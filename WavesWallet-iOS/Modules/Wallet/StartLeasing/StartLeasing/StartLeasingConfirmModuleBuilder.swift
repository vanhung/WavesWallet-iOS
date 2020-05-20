//
//  StartLeasingConfirmModuleBuilder.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 11/21/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import UIKit
import Extensions

struct StartLeasingConfirmModuleBuilder: ModuleBuilderOutput {
    
    var output: StartLeasingModuleOutput?
    var errorDelegate: StartLeasingErrorDelegate?
    
    func build(input: StartLeasingTypes.Kind) -> UIViewController {
        
        switch input {
        case .send(let order):
            let vc = StoryboardScene.StartLeasing.startLeasingConfirmationViewController.instantiate()
            vc.order = order
            vc.output = output
            vc.errorDelegate = errorDelegate
            return vc
        
        case .cancel(let cancelOrder):
            let vc = StoryboardScene.StartLeasing.startLeasingCancelConfirmationViewController.instantiate()
            vc.cancelOrder = cancelOrder
            vc.output = output
            return vc
        }
    }
}
