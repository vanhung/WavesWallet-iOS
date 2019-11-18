//
//  ChangePasswordModuleBuilder.swift
//  WavesWallet-iOS
//
//  Created by mefilt on 16/10/2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import UIKit
import DomainLayer
import Extensions

struct ChangePasswordModuleBuilder: ModuleBuilderOutput {

    struct Input: ChangePasswordModuleInput {
        var wallet: DomainLayer.DTO.Wallet
    }

    var output: ChangePasswordModuleOutput

    func build(input: Input) -> UIViewController {

        let presenter = ChangePasswordPresenter(input: input)
        let vc = StoryboardScene.ChangePassword.changePasswordViewController.instantiate()
        presenter.moduleOutput = output        
        vc.presenter = presenter

        return vc
    }
}
