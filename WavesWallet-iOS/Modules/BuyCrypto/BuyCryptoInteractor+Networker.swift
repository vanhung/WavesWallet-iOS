//
//  BuyCryptoInteractor+Networker.swift
//  WavesWallet-iOS
//
//  Created by vvisotskiy on 25.05.2020.
//  Copyright © 2020 Waves Platform. All rights reserved.
//

import DomainLayer
import RxSwift

// MARK: - NetWorker

extension BuyCryptoInteractor {
    struct ExchangeInfo {
        /// Выбранная валюта реального мира
        let senderAsset: FiatAsset

        /// Выбранная криптовалюта
        let recipientAsset: CryptoAsset

        /// Адрес для обмена выбранного крипто ассета (приходит из GatewayTransferBinding)
        let exchangeAddress: String

        /// Минимальный порог обмена для фиатной валюты
        let minLimit: Decimal

        /// Максимальный порог обмена для фиатной валюты
        let maxLimit: Decimal

        ///
        let rate: Double
    }

    final class Networker {
        private let authorizationService: AuthorizationUseCaseProtocol
        private let environmentRepository: EnvironmentRepositoryProtocol
        private let gatewaysWavesRepository: GatewaysWavesRepository
        private let assetsUseCase: AssetsUseCaseProtocol
        private let adCashGRPCService: AdCashGRPCService
        private let developmentConfigRepository: DevelopmentConfigsRepositoryProtocol
        private let serverEnvironmentRepository: ServerEnvironmentRepository
        private let weOAuthRepository: WEOAuthRepositoryProtocol

        private let disposeBag = DisposeBag()

        init(authorizationService: AuthorizationUseCaseProtocol,
             environmentRepository: EnvironmentRepositoryProtocol,
             gatewaysWavesRepository: GatewaysWavesRepository,
             assetsUseCase: AssetsUseCaseProtocol,
             adCashGRPCService: AdCashGRPCService,
             developmentConfigRepository: DevelopmentConfigsRepositoryProtocol,
             serverEnvironmentRepository: ServerEnvironmentRepository,
             weOAuthRepository: WEOAuthRepositoryProtocol) {
            self.authorizationService = authorizationService
            self.environmentRepository = environmentRepository
            self.assetsUseCase = assetsUseCase
            self.gatewaysWavesRepository = gatewaysWavesRepository
            self.adCashGRPCService = adCashGRPCService
            self.developmentConfigRepository = developmentConfigRepository
            self.serverEnvironmentRepository = serverEnvironmentRepository
            self.weOAuthRepository = weOAuthRepository
        }

        func getAssets(completion: @escaping (Result<BuyCryptoInteractor.AssetsInfo, Error>) -> Void) {
            Observable.zip(authorizationService.authorizedWallet(),
                           environmentRepository.walletEnvironment(),
                           serverEnvironmentRepository.serverEnvironment())
                .flatMap { [weak self] signedWallet, walletEnvironment, serverEnvironment
                    -> Observable<(SignedWallet, WalletEnvironment, ServerEnvironment, WEOAuthTokenDTO)> in
                    guard let sself = self else { return Observable.never() }
                    return sself.weOAuthRepository.oauthToken(signedWallet: signedWallet)
                        .map { (signedWallet, walletEnvironment, serverEnvironment, $0) }
                }
                .flatMap { [weak self] signedWallet, walletEnvironment, serverEnvironment, token
                    -> Observable<(SignedWallet, WalletEnvironment, [GatewaysAssetBinding])> in

                    guard let sself = self else { return Observable.never() }
                    let request = AssetBindingsRequest(assetType: nil,
                                                       direction: .deposit,
                                                       includesExternalAssetTicker: nil,
                                                       includesWavesAsset: nil)
                    return sself.gatewaysWavesRepository.assetBindingsRequest(serverEnvironment: serverEnvironment,
                                                                              oAToken: token,
                                                                              request: request)
                        .map { (signedWallet, walletEnvironment, $0) }
                }
                .subscribe(onNext: { [weak self] signedWallet, walletEnvironment, gatewayAssetBindings in
                    self?.getACashAssets(signedWallet: signedWallet,
                                         walletEnvironment: walletEnvironment,
                                         gatewayAssetBindings: gatewayAssetBindings,
                                         completion: completion)
                },
                           onError: { error in completion(.failure(error)) })
                .disposed(by: disposeBag)
        }

        private func getACashAssets(signedWallet: SignedWallet,
                                    walletEnvironment: WalletEnvironment,
                                    gatewayAssetBindings: [GatewaysAssetBinding],
                                    completion: @escaping (Result<AssetsInfo, Error>) -> Void) {
            let completionAdapter: (Result<[ACashAsset], Error>) -> Void = { result in
                switch result {
                case let .success(assets):
                    let walletEnvironmentAssets = walletEnvironment.generalAssets + (walletEnvironment.assets ?? [])

                    let fiatAssets = assets.filter { $0.kind == .fiat }
                        .compactMap { asset -> FiatAsset? in
                            if let assetInfo = walletEnvironmentAssets.first(where: { $0.assetId == asset.id }) {
                                return .init(name: asset.name,
                                             id: asset.id,
                                             decimals: asset.decimals,
                                             assetInfo: assetInfo)
                            } else {
                                return .init(name: asset.name,
                                             id: asset.id,
                                             decimals: asset.decimals,
                                             assetInfo: nil)
                            }
                        }

                    let cryptoAssets = assets.filter { $0.kind == .crypto }
                        .compactMap { asset -> CryptoAsset? in
                            let assetId = asset.id
                                .replacingOccurrences(of: "USD", with: DomainLayerConstants.acUSDId)
                                .replacingOccurrences(of: "WAVES", with: "AC_WAVES")
                                .replacingOccurrences(of: "WEST", with: "AC_WEST")
                            if let assetBinding = gatewayAssetBindings.first(where: {
                                $0.senderAsset.asset == assetId
                            }),
                                let assetInfo = walletEnvironmentAssets.first(where: {
                                    $0.assetId == assetBinding.recipientAsset.asset
                                }) {
                                return .init(name: asset.name,
                                             id: assetId,
                                             decimals: asset.decimals,
                                             assetInfo: assetInfo)
                            } else {
                                return .init(name: asset.name,
                                             id: assetId,
                                             decimals: asset.decimals,
                                             assetInfo: nil)
                            }
                        }

                    let assetsInfo = AssetsInfo(fiatAssets: fiatAssets, cryptoAssets: cryptoAssets)
                    completion(.success(assetsInfo))

                case let .failure(error):
                    completion(.failure(error))
                }
            }

            adCashGRPCService.getACashAssets(signedWallet: signedWallet, completion: completionAdapter)
        }

        /// <#Description#>
        /// - Parameters:
        ///   - senderAsset: fiat item
        ///   - recipientAsset: crypto item
        ///   - amount:
        func getExchangeRate(senderAsset: FiatAsset,
                             recipientAsset: CryptoAsset,
                             amount: Double,
                             completion: @escaping (Result<ExchangeInfo, Error>) -> Void) {
            Observable.zip(authorizationService.authorizedWallet(),
                           developmentConfigRepository.developmentConfigs(),
                           serverEnvironmentRepository.serverEnvironment())
                .flatMap { [weak self] signedWallet, devConfig, serverEnvironment
                    -> Observable<(SignedWallet, ServerEnvironment, DevelopmentConfigs, WEOAuthTokenDTO)> in
                    guard let sself = self else { return Observable.never() }

                    return sself.weOAuthRepository.oauthToken(signedWallet: signedWallet)
                        .map { (signedWallet, serverEnvironment, devConfig, $0) }
                }
                .flatMap { [weak self] signedWallet, serverEnvironment, devConfig, token
                    -> Observable<(SignedWallet, GatewaysTransferBinding, DevelopmentConfigs)> in
                    guard let sself = self else { return Observable.never() }
                    let request = TransferBindingRequest(asset: recipientAsset.id, recipientAddress: signedWallet.wallet.address)

                    return sself.gatewaysWavesRepository
                        .depositTransferBinding(serverEnvironment: serverEnvironment, oAToken: token, request: request)
                        .map { gatewayTransferBinding -> (SignedWallet, GatewaysTransferBinding, DevelopmentConfigs) in
                            (signedWallet, gatewayTransferBinding, devConfig)
                        }
                }
                .catchError { Observable.error($0) }
                .subscribe(onNext: { [weak self] signedWallet, gatewayTransferBinding, devConfig in
                    let devConfigRate = devConfig
                        .gatewayMinFee[recipientAsset.assetInfo?.assetId ?? ""]?[senderAsset.id.lowercased()]
                    
                    if recipientAsset.id.lowercased() == "ac_waves" || recipientAsset.id.lowercased() == "ac_west" {
                        self?.specificExchangeRatesLimits(signedWallet: signedWallet,
                                                          gatewayTransferBinding: gatewayTransferBinding,
                                                          devConfigRate: devConfigRate,
                                                          senderAsset: senderAsset,
                                                          recipientAsset: recipientAsset,
                                                          amount: amount,
                                                          completion: completion)
                    } else {
                        let completionAdapter: (Result<(min: Decimal, max: Decimal), Error>) -> Void = { result in
                            switch result {
                            case let .success((min, max)):
                                self?.getExchangeRates(signedWallet: signedWallet,
                                                       gatewayTransferBinding: gatewayTransferBinding,
                                                       senderAsset: senderAsset,
                                                       recipientAsset: recipientAsset,
                                                       minLimit: min,
                                                       maxLimit: max,
                                                       amount: amount,
                                                       completion: completion)
                            case let .failure(error):
                                completion(.failure(error))
                            }
                        }

                        self?.getExchangeLimits(signedWallet: signedWallet,
                                                gatewayTransferBinding: gatewayTransferBinding,
                                                devConfigRate: devConfigRate,
                                                senderAsset: senderAsset,
                                                recipientAsset: recipientAsset,
                                                completion: completionAdapter)
                    }
                },
                           onError: { error in completion(.failure(error)) })
                .disposed(by: disposeBag)
        }
        
        private func getExchangeRates(signedWallet: SignedWallet,
                                      gatewayTransferBinding: GatewaysTransferBinding,
                                      senderAsset: FiatAsset,
                                      recipientAsset: CryptoAsset,
                                      minLimit: Decimal,
                                      maxLimit: Decimal,
                                      amount: Double,
                                      completion: @escaping (Result<ExchangeInfo, Error>) -> Void) {
            let completionAdapter: (Result<Double, Error>) -> Void = { result in
                switch result {
                case let .success(exchangeRate):
                    let rateInfo = ExchangeInfo(senderAsset: senderAsset,
                                                recipientAsset: recipientAsset,
                                                exchangeAddress: gatewayTransferBinding.addresses.first ?? "",
                                                minLimit: minLimit,
                                                maxLimit: maxLimit,
                                                rate: exchangeRate)

                    completion(.success(rateInfo))
                case let .failure(error):
                    completion(.failure(error))
                }
            }

            let senderAssetAmount: Double
            if Decimal(amount) < minLimit {
                let minLimitAsNSNumber = minLimit as NSNumber
                senderAssetAmount = Double(truncating: minLimitAsNSNumber)
            } else {
                senderAssetAmount = amount
            }

            // сколько получит пользователь для отображения в ibuy
            adCashGRPCService.getACashAssetsExchangeRate(signedWallet: signedWallet,
                                                         senderAsset: senderAsset.id,
                                                         recipientAsset: recipientAsset.id,
                                                         senderAssetAmount: senderAssetAmount,
                                                         completion: completionAdapter)
        }

        private func getExchangeLimits(signedWallet: SignedWallet,
                                       gatewayTransferBinding: GatewaysTransferBinding,
                                       devConfigRate: DevelopmentConfigs.Rate?,
                                       senderAsset: FiatAsset,
                                       recipientAsset: CryptoAsset,
                                       completion: @escaping (Result<(min: Decimal, max: Decimal), Error>) -> Void) {
            let completionAdapter: (Result<Double, Error>) -> Void = { result in
                switch result {
                case let .success(limitRate):
                    let decimalLimitRate = Decimal(limitRate)
                    var min: Decimal
                    let max: Decimal
                    
                    if recipientAsset.id.lowercased() == "btc" {
                        min = 100 / Decimal(limitRate)
                        max = 9500 / Decimal(limitRate)
                    } else {
                        // coef необходим чтоб получить правильный минимум и максимум (они приходят в копейках)
                        let coef = Decimal(pow(10, Double(senderAsset.decimals)))

                        min = decimalLimitRate * (gatewayTransferBinding.assetBinding.senderAmountMin / coef)
                        max = decimalLimitRate * (gatewayTransferBinding.assetBinding.senderAmountMax / coef)
                    }
                    
                    if let devConfigRate = devConfigRate {
                        let devRate = Decimal(devConfigRate.rate)
                        let devFlat = Decimal(devConfigRate.flat)
                        
                        min = min * devRate + devFlat
                    }
                    completion(.success((min, max)))
                case let .failure(error):
                    completion(.failure(error))
                }
            }

            // чтобы получить лимиты в usd
            adCashGRPCService.getACashAssetsExchangeRate(signedWallet: signedWallet,
                                                         senderAsset: senderAsset.id,
                                                         recipientAsset: "USD",
                                                         senderAssetAmount: 1,
                                                         completion: completionAdapter)
        }
        
        private func specificExchangeRatesLimits(signedWallet: SignedWallet,
                                                 gatewayTransferBinding: GatewaysTransferBinding,
                                                 devConfigRate: DevelopmentConfigs.Rate?,
                                                 senderAsset: FiatAsset,
                                                 recipientAsset: CryptoAsset,
                                                 amount: Double,
                                                 completion: @escaping (Result<ExchangeInfo, Error>) -> Void) {
            let senderAmountMin = Double(truncating: gatewayTransferBinding.assetBinding.senderAmountMin as NSNumber)
            let senderAmountMax = Double(truncating: gatewayTransferBinding.assetBinding.senderAmountMax as NSNumber)
            
            var rateForMin: Double?
            var rateForMax: Double?
            
            let dispatchGroup = DispatchGroup()
            dispatchGroup.enter()
            adCashGRPCService.getACashAssetsExchangeRate(
                signedWallet: signedWallet,
                senderAsset: recipientAsset.id,
                recipientAsset: "USD",
                senderAssetAmount: senderAmountMin) { result in
                    switch result {
                    case .success(let rate):
                        rateForMin = rate
                    case .failure:
                        rateForMin = 1
                        // не знаю как поступать в этой ситуации
                    }
                    dispatchGroup.leave()
            }
            
            dispatchGroup.enter()
            adCashGRPCService.getACashAssetsExchangeRate(
                signedWallet: signedWallet,
                senderAsset: recipientAsset.id,
                recipientAsset: "USD",
                senderAssetAmount: senderAmountMax,
                completion: { result in
                    switch result {
                    case .success(let rate):
                        rateForMax = rate
                    case .failure:
                        rateForMax = 1
                        // не знаю как поступать в этой ситуации
                    }
                    dispatchGroup.leave()
            })
            
            dispatchGroup.notify(queue: DispatchQueue.global(), execute: { [weak self] in
                let decimals = Double(recipientAsset.decimals)
                let coef = pow(10, decimals)
                
                let devRate = devConfigRate?.rate ?? 1
                let devFlat = Double(devConfigRate?.flat ?? 0)
                
                var minLimit = (senderAmountMin / coef) / (rateForMin ?? 1)
                minLimit *= devRate
                minLimit += devFlat
                
                let maxLimit = ((senderAmountMax / coef) / (rateForMax ?? 1))
                
                self?.getExchangeRates(signedWallet: signedWallet,
                                       gatewayTransferBinding: gatewayTransferBinding,
                                       senderAsset: senderAsset,
                                       recipientAsset: recipientAsset,
                                       minLimit: Decimal(minLimit),
                                       maxLimit: Decimal(maxLimit),
                                       amount: amount,
                                       completion: completion)
            })
        }

        func deposite(senderAsset: FiatAsset,
                      recipientAsset: CryptoAsset,
                      exchangeAddress: String,
                      amount: Double,
                      completion: @escaping (Result<URL, Error>) -> Void) {
            authorizationService.authorizedWallet()
                .subscribe(onNext: { [weak self] signedWallet in
                    let completionAdapter: (Result<String, Error>) -> Void = { result in
                        switch result {
                        case let .success(queryParams):

                            let urlString = DomainLayerConstants.URL.advcash + queryParams
                            if let url = URL(string: urlString) {
                                completion(.success(url))
                            } else {
//                                completion(.failure(<#T##Error#>))
                            }
                        case let .failure(error):
                            completion(.failure(error))
                        }
                    }

                    self?.adCashGRPCService.deposite(signedWallet: signedWallet,
                                                     senderAsset: senderAsset.id,
                                                     recipientAsset: recipientAsset.id,
                                                     exchangeAddress: exchangeAddress,
                                                     amount: amount,
                                                     completion: completionAdapter)
                },
                           onError: { error in completion(.failure(error)) })
                .disposed(by: disposeBag)
        }
    }
}
