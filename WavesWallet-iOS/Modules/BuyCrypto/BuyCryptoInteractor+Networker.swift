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
        ///
        let senderAsset: String

        ///
        let recipientAsset: String

        ///
        let exchangeAddress: String

        ///
        let minLimit: Decimal

        ///
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
                            if let assetBinding = gatewayAssetBindings.first(where: {
                                $0.senderAsset.asset == asset.id.replacingOccurrences(of: "USD", with: "AC_USD")
                            }),
                                let assetInfo = walletEnvironmentAssets.first(where: {
                                    $0.assetId == assetBinding.recipientAsset.asset
                                }) {
                                return .init(name: asset.name,
                                             id: asset.id.replacingOccurrences(of: "USD", with: "AC_USD"),
                                             decimals: asset.decimals,
                                             assetInfo: assetInfo)
                            } else {
                                return .init(name: asset.name,
                                             id: asset.id.replacingOccurrences(of: "USD", with: "AC_USD"),
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
        func getExchangeRate(senderAsset: String,
                             recipientAsset: String,
                             amount: Double,
                             completion: @escaping (Result<ExchangeInfo, Error>) -> Void) {
            Observable.zip(authorizationService.authorizedWallet(),
                           developmentConfigRepository.developmentConfigs(),
                           serverEnvironmentRepository.serverEnvironment(), environmentRepository.walletEnvironment())
                .flatMap { [weak self] signedWallet, devConfig, serverEnvironment, walletEnvironment
                    -> Observable<(SignedWallet, ServerEnvironment, DevelopmentConfigs, WalletEnvironment, WEOAuthTokenDTO)> in
                    guard let sself = self else { return Observable.never() }

                    return sself.weOAuthRepository.oauthToken(signedWallet: signedWallet)
                        .map { (signedWallet, serverEnvironment, devConfig, walletEnvironment, $0) }
                }
                .flatMap { [weak self] signedWallet, serverEnvironment, devConfig, walletEnvironment, token
                    -> Observable<(SignedWallet, GatewaysTransferBinding, DevelopmentConfigs, WalletEnvironment)> in
                    guard let sself = self else { return Observable.never() }
                    let transferBindingRequest = TransferBindingRequest(asset: recipientAsset,
                                                                        recipientAddress: signedWallet.wallet.address)

                    return sself.gatewaysWavesRepository.depositTransferBinding(serverEnvironment: serverEnvironment,
                                                                                oAToken: token,
                                                                                request: transferBindingRequest)
                        .map { gatewayTransferBinding
                            -> (SignedWallet, GatewaysTransferBinding, DevelopmentConfigs, WalletEnvironment) in
                            (signedWallet, gatewayTransferBinding, devConfig, walletEnvironment)
                        }
                }
                .catchError { error in
                    Observable.error(error)
                }
                .subscribe(onNext: { [weak self] signedWallet, gatewayTransferBinding, devConfig, walletEnvironment in
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
                    var devConfigRate: DevelopmentConfigs.Rate?
                    let assets = (walletEnvironment.assets ?? []) + walletEnvironment.generalAssets
                    if let assetInfo = assets.first(where: { $0.wavesId == recipientAsset }) {
                        devConfigRate = devConfig.gatewayMinFee[assetInfo.assetId]?[senderAsset.lowercased()]
                    }

                    self?.getExchangeLimits(signedWallet: signedWallet,
                                            gatewayTransferBinding: gatewayTransferBinding,
                                            devConfigRate: devConfigRate,
                                            senderAsset: senderAsset,
                                            completion: completionAdapter)

                },
                           onError: { error in completion(.failure(error)) })
                .disposed(by: disposeBag)
        }

        private func getExchangeLimits(signedWallet: SignedWallet,
                                       gatewayTransferBinding: GatewaysTransferBinding,
                                       devConfigRate: DevelopmentConfigs.Rate?,
                                       senderAsset: String,
                                       completion: @escaping (Result<(min: Decimal, max: Decimal), Error>) -> Void) {
            let completionAdapter: (Result<Double, Error>) -> Void = { result in
                switch result {
                case let .success(limitRate):
                    let min: Decimal
                    let max: Decimal
                    // ac_usd === usnd
                    if let devConfigRate = devConfigRate {
                        
                        // домножить на рейт из конфига
                        let devRate = Decimal(devConfigRate.rate)
                        let devFlat = Decimal(devConfigRate.flat)
                        min = Decimal(limitRate) * gatewayTransferBinding.assetBinding.senderAmountMin * devRate + devFlat
                        max = Decimal(limitRate) * gatewayTransferBinding.assetBinding.senderAmountMax
                    } else {
                        min = 100
                        max = 9500
                    }
                    completion(.success((min, max)))
                case let .failure(error):
                    completion(.failure(error))
                }
            }

            // чтобы получить лимиты для usnd
            adCashGRPCService.getACashAssetsExchangeRate(signedWallet: signedWallet,
                                                         senderAsset: senderAsset,
                                                         recipientAsset: "USD",
                                                         senderAssetAmount: 1,
                                                         completion: completionAdapter)
        }

        private func getExchangeRates(signedWallet: SignedWallet,
                                      gatewayTransferBinding: GatewaysTransferBinding,
                                      senderAsset: String,
                                      recipientAsset: String,
                                      minLimit: Decimal,
                                      maxLimit: Decimal,
                                      amount: Double,
                                      completion: @escaping (Result<ExchangeInfo, Error>) -> Void) {
            let completionAdapter: (Result<Double, Error>) -> Void = { result in
                switch result {
                case let .success(exchangeRate):
                    let rate: Double
                    if Decimal(amount) < minLimit {
                        let minLimitAsNSNumber = minLimit as NSNumber
                        let minLimitDouble = Double(truncating: minLimitAsNSNumber)
                        rate = exchangeRate / minLimitDouble
                    } else {
                        rate = exchangeRate
                    }

                    let rateInfo = ExchangeInfo(senderAsset: senderAsset,
                                                recipientAsset: recipientAsset,
                                                exchangeAddress: gatewayTransferBinding.addresses.first ?? "",
                                                minLimit: minLimit,
                                                maxLimit: maxLimit,
                                                rate: rate)

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
                                                         senderAsset: senderAsset,
                                                         recipientAsset: recipientAsset,
                                                         senderAssetAmount: senderAssetAmount,
                                                         completion: completionAdapter)
        }

        func deposite(senderAsset: String,
                      recipientAsset: String,
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
                                                     senderAsset: senderAsset,
                                                     recipientAsset: recipientAsset,
                                                     exchangeAddress: exchangeAddress,
                                                     amount: amount,
                                                     completion: completionAdapter)
                },
                           onError: { error in completion(.failure(error)) })
                .disposed(by: disposeBag)
        }
    }
}
