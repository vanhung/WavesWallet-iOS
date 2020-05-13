//
//  AssetsSearch.swift
//  WavesWallet-iOS
//
//  Created by rprokofev on 05.08.2019.
//  Copyright © 2019 Waves Exchange. All rights reserved.
//

import Foundation
import WavesSDK
import Extensions
import DomainLayer

enum AssetsSearch {
    
    struct State {
        
        struct UI: DataSourceProtocol {
            
            enum Action {
                case none
                case loading
                case update
                case error(DisplayError)
            }
            
            var sections: [Section]
            var action: Action
            var maxSelectAssets: Int
            var countSelectedAssets: Int
        }
        
        struct Core {
            
            enum Action {
                case none
                case initialAssets
                case search(String)
                case selected([Asset])
            }
            
            var action: Action
            var invalidAction: Action?
            var assets: [Asset]
            var selectAssets: [String: Asset]
            var minSelectAssets: Int
            var maxSelectAssets: Int
            var isInitial: Bool
        }
        
        var ui: UI
        var core: Core
    }
    
    enum Event {        
        case viewDidAppear
        case search(String)
        case select(IndexPath)
        case assets([Asset])
        case handlerError(Error)
        case empty
        case refresh
    }
    
    struct Section: SectionProtocol {
        var rows: [Row]
    }
    
    enum Row {
        case asset(AssetsSearchAssetCell.Model)
        case empty
    }
}

extension AssetsSearch.Row {
    
    var asset: Asset? {
        switch self {
        case .asset(let model):
            return model.asset
        default:
            return nil
        }
    }
}
