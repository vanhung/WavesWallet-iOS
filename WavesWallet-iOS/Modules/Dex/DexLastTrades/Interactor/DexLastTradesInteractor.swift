//
//  DexLastTradesInteractorMock.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 8/22/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import RxSwift
import WavesSDK
import Extensions
import DomainLayer

private enum Constants {
    static let limit = 100
}

final class DexLastTradesInteractor: DexLastTradesInteractorProtocol {

    private struct LastSellBuy {
        let sell: DexLastTrades.DTO.SellBuyTrade?
        let buy: DexLastTrades.DTO.SellBuyTrade?
    }
    
    private let account = UseCasesFactory.instance.accountBalance
    private let lastTradesRepository = UseCasesFactory.instance.repositories.lastTradesRespository
    private let orderBookRepository = UseCasesFactory.instance.repositories.dexOrderBookRepository
    private let auth = UseCasesFactory.instance.authorization
    private let assetsRepositoryLocal = UseCasesFactory.instance.repositories.assetsRepositoryLocal
    private let assetsInteractor = UseCasesFactory.instance.assets

    var pair: DexTraderContainer.DTO.Pair!

    func displayInfo() -> Observable<DexLastTrades.DTO.DisplayData> {

        Observable.zip(getLastTrades(),
                       getLastSellBuy(),
                       account.balances(),
                       getScriptedAssets())
            .flatMap({ [weak self] (lastTrades, lastSellBuy, balances, scriptedAssets) -> Observable<(DexLastTrades.DTO.DisplayData)> in
                guard let self = self else { return Observable.empty() }
                
                return self.displayData(lastTrades: lastTrades,
                                         lastSellBuy: lastSellBuy,
                                         balances:  balances,
                                         scriptedAssets: scriptedAssets)
            })
            .catchError({ [weak self] (error) -> Observable<(DexLastTrades.DTO.DisplayData)> in
                guard let self = self else { return Observable.empty() }
                
                let display = DexLastTrades.DTO.DisplayData(trades: [],
                                                            lastSell: nil,
                                                            lastBuy:  nil,
                                                            availableAmountAssetBalance: Money(0, self.pair.amountAsset.decimals),
                                                            availablePriceAssetBalance: Money(0, self.pair.priceAsset.decimals),
                                                            availableBalances: [],
                                                            scriptedAssets: [])
                return Observable.just(display)
            })
    }
}


extension DexLastTradesInteractor {
    
    private func displayData(lastTrades: [DomainLayer.DTO.Dex.LastTrade],
                             lastSellBuy: LastSellBuy,
                             balances: [DomainLayer.DTO.SmartAssetBalance],
                             scriptedAssets: [DomainLayer.DTO.Asset]) -> Observable<DexLastTrades.DTO.DisplayData> {
        
        var amountAssetBalance =  Money(0, pair.amountAsset.decimals)
        var priceAssetBalance =  Money(0, pair.priceAsset.decimals)
                
        if let amountAsset = balances.first(where: {$0.assetId == pair.amountAsset.id}) {
            amountAssetBalance = Money(amountAsset.availableBalance, amountAsset.asset.precision)
        }
        
        if let priceAsset = balances.first(where: {$0.assetId == pair.priceAsset.id}) {
            priceAssetBalance = Money(priceAsset.availableBalance, priceAsset.asset.precision)
        }
                
        let display = DexLastTrades.DTO.DisplayData(trades: lastTrades,
                                                    lastSell: lastSellBuy.sell,
                                                    lastBuy: lastSellBuy.buy,
                                                    availableAmountAssetBalance: amountAssetBalance,
                                                    availablePriceAssetBalance: priceAssetBalance,
                                                    availableBalances: balances,
                                                    scriptedAssets: scriptedAssets)
        return Observable.just(display)
    }
    
    private func getLastTrades() -> Observable<[DomainLayer.DTO.Dex.LastTrade]> {

        return lastTradesRepository.lastTrades(amountAsset: pair.amountAsset,
                                               priceAsset: pair.priceAsset,
                                               limit: Constants.limit)
    }
    
    private func getLastSellBuy() -> Observable<LastSellBuy> {
        
        return self.orderBookRepository.orderBook(amountAsset: self.pair.amountAsset.id,
                                                  priceAsset: self.pair.priceAsset.id)
            .flatMap({ [weak self] (orderbook) -> Observable<LastSellBuy> in
                
                guard let self = self else { return Observable.empty() }
                
                var sell: DexLastTrades.DTO.SellBuyTrade?
                var buy: DexLastTrades.DTO.SellBuyTrade?
                
                if let bid = orderbook.bids.first {
                    
                    let price = Money.price(amount: bid.price,
                                            amountDecimals: self.pair.amountAsset.decimals,
                                            priceDecimals: self.pair.priceAsset.decimals)
                    
                    sell = DexLastTrades.DTO.SellBuyTrade(price: price, type: .sell)
                }
                
                if let ask = orderbook.asks.first {
                    
                    let price = Money.price(amount: ask.price,
                                            amountDecimals: self.pair.amountAsset.decimals,
                                            priceDecimals: self.pair.priceAsset.decimals)
                    
                    buy = DexLastTrades.DTO.SellBuyTrade(price: price, type: .buy)
                }
                
                return Observable.just(LastSellBuy(sell: sell, buy: buy))
            })
        
    }
    
    func getScriptedAssets() -> Observable<[DomainLayer.DTO.Asset]> {
        
        return auth.authorizedWallet().flatMap({ [weak self] (wallet) -> Observable<[DomainLayer.DTO.Asset]> in
            guard let self = self else { return Observable.empty() }
            
            let ids = [self.pair.amountAsset.id, self.pair.priceAsset.id]
            return self.assetsRepositoryLocal.assets(by: ids, accountAddress: wallet.address)
                .map { $0.filter { $0.hasScript }.sorted(by: { (first, second) -> Bool in
                    return first.id == self.pair.amountAsset.id
                })}
                .catchError({ [weak self] (error) -> Observable<[DomainLayer.DTO.Asset]> in
                    guard let self = self else { return Observable.empty() }
                    
                    return self.assetsInteractor.assets(by: ids, accountAddress: wallet.address)
                })
        })
    }
}
