//
//  ReceiveCryptocurrencyInteractor.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 10/5/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import DomainLayer
import Extensions
import Foundation
import RxSwift
import WavesSDK

private enum Constants {
    static let btcSegWitAddress = NSPredicate(format: "SELF MATCHES %@",
                                              "((bc|tb)(0([ac-hj-np-z02-9]{39}|[ac-hj-np-z02-9]{59})|1[ac-hj-np-z02-9]{8,87}))")
    static let btcLegacyAddress = NSPredicate(format: "SELF MATCHES %@", "([13]|[mn2])[a-km-zA-HJ-NP-Z1-9]{25,39}")
}

final class ReceiveCryptocurrencyInteractor: ReceiveCryptocurrencyInteractorProtocol {
    private let auth: AuthorizationUseCaseProtocol
    private let coinomatRepository: CoinomatRepositoryProtocol
    private let gatewayRepository: GatewayRepositoryProtocol
    private let serverEnvironmentUseCase: ServerEnvironmentRepository
    private let environmentRepository: EnvironmentRepositoryProtocol
    private let gatewaysWavesRepository: GatewaysWavesRepository
    private let weOAuthRepository: WEOAuthRepositoryProtocol

    init(authorization: AuthorizationUseCaseProtocol,
         coinomatRepository: CoinomatRepositoryProtocol,
         gatewayRepository: GatewayRepositoryProtocol,
         serverEnvironmentUseCase: ServerEnvironmentRepository,
         environmentRepository: EnvironmentRepositoryProtocol,
         gatewaysWavesRepository: GatewaysWavesRepository,
         weOAuthRepository: WEOAuthRepositoryProtocol) {
        auth = authorization
        self.coinomatRepository = coinomatRepository
        self.gatewayRepository = gatewayRepository
        self.serverEnvironmentUseCase = serverEnvironmentUseCase
        self.environmentRepository = environmentRepository
        self.gatewaysWavesRepository = gatewaysWavesRepository
        self.weOAuthRepository = weOAuthRepository
    }

    func generateAddress(asset: Asset) -> Observable<ResponseType<ReceiveCryptocurrency.DTO.DisplayInfo>> {
        let serverEnvironment = serverEnvironmentUseCase.serverEnvironment()
        let wallet = auth.authorizedWallet()
        let environment = environmentRepository.walletEnvironment()

        return Observable.zip(wallet, serverEnvironment, environment)
            .flatMap { [weak self] wallet, serverEnvironment, appEnvironments -> Observable<ResponseType<ReceiveCryptocurrency.DTO.DisplayInfo>> in

                let generalAssets = appEnvironments.generalAssets + (appEnvironments.assets ?? [])

                guard let self = self, let gatewayType = asset.gatewayType else {
                    if asset.isExistInExternalSource {
                        let addresses = [ReceiveCryptocurrency.DTO.DisplayInfo.Address(name: "",
                                                                                       address: wallet.address)]
                        let displayInfo = ReceiveCryptocurrency.DTO
                            .DisplayInfo(addresses: addresses,
                                         asset: asset,
                                         minAmount: Money(0, 0),
                                         maxAmount: nil,
                                         generalAssets: generalAssets)
                        
                        return Observable.just(ResponseType(output: displayInfo, error: nil))
                    }

                    return Observable.empty()
                }

                switch gatewayType {
                case .gateway:
                    return self.gatewayRepository.startDepositProcess(serverEnvironment: serverEnvironment,
                                                                      address: wallet.address,
                                                                      asset: asset)
                        .map { startDeposit -> ResponseType<ReceiveCryptocurrency.DTO.DisplayInfo> in

                            let addresses = [startDeposit.address.displayInfoAddress()]

                            let displayInfo = ReceiveCryptocurrency.DTO.DisplayInfo(addresses: addresses,
                                                                                    asset: asset,
                                                                                    minAmount: startDeposit.minAmount,
                                                                                    maxAmount: startDeposit.maxAmount,
                                                                                    generalAssets: generalAssets)

                            return ResponseType(output: displayInfo, error: nil)
                        }

                case .coinomat:
                    guard let currencyFrom = asset.gatewayId,
                        let currencyTo = asset.wavesId else { return Observable.empty() }

                    let tunnel = self.coinomatRepository.tunnelInfo(asset: asset,
                                                                    currencyFrom: currencyFrom,
                                                                    currencyTo: currencyTo,
                                                                    walletTo: wallet.address)

                    let rate = self.coinomatRepository.getRate(asset: asset)
                    return Observable.zip(tunnel, rate)
                        .flatMap { tunnel, rate -> Observable<ResponseType<ReceiveCryptocurrency.DTO.DisplayInfo>> in
                            let displayInfo = ReceiveCryptocurrency.DTO
                                .DisplayInfo(addresses: [tunnel.address.displayInfoAddress()],
                                             asset: asset,
                                             minAmount: tunnel.min,
                                             maxAmount: rate.max,
                                             generalAssets: generalAssets)
                            return Observable.just(ResponseType(output: displayInfo, error: nil))
                        }
                case .exchange:

                    return self.weOAuthRepository.oauthToken(signedWallet: wallet)
                        .flatMap { [weak self] token -> Observable<ResponseType<ReceiveCryptocurrency.DTO.DisplayInfo>> in

                            guard let self = self else { return Observable.never() }

                            let assetBindingsRequest = AssetBindingsRequest(assetType: .crypto,
                                                                            direction: .deposit,
                                                                            includesWavesAsset: asset.id)

                            return self
                                .gatewaysWavesRepository.assetBindingsRequest(serverEnvironment: serverEnvironment,
                                                                              oAToken: token,
                                                                              request: assetBindingsRequest)
                                .flatMap { [weak self] binding -> Observable<ResponseType<ReceiveCryptocurrency.DTO.DisplayInfo>> in

                                    guard let self = self else { return Observable.never() }

                                    guard let binding = binding.first else { return Observable.error(NetworkError.notFound) }

                                    let request = TransferBindingRequest(asset: binding.senderAsset.asset,
                                                                         recipientAddress: wallet.address)

                                    return self
                                        .gatewaysWavesRepository
                                        .depositTransferBinding(serverEnvironment: serverEnvironment,
                                                                oAToken: token,
                                                                request: request)
                                        .map { binding -> ResponseType<ReceiveCryptocurrency.DTO.DisplayInfo> in

                                            var amoauntMin = binding.assetBinding.senderAmountMin.int64Value
                                            var amoauntMax = binding.assetBinding.senderAmountMax.int64Value
                                            var assetPrecision = asset.precision

                                            if binding.assetBinding.recipientAsset
                                                .asset == "474jTeYx2r2Va35794tCScAXWJG9hU2HcgxzMowaZUnu" {
                                                amoauntMax = 5_000_000_000_000
                                                amoauntMin = 1_000_000
                                                assetPrecision = 8
                                            }

                                            if binding.assetBinding.recipientAsset
                                                .asset == "F81SdfzBZr5ce8JArRWLPJEDg1V8yT257ohbcHk75yCp" {
                                                amoauntMax = 100_000_000_000_000
                                                amoauntMin = 1_000_000_000
                                                assetPrecision = 8
                                            }

                                            let minAmount = Money(amoauntMin,
                                                                  assetPrecision)

                                            let maxAmount = Money(amoauntMax,
                                                                  assetPrecision)

                                            let addresses = binding.addresses.displayInfoAddresses()

                                            let info = ReceiveCryptocurrency
                                                .DTO
                                                .DisplayInfo(addresses: addresses,
                                                             asset: asset,
                                                             minAmount: minAmount,
                                                             maxAmount: maxAmount,
                                                             generalAssets: generalAssets)
                                            return ResponseType(output: info,
                                                                error: nil)
                                        }
                                }
                        }
                }
            }
            .catchError { error -> Observable<ResponseType<ReceiveCryptocurrency.DTO.DisplayInfo>> in
                if let networkError = error as? NetworkError {
                    return Observable.just(ResponseType(output: nil, error: networkError))
                }

                return Observable.just(ResponseType(output: nil, error: NetworkError.error(by: error)))
            }
    }
}

private extension Array where Element == ReceiveCryptocurrency.DTO.DisplayInfo.Address {
    func addressesSort(asset _: Asset) -> [Element] {
        return self
    }
}

private extension Array where Element == String {
    func displayInfoAddresses() -> [ReceiveCryptocurrency.DTO.DisplayInfo.Address] {
        return enumerated()
            .map { index, element -> ReceiveCryptocurrency.DTO.DisplayInfo.Address in
                element
                    .displayInfoAddress(deffaultName: Localizable.Waves.Receivecryptocurrency.Address.Default
                        .name("\(index + 1)"))
            }
    }
}

private extension String {
    func displayInfoAddress(deffaultName: String = "Address") -> ReceiveCryptocurrency.DTO.DisplayInfo.Address {
        let new = Constants.btcSegWitAddress
        let old = Constants.btcLegacyAddress

        var name: String = deffaultName
        if new.evaluate(with: self) {
            name = "SegWit Address"
        } else if old.evaluate(with: self) {
            name = "Legacy Address"
        }

        return ReceiveCryptocurrency.DTO.DisplayInfo.Address(name: name,
                                                             address: self)
    }
}
