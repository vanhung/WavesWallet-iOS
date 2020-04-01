//
//  ProfileCoordinator.swift
//  WavesWallet-iOS
//
//  Created by mefilt on 04/10/2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import UIKit
import RxSwift
import StoreKit
import MessageUI
import DomainLayer
import Extensions

final class ProfileCoordinator: Coordinator {

    var childCoordinators: [Coordinator] = []
    weak var parent: Coordinator?
    private weak var applicationCoordinator: ApplicationCoordinatorProtocol?

    private let authorization = UseCasesFactory.instance.authorization

    private let navigationRouter: NavigationRouter
    private let disposeBag: DisposeBag = DisposeBag()

    init(navigationRouter: NavigationRouter, applicationCoordinator: ApplicationCoordinatorProtocol?) {
        self.applicationCoordinator = applicationCoordinator
        self.navigationRouter = navigationRouter
    }

    func start() {
        let vc = ProfileModuleBuilder(output: self).build()

        self.navigationRouter.pushViewController(vc, animated: true) { [weak self] in
            guard let self = self else { return }
            self.removeFromParentCoordinator()
        }
        setupBackupTost(target: vc, navigationRouter: navigationRouter, disposeBag: disposeBag)
    }
}

// MARK: ProfileModuleOutput

extension ProfileCoordinator: ProfileModuleOutput {

    func showBackupPhrase(wallet: DomainLayer.DTO.Wallet, saveBackedUp: @escaping ((_ isBackedUp: Bool) -> Void)) {

        authorization
            .authorizedWallet()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] (signedWallet) in

                guard let self = self else { return }

                let seed = signedWallet.seedWords

                UseCasesFactory
                    .instance
                    .analyticManager
                    .trackEvent(.profile(.profileBackupPhrase))
                
                
                if wallet.isBackedUp == false {
                    
                    let backup = BackupCoordinator(seed: seed,
                                                   behaviorPresentation: .push(self.navigationRouter),
                                                   hasShowNeedBackupView: false,
                                                   completed: { isSkipBackup in
                        saveBackedUp(!isSkipBackup)
                    })
                    self.addChildCoordinatorAndStart(childCoordinator: backup)
                } else {
                    let vc = StoryboardScene.Backup.saveBackupPhraseViewController.instantiate()
                    vc.input = .init(seed: seed, isReadOnly: true)
                    self.navigationRouter.pushViewController(vc)
                }
            })
            .disposed(by: disposeBag)
    }

    func showAddressesKeys(wallet: DomainLayer.DTO.Wallet) {
        
        UseCasesFactory
            .instance
            .analyticManager
            .trackEvent(.profile(.profileAddressAndKeys))
        
        guard let applicationCoordinator = self.applicationCoordinator else { return }

        let coordinator = AddressesKeysCoordinator(navigationRouter: navigationRouter,
                                                   wallet: wallet,
                                                   applicationCoordinator: applicationCoordinator)
        addChildCoordinatorAndStart(childCoordinator: coordinator)
    }

    func showAddressBook() {
        
        UseCasesFactory
            .instance
            .analyticManager
            .trackEvent(.addressBook(.profileAddressBookPage))
        
        let vc = AddressBookModuleBuilder(output: nil)
            .build(input: .init(isEditMode: true))
        navigationRouter.pushViewController(vc)
    }

    func showLanguage() {
        
        UseCasesFactory
            .instance
            .analyticManager
            .trackEvent(.profile(.profileLanguage))
        
        let language = StoryboardScene.Language.languageViewController.instantiate()
        language.delegate = self
        navigationRouter.pushViewController(language)
    }

    func showNetwork(wallet: DomainLayer.DTO.Wallet) {
        
        UseCasesFactory
            .instance
            .analyticManager
            .trackEvent(.profile(.profileNetwork))
        
        let vc = NetworkSettingsModuleBuilder(output: self)
            .build(input: .init(wallet: wallet))
        navigationRouter.pushViewController(vc)
    }

    func showRateApp() {
        
        UseCasesFactory
            .instance
            .analyticManager
            .trackEvent(.profile(.profileRateApp))
        
        #if DEBUG
        if UITest.isEnabledonkeyTest {
            return
        }
        #endif
        RateApp.show()
    }

    func showFeedback() {
        
        UseCasesFactory
            .instance
            .analyticManager
            .trackEvent(.profile(.profileFeedback))
        
        #if DEBUG
        if UITest.isEnabledonkeyTest {
            return
        }
        #endif
        let coordinator = MailComposeCoordinator(viewController: navigationRouter.navigationController,
                                                 email: UIGlobalConstants.supportEmail)
        addChildCoordinator(childCoordinator: coordinator)
        coordinator.start()
    }

    func showSupport() {
        
        UseCasesFactory
            .instance
            .analyticManager
            .trackEvent(.profile(.profileSupport))
        
        #if DEBUG
        if UITest.isEnabledonkeyTest {
            return
        }
        #endif
        
        if let url = URL(string: UIGlobalConstants.URL.support) {
            BrowserViewController.openURL(url)
        }
    }

    func showAlertForEnabledBiometric() {
        let alertController = UIAlertController.showAlertForEnabledBiometric()
        navigationRouter.present(alertController)
    }

    func accountSetEnabledBiometric(isOn: Bool, wallet: DomainLayer.DTO.Wallet) {
        let passcode = PasscodeCoordinator(kind: .setEnableBiometric(isOn, wallet: wallet),
                                           behaviorPresentation: .push(navigationRouter, dissmissToRoot: true))
        passcode.delegate = self
        addChildCoordinatorAndStart(childCoordinator: passcode)
    }

    func showChangePasscode(wallet: DomainLayer.DTO.Wallet) {
        
        UseCasesFactory
            .instance
            .analyticManager
            .trackEvent(.profile(.profileChangePasscode))
        
        let passcode = PasscodeCoordinator(kind: .changePasscode(wallet),
                                           behaviorPresentation: .push(navigationRouter, dissmissToRoot: true))

        passcode.delegate = self
        addChildCoordinatorAndStart(childCoordinator: passcode)
    }

    func showChangePassword(wallet: DomainLayer.DTO.Wallet) {
        
        UseCasesFactory
            .instance
            .analyticManager
            .trackEvent(.profile(.profileChangePassword))
        
        let vc = ChangePasswordModuleBuilder(output: self)
            .build(input: .init(wallet: wallet))
        navigationRouter.pushViewController(vc)
    }
    
    func openDebug() {
        let vc = StoryboardScene.Support.debugViewController.instantiate()
        vc.delegate = self
        let nv = CustomNavigationController()
        nv.viewControllers = [vc]
        nv.modalPresentationStyle = .fullScreen
        navigationRouter.present(nv, animated: true, completion: nil)
    }

    func accountLogouted() {
        
        #if DEBUG
        if UITest.isEnabledonkeyTest {
            return
        }
        #endif
        self.applicationCoordinator?.showEnterDisplay()
    }

    func accountDeleted() {
        
        UseCasesFactory
            .instance
            .analyticManager
            .trackEvent(.profile(.profileDeleteAccount))
        
        #if DEBUG
        if UITest.isEnabledonkeyTest {
            return
        }
        #endif
        self.applicationCoordinator?.showEnterDisplay()
    }
}

extension ProfileCoordinator: DebugViewControllerDelegate {
    func dissmissDebugVC(isNeedRelaunchApp: Bool) {
        if isNeedRelaunchApp {
            relaunchApplication()
        }

        navigationRouter.dismiss(animated: true, completion: nil)
    }
    
    func relaunchApplication() {
        authorization
            .logout()
            .subscribe(onCompleted: { [weak self] in
                guard let self = self else { return }
                self.applicationCoordinator?.showEnterDisplay()
            })
            .disposed(by: disposeBag)
    }
}

// MARK: PasscodeCoordinatorDelegate

extension ProfileCoordinator: PasscodeCoordinatorDelegate {

    func passcodeCoordinatorAuthorizationCompleted(wallet: DomainLayer.DTO.Wallet) {}

    func passcodeCoordinatorWalletLogouted() {
        applicationCoordinator?.showEnterDisplay()
    }

    func passcodeCoordinatorVerifyAcccesCompleted(signedWallet: DomainLayer.DTO.SignedWallet) {}
}

// MARK: LanguageViewControllerDelegate

extension ProfileCoordinator: LanguageViewControllerDelegate {
    func languageViewChangedLanguage() {
        navigationRouter.popViewController()
    }
}

// MARK: ChangePasswordModuleOutput

extension ProfileCoordinator: ChangePasswordModuleOutput {
    func changePasswordCompleted(wallet: DomainLayer.DTO.Wallet, newPassword: String, oldPassword: String) {

        let passcode = PasscodeCoordinator(kind: .changePassword(wallet: wallet,
                                                                 newPassword: newPassword,
                                                                 oldPassword: oldPassword),
                                           behaviorPresentation: .push(navigationRouter, dissmissToRoot: true))

        passcode.delegate = self
        addChildCoordinatorAndStart(childCoordinator: passcode)        
    }
}

// MARK: NetworkSettingsModuleOutput

extension ProfileCoordinator: NetworkSettingsModuleOutput {

    func networkSettingSavedSetting() {
        NotificationCenter.default.post(name: .changedSpamList, object: nil)
        navigationRouter.popViewController()
    }
}


