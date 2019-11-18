//
//  WidgetSettingsCoordinator.swift
//  WavesWallet-iOS
//
//  Created by rprokofev on 01.08.2019.
//  Copyright © 2019 Waves Exchange. All rights reserved.
//

import UIKit
import RxSwift
import WavesSDKExtensions
import DomainLayer
import Extensions

private enum StatePopover {
    
    case none
    case syncAssets([DomainLayer.DTO.Asset])
}

private enum WidgetState {
    case none
    case callback((([DomainLayer.DTO.Asset]) -> Void))
}

final class WidgetSettingsCoordinator: Coordinator {
    
    var childCoordinators: [Coordinator] = []
    
    weak var parent: Coordinator?
    
    private var navigationRouter: NavigationRouter
    
    private var windowRouter: WindowRouter
    
    private let disposeBag: DisposeBag = DisposeBag()
    
    private var statePopover: StatePopover = .none
    
    private var widgetState: WidgetState = .none
    
    private lazy var popoverViewControllerTransitioning = ModalViewControllerTransitioning { [weak self] in
        guard let self = self else { return }
        
        switch self.statePopover {
        case .syncAssets(let assets):
            if case .callback(let callback) = self.widgetState {
                callback(assets)
            }            
            
        default:
            break
        }
    }

    init(windowRouter: WindowRouter) {
        
        let window = UIWindow()
        window.windowLevel = UIWindow.Level.init(rawValue: UIWindow.Level.normal.rawValue + 1.0)
        self.windowRouter = WindowRouter.windowFactory(window: window)
        self.navigationRouter = NavigationRouter(navigationController: CustomNavigationController())
        
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    @objc private func didEnterBackground() {
        widgetSettingsClose()
    }

    func start() {
        
        let vc = WidgetSettingsModuleBuilder(output: self).build()
        
        windowRouter.setRootViewController(self.navigationRouter.navigationController)
        self.navigationRouter.pushViewController(vc)
    }
}

// MARK: AssetsSearchModuleOutput

extension WidgetSettingsCoordinator: AssetsSearchModuleOutput {
    
    func assetsSearchSelectedAssets(_ assets: [DomainLayer.DTO.Asset]) {
        self.statePopover = .syncAssets(assets)
    }
    
    func assetsSearchClose() {
        self.navigationRouter.dismiss(animated: true, completion: nil)
    }
}

// MARK: WidgetSettingsModuleOutput

extension WidgetSettingsCoordinator: WidgetSettingsModuleOutput {
    
    func widgetSettingsClose() {
        
        windowRouter.dissmissWindow(animated: nil, completed: { [weak self] in
            guard let self = self else { return }
            self.removeFromParentCoordinator()
        })
    }
    
    func widgetSettingsSyncAssets(_ current: [DomainLayer.DTO.Asset], minCountAssets: Int, maxCountAssets: Int, callback: @escaping (([DomainLayer.DTO.Asset]) -> Void)) {
        
        let vc = AssetsSearchViewBuilder(output: self)
            .build(input: .init(assets: current, minCountAssets: minCountAssets, maxCountAssets: maxCountAssets))
        
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = popoverViewControllerTransitioning
        
        self.widgetState = .callback(callback)
        
        self.navigationRouter.present(vc, animated: true) {
            
        }
    }
    
    func widgetSettingsChangeInterval(_ selected: DomainLayer.DTO.Widget.Interval?, callback: @escaping (_ asset: DomainLayer.DTO.Widget.Interval) -> Void) {
        
        let all = DomainLayer.DTO.Widget.Interval.all
        
        let elements: [ActionSheet.DTO.Element] = all.map { .init(title: $0.title) }
        
        let selectedElement = elements.first(where: { $0.title == (selected?.title ?? "") })
        
        let data = ActionSheet.DTO.Data.init(title: Localizable.Waves.Widgetsettings.Actionsheet.Changeinterval.title,
                                             elements: elements,
                                             selectedElement: selectedElement)
            
        let vc = ActionSheetViewBuilder { [weak self] (element) in
            guard let interval = all.first(where: { (interval) -> Bool in
                return interval.title == element.title
            }) else { return }
            callback(interval)
            self?.navigationRouter.dismiss(animated: true, completion: nil)
        }
        .build(input: data)
        
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = popoverViewControllerTransitioning
                        
        self.navigationRouter.present(vc, animated: true) {
            
        }
    }
    
    func widgetSettingsChangeStyle(_ selected: DomainLayer.DTO.Widget.Style?, callback: @escaping (_ style: DomainLayer.DTO.Widget.Style) -> Void) {
    
        let all = DomainLayer.DTO.Widget.Style.all
        
        let elements: [ActionSheet.DTO.Element] = all.map { .init(title: $0.title) }
        
        let selectedElement = elements.first(where: { $0.title == (selected?.title ?? "") })
        
        let data = ActionSheet.DTO.Data.init(title: Localizable.Waves.Widgetsettings.Actionsheet.Changestyle.title,
                                             elements: elements,
                                             selectedElement: selectedElement)
        
        let vc = ActionSheetViewBuilder { [weak self] (element) in
            guard let style = all.first(where: { (style) -> Bool in
                return style.title == element.title
            }) else { return }
            callback(style)
            self?.navigationRouter.dismiss(animated: true, completion: nil)
        }
        .build(input: data)
        
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = popoverViewControllerTransitioning
        
        self.navigationRouter.present(vc, animated: true) {
            
        }
    }
}
