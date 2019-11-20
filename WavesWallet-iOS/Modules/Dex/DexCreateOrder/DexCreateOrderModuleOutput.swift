//
//  DexCreateOrderModuleOutput.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 9/21/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation

protocol DexCreateOrderModuleOutput: AnyObject {
    
    func dexCreateOrderDidCreate(output: DexCreateOrder.DTO.Output)
    
    func dexCreateOrderWarningForPrice(isPriceHigherMarket: Bool, callback: @escaping ((_ isSuccess: Bool) -> Void))
}

protocol DexCreateOrderProtocol {
    func updateCreatedOrders()
}

protocol DexCancelOrderProtocol {
    func updateCanceledOrders()
}
