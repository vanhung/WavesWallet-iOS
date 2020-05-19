//
//  EditAccountNameCoordinator.swift
//  WavesWallet-iOS
//
//  Created by Mac on 02/11/2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import UIKit
import DomainLayer

final class EditAccountNameCoordinator: Coordinator {
    
    var childCoordinators: [Coordinator] = []
    weak var parent: Coordinator?
    
    private let navigationRouter: NavigationRouter
    private let wallet: Wallet
    
    init(navigationRouter: NavigationRouter, wallet: Wallet) {
        self.navigationRouter = navigationRouter
        self.wallet = wallet
    }
    
    func start() {
        let vc = EditAccountNameModuleBuilder(output: self).build(input: .init(wallet: wallet))
        navigationRouter.pushViewController(vc)
    }
}

extension EditAccountNameCoordinator: EditAccountNameModuleOutput {}

protocol EditAccountNameModuleInput {
    var wallet: Wallet { get }
}

protocol EditAccountNameModuleOutput {}
