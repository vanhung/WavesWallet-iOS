//
//  DexOrderBookRepositoryProtocol.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 12/17/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import RxSwift

public protocol DexOrderBookRepositoryProtocol {
    
    func orderBook(amountAsset: String, priceAsset: String) -> Observable<DomainLayer.DTO.Dex.OrderBook>
    
    func markets(wallet: DomainLayer.DTO.SignedWallet, pairs: [DomainLayer.DTO.Dex.Pair]) -> Observable<[DomainLayer.DTO.Dex.SmartPair]>

    func myOrders(wallet: DomainLayer.DTO.SignedWallet, amountAsset: DomainLayer.DTO.Dex.Asset, priceAsset: DomainLayer.DTO.Dex.Asset) -> Observable<[DomainLayer.DTO.Dex.MyOrder]>

    func cancelOrder(wallet: DomainLayer.DTO.SignedWallet, orderId: String, amountAsset: String, priceAsset: String) -> Observable<Bool>

    func createOrder(wallet: DomainLayer.DTO.SignedWallet, order: DomainLayer.Query.Dex.CreateOrder, type: DomainLayer.Query.Dex.CreateOrderType) -> Observable<Bool>

    func orderSettingsFee() -> Observable<DomainLayer.DTO.Dex.SettingsOrderFee>
}
