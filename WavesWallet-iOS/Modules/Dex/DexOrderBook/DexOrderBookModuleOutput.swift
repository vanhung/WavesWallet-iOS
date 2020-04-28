//
//  DexOrderBookModuleOutput.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 9/9/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import Extensions
import DomainLayer

protocol DexOrderBookModuleOutput: AnyObject {
    
    func didCreateOrder(_ bidAsk: DexOrderBook.DTO.BidAsk,
                        amountAsset: DomainLayer.DTO.Dex.Asset,
                        priceAsset: DomainLayer.DTO.Dex.Asset,
                        ask: Money?,
                        bid: Money?,
                        last: Money?,
                        availableAmountAssetBalance: Money,
                        availablePriceAssetBalance: Money,
                        availableBalances: [DomainLayer.DTO.SmartAssetBalance],
                        inputMaxSum: Bool,
                        scriptedAssets: [DomainLayer.DTO.Asset])

    func didCreateEmptyOrder(amountAsset: DomainLayer.DTO.Dex.Asset,
                             priceAsset: DomainLayer.DTO.Dex.Asset,
                             orderType: DomainLayer.DTO.Dex.OrderType,
                             ask: Money?,
                             bid: Money?,
                             last: Money?,
                             availableAmountAssetBalance: Money,
                             availablePriceAssetBalance: Money,
                             availableBalances: [DomainLayer.DTO.SmartAssetBalance],
                             scriptedAssets: [DomainLayer.DTO.Asset])
}
