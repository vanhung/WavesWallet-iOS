//
//  AppCoordinator.swift
//  WavesWallet-iOS
//
//  Created by mefilt on 13.09.2018.
//  Copyright © 2018 Waves Platform. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RESideMenu
import RxOptional
import WavesSDKExtensions
import WavesSDK
import Extensions
import DomainLayer

private enum Contants {

    #if DEBUG
    static let delay: TimeInterval = 1
    #else
    static let delay: TimeInterval = 10
    #endif
}

struct Application: TSUD {

    struct Settings: Codable, Mutating {
        var isAlreadyShowHelloDisplay: Bool  = false
    }

    private static let key: String = "com.waves.application.settings"

    static var defaultValue: Settings {
        return Settings(isAlreadyShowHelloDisplay: false)
    }

    static var stringKey: String {
        return Application.key
    }
}

protocol ApplicationCoordinatorProtocol: AnyObject {
    func showEnterDisplay()
}

final class AppCoordinator: Coordinator {

    var childCoordinators: [Coordinator] = []
    weak var parent: Coordinator?

    private let windowRouter: WindowRouter

    private let authoAuthorizationInteractor: AuthorizationUseCaseProtocol = UseCasesFactory.instance.authorization
    private let mobileKeeperRepository: MobileKeeperRepositoryProtocol = UseCasesFactory.instance.repositories.mobileKeeperRepository
    private let applicationVersionUseCase: ApplicationVersionUseCaseProtocol = UseCasesFactory.instance.applicationVersionUseCase
    
    private let disposeBag: DisposeBag = DisposeBag()
    private var deepLink: DeepLink? = nil
    private var isActiveApp: Bool = false
    private var snackError: String? = nil
    private var isActiveForceUpdate: Bool = false
    
#if DEBUG || TEST
    init(_ debugWindowRouter: DebugWindowRouter, deepLink: DeepLink?) {
        self.windowRouter = debugWindowRouter
        debugWindowRouter.delegate = self
        self.deepLink = deepLink
    }
#else
    init(_ windowRouter: WindowRouter, deepLink: DeepLink?) {
        self.windowRouter = windowRouter
        self.deepLink = deepLink
    }
#endif

    func start() {
        self.isActiveApp = true
        
        #if DEBUG || TEST
            if CommandLine.arguments.contains("UI-Develop") {
                addChildCoordinatorAndStart(childCoordinator: UIDeveloperCoordinator(windowRouter: windowRouter))
            } else {
                logInApplication()
            }
        #else
            logInApplication()
        #endif

        if let deepLink = deepLink {
            openURL(link: deepLink)
        }
        
        checkAndRunForceUpdate()
    }

    private var isMainTabDisplayed: Bool {
        return childCoordinators.first(where: { $0 is MainTabBarCoordinator }) != nil
    }
}

// MARK: Methods for showing differnt displays
extension AppCoordinator: PresentationCoordinator {

    enum Display {
        case hello
        case slide(DomainLayer.DTO.Wallet)
        case enter
        case passcode(DomainLayer.DTO.Wallet)
        case widgetSettings
        case mobileKeeper(DomainLayer.DTO.MobileKeeper.Request)
        case send(DeepLink)
        case dex(DeepLink)
        case forceUpdate(DomainLayer.DTO.VersionUpdateData)
    }

    func showDisplay(_ display: AppCoordinator.Display) {

        switch display {
        case .hello:
            guard isActiveForceUpdate == false else { return }

            let helloCoordinator = HelloCoordinator(windowRouter: windowRouter)
            helloCoordinator.delegate = self
            addChildCoordinatorAndStart(childCoordinator: helloCoordinator)

        case .passcode(let wallet):
            guard isActiveForceUpdate == false else { return }

            guard isHasCoordinator(type: PasscodeLogInCoordinator.self) != true else { return }

            let passcodeCoordinator = PasscodeLogInCoordinator(wallet: wallet, routerKind: .alertWindow)
            passcodeCoordinator.delegate = self

            addChildCoordinatorAndStart(childCoordinator: passcodeCoordinator)

        case .slide(let wallet):
            guard isActiveForceUpdate == false else { return }
            guard isHasCoordinator(type: SlideCoordinator.self) != true else {
                showDeepLinkVcIfNeed()
                return
            }
            
            let slideCoordinator = SlideCoordinator(windowRouter: windowRouter, wallet: wallet)
            slideCoordinator.menuViewControllerDelegate = self
            addChildCoordinatorAndStart(childCoordinator: slideCoordinator)            
            showDeepLinkVcIfNeed()
            
        case .enter:
            guard isActiveForceUpdate == false else { return }

            let prevSlideCoordinator = self.childCoordinators.first { (coordinator) -> Bool in
                return coordinator is SlideCoordinator
            }

            guard prevSlideCoordinator?.isHasCoordinator(type: EnterCoordinator.self) != true else { return }

            let slideCoordinator = SlideCoordinator(windowRouter: windowRouter, wallet: nil)
            slideCoordinator.menuViewControllerDelegate = self
            addChildCoordinatorAndStart(childCoordinator: slideCoordinator)
        
        case .widgetSettings:
            guard isActiveForceUpdate == false else { return }
            guard isHasCoordinator(type: WidgetSettingsCoordinator.self) != true else {
                return
            }
        
            let coordinator = WidgetSettingsCoordinator(windowRouter: windowRouter)
            addChildCoordinatorAndStart(childCoordinator: coordinator)
            
        case .mobileKeeper(let request):
            guard isActiveForceUpdate == false else { return }

            let coordinator = MobileKeeperCoordinator(windowRouter: windowRouter, request: request)
            addChildCoordinatorAndStart(childCoordinator: coordinator)
 
        case .send(let link):
            guard isActiveForceUpdate == false else { return }
            deepLink = link
            
        case.dex(let link):
            guard isActiveForceUpdate == false else { return }
            deepLink = link

        case .forceUpdate(let data):
            isActiveForceUpdate = true

            //add coordinator
            let vc = StoryboardScene.ForceUpdateApp.forceUpdateAppViewController.instantiate()
            vc.data = data
            windowRouter.window.rootViewController = vc
            windowRouter.window.makeKeyAndVisible()
        }
    }
    
    func openURL(link: DeepLink) {
        guard isActiveForceUpdate == false else { return }
        if link.url.absoluteString == DeepLink.widgetSettings {
            self.showDisplay(.widgetSettings)
        }
        else if link.isClientSendLink {
            self.showDisplay(.send(link))
        }
        else if link.isClientDexLink {
            self.showDisplay(.dex(link))
        }
        else if link.isMobileKeeper {
            
            mobileKeeperRepository
                .decodableRequest(link.url)
                .observeOn(MainScheduler.asyncInstance)
                .subscribe(onNext: { (request) in
                    guard let request = request else { return }
                    self.showDisplay(.mobileKeeper(request))
                }, onError: { [weak self] (error) in
                    
                    if let error = error as? MobileKeeperUseCaseError {
                        self?.showErrorView(with: error)
                    }
                })
                .disposed(by: disposeBag)
        }
    }
    
    //TODO: Localization
    private func showErrorView(with error: MobileKeeperUseCaseError) {
        
        if let snackError = snackError {
            UIApplication.shared.windows.last?.rootViewController?.hideSnack(key: snackError)
        }
        
        switch error {
        case .dAppDontOpen:
            snackError = showErrorSnack("Application don't open")
            
        case .dataIncorrect:
            snackError = showErrorSnack("Request incorect")
            
        case .transactionDontSupport:
            snackError = showErrorSnack("Transaction don't support")
        default:
            snackError = UIApplication.shared.windows.last?.rootViewController?.showErrorNotFoundSnackWithoutAction()
        }
    }
    
    private func showErrorSnack(_ message: (String)) -> String? {
        return UIApplication.shared.windows.last?.rootViewController?.showErrorSnackWithoutAction(title: message)
    }
}

// MARK: Main Logic
extension AppCoordinator  {

    private func showDeepLinkVcIfNeed() {
        if let link = deepLink, link.isClientSendLink {
           
            guard isHasCoordinator(type: SendCoordinator.self) != true else {
                return
            }
            let coordinator = SendCoordinator(windowRouter: windowRouter, deepLink: link)
            addChildCoordinatorAndStart(childCoordinator: coordinator)
        }
        else if let link = deepLink, link.isClientDexLink {
            guard isHasCoordinator(type: DexDeepLinkCoordinator.self) != true else {
                return
            }
            let coordinator = DexDeepLinkCoordinator(windowRouter: windowRouter, deepLink: link)
            addChildCoordinatorAndStart(childCoordinator: coordinator)
        }
    }
    
    private func display(by wallet: DomainLayer.DTO.Wallet?) -> Observable<Display> {

        if let wallet = wallet {
            return display(by: wallet)
        } else {
            let settings = Application.get()
            if settings.isAlreadyShowHelloDisplay {
                return Observable.just(Display.enter)
            } else {
                return Observable.just(Display.hello)
            }
        }
    }

    private func display(by wallet: DomainLayer.DTO.Wallet) -> Observable<Display> {
        return authoAuthorizationInteractor
            .isAuthorizedWallet(wallet)
            .map { isAuthorizedWallet -> Display in
                if isAuthorizedWallet {
                    return Display.slide(wallet)
                } else {
                    return Display.passcode(wallet)
                }
        }
    }

    private func logInApplication() {
        authoAuthorizationInteractor
            .lastWalletLoggedIn()
            .take(1)
            .catchError { _ -> Observable<DomainLayer.DTO.Wallet?> in
                return Observable.just(nil)
            }
            .subscribeOn(ConcurrentDispatchQueueScheduler(queue: DispatchQueue.global()))
            .observeOn(MainScheduler.asyncInstance)
            .flatMap(weak: self, selector: { $0.display })
            .subscribe(weak: self, onNext: { $0.showDisplay })
            .disposed(by: disposeBag)
    }

    private func revokeAuthAndOpenPasscode() {

        Observable
            .just(1)
            .delay(Contants.delay, scheduler: MainScheduler.asyncInstance)
            .flatMap { [weak self] _ -> Observable<DomainLayer.DTO.Wallet?> in

                guard let self = self else { return Observable.never() }

                if self.isActiveApp == true {
                    return Observable.never()
                }

                return
                    self
                        .authoAuthorizationInteractor
                        .revokeAuth()
                        .flatMap({ [weak self] (_) -> Observable<DomainLayer.DTO.Wallet?> in
                            guard let self = self else { return Observable.never() }

                            return self.authoAuthorizationInteractor
                                .lastWalletLoggedIn()
                                .take(1)
                        })
            }
            .share()
            .subscribeOn(ConcurrentDispatchQueueScheduler(queue: DispatchQueue.global()))
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(weak: self, onNext: { owner, wallet in
                if let wallet = wallet {
                    owner.showDisplay(.passcode(wallet))
                } else if Application.get().isAlreadyShowHelloDisplay {
                    owner.showDisplay(.enter)
                }
            })
            .disposed(by: disposeBag)
    }
}

// MARK: HelloCoordinatorDelegate
extension AppCoordinator: HelloCoordinatorDelegate  {

    func userFinishedGreet() {
        var settings = Application.get()
        settings.isAlreadyShowHelloDisplay = true
        Application.set(settings)
        showDisplay(.enter)
    }

    func userChangedLanguage(_ language: Language) {
        Language.change(language)
    }
}

// MARK: PasscodeLogInCoordinatorDelegate
extension AppCoordinator: PasscodeLogInCoordinatorDelegate {

    func passcodeCoordinatorLogInCompleted(wallet: DomainLayer.DTO.Wallet) {
        showDisplay(.slide(wallet))
    }

    func passcodeCoordinatorWalletLogouted() {
        showDisplay(.enter)
        deepLink = nil
    }
}


// MARK: Lifecycle application
extension AppCoordinator {

    func applicationDidEnterBackground() {
        isActiveApp = false
        deepLink = nil
        revokeAuthAndOpenPasscode()
    }

    func applicationDidBecomeActive() {
        if isActiveApp {
            return
        }
        isActiveApp = true
    }
}



// MARK: DebugWindowRouterDelegate
extension AppCoordinator: DebugWindowRouterDelegate  {
    
    func relaunchApplication() {

        self.authoAuthorizationInteractor
            .logout()
            .subscribe(onCompleted: { [weak self] in
                guard let self = self else { return }
                self.showDisplay(.enter)
            })
            .disposed(by: self.disposeBag)
    }
}


// MARK: MenuViewControllerDelegate
extension AppCoordinator: MenuViewControllerDelegate {
    
    func menuViewControllerDidTapWavesLogo() {
        
        let vc = StoryboardScene.Support.debugViewController.instantiate()
        vc.delegate = self
        let nv = CustomNavigationController()
        nv.viewControllers = [vc]
        nv.modalPresentationStyle = .fullScreen
        self.windowRouter.window.rootViewController?.present(nv, animated: true, completion: nil)
    }
}

// MARK: DebugViewControllerDelegate
extension AppCoordinator: DebugViewControllerDelegate {

    func dissmissDebugVC(isNeedRelaunchApp: Bool) {
        
        if isNeedRelaunchApp {
            relaunchApplication()
        }
        
        self.windowRouter.window.rootViewController?.dismiss(animated: true, completion: nil)
    }
}

//MARK: - ForceUpdate
private extension AppCoordinator {
    func checkAndRunForceUpdate() {
        
        applicationVersionUseCase.isNeedForceUpdate()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] data in
                guard let self = self else { return }

                if data.isNeedForceUpdate {
                    self.showDisplay(.forceUpdate(data))
                }
            }).disposed(by: disposeBag)
        
    }
}
