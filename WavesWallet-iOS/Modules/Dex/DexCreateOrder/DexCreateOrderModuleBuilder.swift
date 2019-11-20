//
//  DexSellBuyModuleBuilder.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 9/11/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import UIKit
import DomainLayer
import Extensions
 
struct DexCreateOrderModuleBuilder: ModuleBuilderOutput {
    
    weak var output: DexCreateOrderModuleOutput?

    func build(input: DexCreateOrder.DTO.Input) -> UIViewController {
        
        let interactor: DexCreateOrderInteractorProtocol = DexCreateOrderInteractor()
        
        var presenter: DexCreateOrderPresenterProtocol = DexCreateOrderPresenter()
        presenter.interactor = interactor
        presenter.pair = DomainLayer.DTO.Dex.Pair(amountAsset: input.amountAsset,
                                                  priceAsset: input.priceAsset)
        
        let vc = StoryboardScene.Dex.dexCreateOrderViewController.instantiate()
        vc.input = input
        vc.presenter = presenter
        vc.moduleOutput = output
        
        return vc
    }
}
