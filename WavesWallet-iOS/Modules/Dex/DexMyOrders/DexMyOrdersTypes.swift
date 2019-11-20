//
//  DexMyOrdersTypes.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 8/24/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import DomainLayer
import Extensions

enum DexMyOrders {
    enum DTO {}
    enum ViewModel {}
    
    enum Event {
        case readyView
        case setOrders([DomainLayer.DTO.Dex.MyOrder])
        case refresh
    }
    
    struct State: Mutating {
        enum Action {
            case none
            case update
        }
        
        var action: Action
        var section: DexMyOrders.ViewModel.Section
        var isNeedLoadOrders: Bool
    }
}

extension DexMyOrders.ViewModel {
 
    struct Section: Mutating {
        var items: [Row]
    }

    enum Row {
        case order(DomainLayer.DTO.Dex.MyOrder)
    }
    
    static let dateFormatterTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
    
    static let dateFormatterDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yy"
        return formatter
    }()
}

extension DexMyOrders.ViewModel.Row {
    var order: DomainLayer.DTO.Dex.MyOrder? {
        switch self {
        case .order(let order):
            return order
        }
    }
}

extension DexMyOrders.State: Equatable {
    
    static func == (lhs: DexMyOrders.State, rhs: DexMyOrders.State) -> Bool {
        return lhs.isNeedLoadOrders == rhs.isNeedLoadOrders
    }
}
