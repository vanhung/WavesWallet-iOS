//
//  SplashScreenCoordinator.swift
//  WavesWallet-iOS
//
//  Created by rprokofev on 23.06.2020.
//  Copyright © 2020 Waves Platform. All rights reserved.
//

import UIKit

final class SplashScreenCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    weak var parent: Coordinator?

    private lazy var windowRouter: WindowRouter = WindowRouter.windowFactory(window: self.window)
    private let navigationRouter: NavigationRouter = NavigationRouter(navigationController: CustomNavigationController())

    private let window: UIWindow = {
        let window = UIWindow()
        window.bounds = UIScreen.main.bounds
        window.backgroundColor = .clear
        window.windowLevel = UIWindow.Level(rawValue: UIWindow.Level.normal.rawValue + 10.0)
        return window
    }()

    init() {}

    func start() {
        
        
        let vc = SplashScreenVC.instantiateFromStoryboard()

        vc.animatedCompleted = { [weak self] in
            self?.window.isHidden = true
            self?.window.removeFromSuperview()
            self?.removeFromParentCoordinator()
        }
        
        navigationRouter.pushViewController(vc)
        windowRouter.setRootViewController(navigationRouter.navigationController)
    }
}

    