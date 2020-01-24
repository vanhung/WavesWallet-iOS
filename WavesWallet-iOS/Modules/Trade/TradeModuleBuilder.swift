//
//  TradeModuleBuilder.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 09.01.2020.
//  Copyright © 2020 Waves Platform. All rights reserved.
//

import Foundation
import Extensions
import DomainLayer

protocol TradeRefreshOutput: AnyObject {
    func pairsDidChange()
}

protocol TradeModuleOutput: AnyObject {

    func myOrdersTapped()
    func searchTapped(selectedAsset: DomainLayer.DTO.Dex.Asset?, delegate: TradeRefreshOutput)
    func tradeDidDissapear()
}

struct TradeModuleBuilder: ModuleBuilderOutput {
        
    var output: TradeModuleOutput
    
    func build(input: DomainLayer.DTO.Dex.Asset?) -> UIViewController {
        let vc = StoryboardScene.Trade.tradeViewController.instantiate()
        vc.system = TradeSystem()
        vc.selectedAsset = input
        vc.output = output
        
        return vc
    }
}
