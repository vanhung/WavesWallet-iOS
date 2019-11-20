//
//  DexListModuleBuilder.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 8/7/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import UIKit
import Extensions

struct DexListModuleBuilder: ModuleBuilderOutput {
    
    weak var output: DexListModuleOutput?
    
    func build(input: Void) -> UIViewController {
        
        let vc = StoryboardScene.Dex.dexListViewController.instantiate()
        let presenter = DexListPresenter()
        presenter.interactor = DexListInteractor()
        presenter.moduleOutput = output
        vc.presenter = presenter
        
        return vc
    }
}
