//
//  AppDelegate.swift
//  WavesWallet-iOS
//
//  Created by Alexey Koloskov on 20/04/2017.
//  Copyright © 2017 Waves Exchange. All rights reserved.
//

import IQKeyboardManagerSwift
import RESideMenu
import RxSwift
import UIKit

import WavesSDK
import WavesSDKCrypto
import WavesSDKExtensions

import DataLayer
import DomainLayer
import Extensions
import Firebase
import FirebaseMessaging
import Intercom

#if DEBUG
    import SwiftMonkeyPaws
#endif

#if DEBUG
    enum UITest {
        static var isEnabledonkeyTest: Bool { CommandLine.arguments.contains("--MONKEY_TEST") }
    }
#endif

@UIApplicationMain class AppDelegate: UIResponder, UIApplicationDelegate {
    var disposeBag = DisposeBag()

    var window: UIWindow?

    var appCoordinator: AppCoordinator!

    lazy var migrationInteractor: MigrationUseCaseProtocol = UseCasesFactory.instance.migration

    #if DEBUG
        var paws: MonkeyPaws?
    #endif

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        var url: URL?

        if let path = launchOptions?[.url] as? String {
            url = URL(string: path)
        }

        if let scheme = url?.scheme, DeepLink.scheme != scheme {
            return false
        }

        var deepLink: DeepLink?

        if let url = url {
            deepLink = DeepLink(url: url)
        }

        guard setupLayers() else { return false }

        UNUserNotificationCenter.current().delegate = self
        
        application.registerForRemoteNotifications()
        
        setupUI()
        setupServices()

        let router = WindowRouter.windowFactory(window: window!)

        appCoordinator = AppCoordinator(router, deepLink: deepLink)

        migrationInteractor
            .migration()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { _ in },
                       onError: { _ in },
                       onCompleted: { self.appCoordinator.start() })
            .disposed(by: disposeBag)

        application.registerForRemoteNotifications()
        return true
    }

    func application(_: UIApplication, open url: URL, options _: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        if DeepLink.scheme != url.scheme {
            return false
        }

        appCoordinator.openURL(link: DeepLink(url: url))

        return true
    }

    func applicationWillResignActive(_: UIApplication) {}

    func applicationDidEnterBackground(_: UIApplication) {
        appCoordinator.applicationDidEnterBackground()

        Intercom.hideMessenger()
    }

    func applicationWillEnterForeground(_: UIApplication) {}

    func applicationDidBecomeActive(_ application: UIApplication) {
        appCoordinator.applicationDidBecomeActive()
        application.applicationIconBadgeNumber = 0
    }

    func applicationWillTerminate(_: UIApplication) {}

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {}
    
    func application(_ application: UIApplication,
                     open: URL,
                     sourceApplication: String?,
                     annotation: Any) -> Bool { false }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
                
        Messaging.messaging().apnsToken = deviceToken
                    
        appCoordinator.application(application,
                                   didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
            
    }

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        appCoordinator.application(application,
                                   didReceiveRemoteNotification: userInfo,
                                   fetchCompletionHandler: completionHandler)
    }
}

extension AppDelegate {
    func setupUI() {
        Swizzle(initializers: [UIView.passtroughInit, UIView.insetsInit, UIView.shadowInit]).start()

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .basic50

        #if DEBUG
            if UITest.isEnabledonkeyTest {
                paws = MonkeyPaws(view: window!)
            }
        #endif

        IQKeyboardManager.shared.enable = true
        UIBarButtonItem.appearance().tintColor = UIColor.black

        Language.load(localizable: Localizable.self, languages: Language.list)
    }

    func setupLayers() -> Bool {
        guard let googleServiceInfoPath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") else {
            return false
        }

        guard let googleServiceInfoPathWaves = Bundle.main.path(forResource: "GoogleService-Info-Waves", ofType: "plist") else {
            return false
        }

        guard let appsflyerInfoPath = Bundle.main.path(forResource: "Appsflyer-Info", ofType: "plist") else {
            return false
        }

        guard let amplitudeInfoPath = Bundle.main.path(forResource: "Amplitude-Info", ofType: "plist") else {
            return false
        }

        guard let sentryIoInfoPath = Bundle.main.path(forResource: "Sentry-io-Info", ofType: "plist") else {
            return false
        }

        Intercom.setApiKey("ios_sdk-5f049396b8a724034920255ca7645cadc3ee1920", forAppId: "ibdxiwmt")
        
        let resourses = RepositoriesFactory.Resources(googleServiceInfo: googleServiceInfoPath,
                                                      appsflyerInfo: appsflyerInfoPath,
                                                      amplitudeInfo: amplitudeInfoPath,
                                                      sentryIoInfoPath: sentryIoInfoPath,
                                                      googleServiceInfoForWavesPlatform: googleServiceInfoPathWaves)
        
        let services = ServicesFactoryImp()
        
        let repositories = RepositoriesFactory(resources: resourses,
                                               services: services)        

        Intercom.setApiKey("ios_sdk-5f049396b8a724034920255ca7645cadc3ee1920",
                           forAppId: "ibdxiwmt")

        UseCasesFactory.initialization(services: services,
                                       repositories: repositories,
                                       authorizationInteractorLocalizable: AuthorizationInteractorLocalizableImp())

        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func setupServices() {
        #if DEBUG || TEST

            SweetLogger.current.add(plugin: SweetLoggerConsole(visibleLevels: [.warning, .debug, .error, .network],
                                                               isShortLog: true))
            SweetLogger.current.visibleLevels = [.warning, .debug, .error, .network]

        #else
            SweetLogger.current.add(plugin: SweetLoggerSentry(visibleLevels: [.error, .network]))
            SweetLogger.current.visibleLevels = [.warning, .debug, .error, .network]

        #endif
    }

    class func shared() -> AppDelegate { UIApplication.shared.delegate as! AppDelegate }

    var menuController: RESideMenu { window?.rootViewController as! RESideMenu }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    
        completionHandler([.alert, .sound])
    }
}
