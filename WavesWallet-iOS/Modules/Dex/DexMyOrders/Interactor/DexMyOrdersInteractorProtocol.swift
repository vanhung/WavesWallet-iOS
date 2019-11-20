//
//  DexMyOrdersInteractorProtocol.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 8/24/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import RxSwift
import DomainLayer

protocol DexMyOrdersInteractorProtocol {
    
    var pair: DexTraderContainer.DTO.Pair! { get set }

    func myOrders() -> Observable<[DomainLayer.DTO.Dex.MyOrder]>
}
