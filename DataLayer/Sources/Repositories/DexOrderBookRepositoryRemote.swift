//
//  DexOrderBookRepositoryRemote.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 12/17/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import DomainLayer
import Extensions
import Foundation
import Moya
import RealmSwift
import RxSwift
import WavesSDK

private enum Constants {
    static let baseFee: Int64 = 300_000
    static let WavesRate: Double = 1
}

final class DexOrderBookRepositoryRemote: DexOrderBookRepositoryProtocol {
    private let spamAssetsRepository: SpamAssetsRepositoryProtocol

    private let matcherRepository: MatcherRepositoryProtocol

    private let assetsRepository: AssetsRepositoryProtocol

    private let waveSDKServices: WavesSDKServices
    private let assetsBalanceSettingsRepository: AssetsBalanceSettingsRepositoryProtocol
    private let serverEnvironmentRepository: ServerEnvironmentRepository

    init(spamAssetsRepository: SpamAssetsRepositoryProtocol,
         matcherRepository: MatcherRepositoryProtocol,
         assetsRepository: AssetsRepositoryProtocol,
         waveSDKServices: WavesSDKServices,
         assetsBalanceSettingsRepository: AssetsBalanceSettingsRepositoryProtocol,
         serverEnvironmentRepository: ServerEnvironmentRepository) {
        self.spamAssetsRepository = spamAssetsRepository
        self.matcherRepository = matcherRepository
        self.assetsRepository = assetsRepository
        self.assetsBalanceSettingsRepository = assetsBalanceSettingsRepository
        self.waveSDKServices = waveSDKServices
        self.serverEnvironmentRepository = serverEnvironmentRepository
    }

    func orderBook(serverEnvironment: ServerEnvironment,
                   amountAsset: String,
                   priceAsset: String) -> Observable<DomainLayer.DTO.Dex.OrderBook> {
        return waveSDKServices
            .wavesServices(environment: serverEnvironment)
            .matcherServices
            .orderBookMatcherService
            .orderBook(amountAsset: amountAsset,
                       priceAsset: priceAsset)
            .flatMap { orderBook -> Observable<DomainLayer.DTO.Dex.OrderBook> in

                let bids = orderBook.bids.map { DomainLayer.DTO.Dex.OrderBook.Value(amount: $0.amount, price: $0.price) }

                let asks = orderBook.asks.map { DomainLayer.DTO.Dex.OrderBook.Value(amount: $0.amount, price: $0.price) }

                return Observable.just(DomainLayer.DTO.Dex.OrderBook(bids: bids, asks: asks))
            }
    }

    func markets(serverEnvironment: ServerEnvironment,
                 wallet: SignedWallet,
                 pairs: [DomainLayer.DTO.Dex.Pair]) -> Observable<[DomainLayer.DTO.Dex.SmartPair]> {
        let waveSDKServices = self.waveSDKServices.wavesServices(environment: serverEnvironment)

        return matcherRepository
            .matcherPublicKey(serverEnvironment: serverEnvironment)
            .flatMap { [weak self] matcherPublicKey -> Observable<[DomainLayer.DTO.Dex.SmartPair]> in
                guard let self = self else { return Observable.empty() }

                let queryPairs = pairs.map {
                    DataService.Query.PairsPrice.Pair(amountAssetId: $0.amountAsset.id, priceAssetId: $0.priceAsset.id)
                }

                let pairsPrice = waveSDKServices.dataServices.pairsPriceDataService
                    .pairsPrice(query: .init(pairs: queryPairs, matcher: matcherPublicKey.address))

                let idsSet = queryPairs.reduce(into: Set<String>()) { out, pair in
                    out.insert(pair.amountAssetId)
                    out.insert(pair.priceAssetId)
                }

                let ids = Array(idsSet)

                let assetsBalanceSettings = self.assetsBalanceSettingsRepository
                    .settings(by: wallet.address, ids: ids)

                let assets = self.assetsRepository.assets(ids: ids,
                                                          accountAddress: wallet.address)

                return Observable.zip(assets, assetsBalanceSettings, pairsPrice)
                    .map { [weak self] _, assetsBalanceSettings, pairsPrice -> [DomainLayer.DTO.Dex.SmartPair] in

                        guard let self = self, let realm = try? WalletRealmFactory.realm(accountAddress: wallet.address) else {
                            return []
                        }

                        var smartPairs: [DomainLayer.DTO.Dex.SmartPair] = []

                        for (index, pair) in pairsPrice.enumerated() {
                            if pair != nil {
                                let amountAsset = pairs[index].amountAsset
                                let priceAsset = pairs[index].priceAsset

                                let piar = DomainLayer.DTO.Dex
                                    .SmartPair(amountAsset: amountAsset, priceAsset: priceAsset, realm: realm)
                                
                                smartPairs.append(piar)
                            }
                        }

                        return self.sort(pairs: smartPairs,
                                         assetsBalanceSettings: assetsBalanceSettings)
                    }
            }
    }

    func allMyOrders(serverEnvironment: ServerEnvironment,
                     wallet: SignedWallet) -> Observable<[DomainLayer.DTO.Dex.MyOrder]> {
        let waveSDKServices = self
            .waveSDKServices
            .wavesServices(environment: serverEnvironment)

        let signature = TimestampSignature(signedWallet: wallet, timestampServerDiff: serverEnvironment.timestampServerDiff)

        return waveSDKServices
            .matcherServices
            .orderBookMatcherService
            .allMyOrders(query: .init(publicKey: wallet.publicKey.getPublicKeyStr(),
                                      signature: signature.signature(),
                                      timestamp: signature.timestamp))
            .flatMap { [weak self] orders -> Observable<[DomainLayer.DTO.Dex.MyOrder]> in

                guard let self = self else { return Observable.empty() }
                guard !orders.isEmpty else { return Observable.just([]) }

                var ids: [String] = []

                for order in orders {
                    if !ids.contains(order.amountAsset) {
                        ids.append(order.amountAsset)
                    }

                    if !ids.contains(order.priceAsset) {
                        ids.append(order.priceAsset)
                    }
                }

                return self.assetsRepository.assets(ids: ids,
                                                    accountAddress: wallet.address)
                    .map { $0.compactMap { $0 } }
                    .map { assets -> [DomainLayer.DTO.Dex.MyOrder] in

                        var myOrders: [DomainLayer.DTO.Dex.MyOrder] = []

                        for order in orders {
                            if let amountAsset = assets.first(where: { $0.id == order.amountAsset }),
                                let priceAsset = assets.first(where: { $0.id == order.priceAsset }) {
                                myOrders.append(DomainLayer.DTO.Dex.MyOrder(order,
                                                                            priceAsset: priceAsset,
                                                                            amountAsset: amountAsset))
                            }
                        }

                        return myOrders
                    }
            }
    }

    func myOrders(serverEnvironment: ServerEnvironment,
                  wallet: SignedWallet,
                  amountAsset: Asset,
                  priceAsset: Asset) -> Observable<[DomainLayer.DTO.Dex.MyOrder]> {
        let waveSDKServices = self
            .waveSDKServices
            .wavesServices(environment: serverEnvironment)

        let signature = TimestampSignature(signedWallet: wallet, timestampServerDiff: serverEnvironment.timestampServerDiff)

        return waveSDKServices
            .matcherServices
            .orderBookMatcherService
            .myOrders(query: .init(amountAsset: amountAsset.id,
                                   priceAsset: priceAsset.id,
                                   publicKey: wallet.publicKey.getPublicKeyStr(),
                                   signature: signature.signature(),
                                   timestamp: signature.timestamp))
            .map { orders -> [DomainLayer.DTO.Dex.MyOrder] in

                var myOrders: [DomainLayer.DTO.Dex.MyOrder] = []

                for order in orders {
                    myOrders.append(DomainLayer.DTO.Dex.MyOrder(order,
                                                                priceAsset: priceAsset,
                                                                amountAsset: amountAsset))
                }
                return myOrders
            }
    }

    func cancelOrder(serverEnvironment: ServerEnvironment,
                     wallet: SignedWallet,
                     orderId: String,
                     amountAsset: String,
                     priceAsset: String) -> Observable<Bool> {
        let waveSDKServices = self
            .waveSDKServices
            .wavesServices(environment: serverEnvironment)

        let signature = CancelOrderSignature(signedWallet: wallet, orderId: orderId)

        return waveSDKServices
            .matcherServices
            .orderBookMatcherService
            .cancelOrder(query: .init(orderId: orderId,
                                      amountAsset: amountAsset,
                                      priceAsset: priceAsset,
                                      signature: signature.signature(),
                                      senderPublicKey: wallet.publicKey.getPublicKeyStr()))
    }

    func cancelAllOrders(serverEnvironment: ServerEnvironment, wallet: SignedWallet) -> Observable<Bool> {
        let waveSDKServices = self
            .waveSDKServices
            .wavesServices(environment: serverEnvironment)

        let signature = TimestampSignature(signedWallet: wallet, timestampServerDiff: serverEnvironment.timestampServerDiff)

        return waveSDKServices
            .matcherServices
            .orderBookMatcherService
            .cancelAllOrders(query: .init(signature: signature.signature(),
                                          senderPublicKey: wallet.publicKey.getPublicKeyStr(),
                                          timestamp: signature.timestamp))
    }

    func createOrder(serverEnvironment: ServerEnvironment,
                     wallet: SignedWallet,
                     order: DomainLayer.Query.Dex.CreateOrder,
                     type: DomainLayer.Query.Dex.CreateOrderType) -> Observable<Bool> {
        let waveSDKServices = self
            .waveSDKServices
            .wavesServices(environment: serverEnvironment)

        let timestamp = order.timestamp - serverEnvironment.timestampServerDiff

        let expirationTimestamp = timestamp + order.expiration * 60 * 1000

        let createOrderSignature = CreateOrderSignature(signedWallet: wallet,
                                                        timestamp: timestamp,
                                                        matcherPublicKey: order.matcherPublicKey,
                                                        assetPair: .init(priceAssetId: order.priceAsset,
                                                                         amountAssetId: order.amountAsset),
                                                        orderType: order.orderType == .sell ? .sell : .buy,
                                                        price: order.price,
                                                        amount: order.amount,
                                                        expiration: expirationTimestamp,
                                                        matcherFee: order.matcherFee,
                                                        matcherFeeAsset: order.matcherFeeAsset,
                                                        version: .V3)

        let order = MatcherService.Query.CreateOrder(matcherPublicKey: order.matcherPublicKey.getPublicKeyStr(),
                                                     senderPublicKey: wallet.publicKey.getPublicKeyStr(),
                                                     assetPair: .init(amountAssetId: order.amountAsset,
                                                                      priceAssetId: order.priceAsset),
                                                     amount: order.amount,
                                                     price: order.price,
                                                     orderType: order.orderType == .sell ? .sell : .buy,
                                                     matcherFee: order.matcherFee,
                                                     timestamp: timestamp,
                                                     expirationTimestamp: expirationTimestamp,
                                                     proofs: [createOrderSignature.signature()],
                                                     matcherFeeAsset: order.matcherFeeAsset.normalizeWavesAssetId)

        switch type {
        case .limit:
            return waveSDKServices
                .matcherServices
                .orderBookMatcherService
                .createOrder(query: order)

        case .market:
            return waveSDKServices
                .matcherServices
                .orderBookMatcherService
                .createMarketOrder(query: order)
        }
    }

    func orderSettingsFee(serverEnvironment: ServerEnvironment) -> Observable<DomainLayer.DTO.Dex.SettingsOrderFee> {
        let waveSDKServices = self
            .waveSDKServices
            .wavesServices(environment: serverEnvironment)

        return waveSDKServices
            .matcherServices
            .orderBookMatcherService
            .settingsRatesFee()
            .map { ratesFee -> DomainLayer.DTO.Dex.SettingsOrderFee in

                let assets = ratesFee.map {
                    DomainLayer.DTO.Dex.SettingsOrderFee.Asset(assetId: $0.assetId, rate: $0.rate)
                }

                return DomainLayer.DTO.Dex.SettingsOrderFee(baseFee: Constants.baseFee, feeAssets: assets)
            }
            .catchError { _ -> Observable<DomainLayer.DTO.Dex.SettingsOrderFee> in
                // TODO: remove code after MainNet will be support custom fee at matcher

                let wavesAsset = DomainLayer.DTO.Dex.SettingsOrderFee.Asset(assetId: WavesSDKConstants.wavesAssetId,
                                                                            rate: Constants.WavesRate)
                let settings = DomainLayer.DTO.Dex.SettingsOrderFee(baseFee: Constants.baseFee, feeAssets: [wavesAsset])
                return Observable.just(settings)
            }
    }
}

// MARK: - Markets Sort

// TODO: Remove call realm
private extension DexOrderBookRepositoryRemote {
    func sort(pairs: [DomainLayer.DTO.Dex.SmartPair],
              assetsBalanceSettings: [String: AssetBalanceSettings]) -> [DomainLayer.DTO.Dex.SmartPair] {
        return pairs.filter { pairs -> Bool in
            pairs.isGeneral
        }
        .sorted { pair1, pair2 -> Bool in

            let setting1 = assetsBalanceSettings[pair1.amountAsset.id]
            let setting2 = assetsBalanceSettings[pair2.amountAsset.id]

            return (setting1?.sortLevel ?? 0) < (setting2?.sortLevel ?? 0)
        }
    }
}

private extension MatcherService.DTO.Order {
    var amountAsset: String {
        if let amountAsset = assetPair.amountAsset {
            return amountAsset
        }
        return WavesSDKConstants.wavesAssetId
    }

    var priceAsset: String {
        if let priceAsset = assetPair.priceAsset {
            return priceAsset
        }
        return WavesSDKConstants.wavesAssetId
    }
}
