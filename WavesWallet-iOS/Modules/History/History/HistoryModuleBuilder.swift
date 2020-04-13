//
//  HistoryModuleBuilder.swift
//  WavesWallet-iOS
//
//  Created by Mac on 07/08/2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import UIKit
import Extensions

struct HistoryModuleBuilder: ModuleBuilderOutput {
    
    var output: HistoryModuleOutput
    
    func build(input: HistoryModuleInput) -> UIViewController {
        
        let presenter = HistoryPresenter(input: input)
        let vc = StoryboardScene.History.historyViewController.instantiate()
        
        presenter.interactor = HistoryInteractor()
        presenter.moduleOutput = output
        vc.presenter = presenter

        switch input.type {
        case .all:
            vc.createBackButton()

        default:
            vc.createBackButton()
        }
        
        return vc
    }
}

struct HistoryInput: HistoryModuleInput {
    
    let inputType: HistoryType
    
    var type: HistoryType {
        return inputType
    }
}
