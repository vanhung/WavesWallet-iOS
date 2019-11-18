//
//  AliasesViewModuleBuilder.swift
//  WavesWallet-iOS
//
//  Created by mefilt on 29/10/2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import UIKit
import DomainLayer
import Extensions

struct AliasesModuleBuilder: ModuleBuilderOutput {

    struct Input: AliasesModuleInput {
        let aliases: [DomainLayer.DTO.Alias]
    }

    var output: AliasesModuleOutput

    func build(input: Input) -> UIViewController {

        let vc = StoryboardScene.Profile.aliasesViewController.instantiate()
        let presenter = AliasesPresenter()
        presenter.moduleInput = input
        presenter.moduleOutput = output
        vc.presenter = presenter

        return vc
    }
}

