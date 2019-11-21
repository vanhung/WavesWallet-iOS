//
//  HelloCoordinator.swift
//  WavesWallet-iOS
//
//  Created by mefilt on 12.09.2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import UIKit
import Extensions

protocol HelloCoordinatorDelegate: AnyObject {
    func userFinishedGreet()
    func userChangedLanguage(_ language: Language)
}

final class HelloCoordinator: Coordinator {

    var childCoordinators: [Coordinator] = []
    weak var parent: Coordinator?

    private var windowRouter: WindowRouter
    private var navigationRouter: NavigationRouter
    
    private var isNewUser: Bool = false

    weak var delegate: HelloCoordinatorDelegate?

    init(windowRouter: WindowRouter, isNewUser: Bool) {
        self.windowRouter = windowRouter
        self.isNewUser = isNewUser
        self.navigationRouter = NavigationRouter(navigationController: CustomNavigationController())        
    }

    func start() {
        
        
        if isNewUser {
            let vc = StoryboardScene.Hello.helloLanguagesViewController.instantiate()
            vc.output = self
            self.navigationRouter.pushViewController(vc, animated: true) { [weak self] in
                guard let self = self else { return }
                self.removeFromParentCoordinator()
            }
        } else {
            let vc = StoryboardScene.Hello.infoPagesViewController.instantiate()
            vc.output = self
            vc.isNewUser = isNewUser
            self.navigationRouter.pushViewController(vc, animated: true) { [weak self] in
                guard let self = self else { return }
                self.removeFromParentCoordinator()
            }
        }

        self.windowRouter.setRootViewController(self.navigationRouter.navigationController)
    }
}

// MARK: HelloLanguagesModuleOutput
extension HelloCoordinator: HelloLanguagesModuleOutput {

    func languageDidSelect(language: Language) {
        delegate?.userChangedLanguage(language)
    }

    func userFinishedChangeLanguage() {
        let vc = StoryboardScene.Hello.infoPagesViewController.instantiate()
        vc.output = self
        vc.isNewUser = isNewUser
        navigationRouter.pushViewController(vc, animated: true)
    }
}

// MARK: InfoPagesViewControllerDelegate
extension HelloCoordinator: InfoPagesViewModuleOutput {
    func userFinishedReadPages() {
        navigationRouter.popViewController()
        self.delegate?.userFinishedGreet()
        self.removeFromParentCoordinator()
    }
}
