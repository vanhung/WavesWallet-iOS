//
//  DexTraderContainerModuleBuilder.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 8/15/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import UIKit
import Extensions

struct DexTraderContainerModuleBuilder: ModuleBuilderOutput {
    
    weak var output: DexTraderContainerModuleOutput?
    weak var orderBookOutput: DexOrderBookModuleOutput?
    weak var lastTradesOutput: DexLastTradesModuleOutput?
    weak var myOrdersOutpout: DexMyOrdersModuleOutput?
    
    var backAction:(() -> Void)?
    
    func build(input: DexTraderContainer.DTO.Pair) -> UIViewController {
        let vc = StoryboardScene.Dex.dexTraderContainerViewController.instantiate()
        vc.pair = input
        vc.moduleOutput = output
        vc.backAction = backAction
        
        vc.addViewController(DexOrderBookModuleBuilder(output: orderBookOutput).build(input: input), isScrollEnabled: true)
        vc.addViewController(DexChartModuleBuilder().build(input: input), isScrollEnabled: false)
        vc.addViewController(DexLastTradesModuleBuilder(output: lastTradesOutput).build(input: input), isScrollEnabled: true)
        vc.addViewController(DexMyOrdersModuleBuilder(output: myOrdersOutpout).build(input: input), isScrollEnabled: true)
        return vc
    }
}

