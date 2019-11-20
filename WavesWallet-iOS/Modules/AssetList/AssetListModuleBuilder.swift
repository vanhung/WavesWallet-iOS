//
//  AssetListModuleBuilder.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 10/5/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import UIKit
import Extensions

struct AssetListModuleBuilder: ModuleBuilderOutput {
    
    var output: AssetListModuleOutput
    
    func build(input: AssetList.DTO.Input) -> UIViewController {
        
        let interactor: AssetListInteractorProtocol = AssetListInteractor()
        let presenter = AssetListPresenter()
        presenter.interactor = interactor
        presenter.filters = input.filters
        presenter.moduleOutput = output
        presenter.isMyList = !input.showAllList
        
        let vc = StoryboardScene.AssetList.assetListViewController.instantiate()
        vc.presenter = presenter
        vc.selectedAsset = input.selectedAsset
        vc.showAllList = input.showAllList
        
        return vc
    }
}
