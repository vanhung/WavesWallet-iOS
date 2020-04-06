//
//  SlideMenuRouter.swift
//  WavesWallet-iOS
//
//  Created by mefilt on 15/01/2019.
//  Copyright © 2019 Waves Exchange. All rights reserved.
//

import Foundation
import UIKit

//TODO: Remove
final class SlideMenuRouter: NSObject {

    public let slideMenu: SlideMenu

    public init(slideMenu: SlideMenu) {
        self.slideMenu = slideMenu
        super.init()
    }

    public func setLeftMenuViewController(_ viewController: UIViewController) {
        slideMenu.leftMenuViewController = viewController
    }

    public func setContentViewController(_ viewController: UIViewController) {
        slideMenu.contentViewController = viewController
    }
}

extension SlideMenuRouter: Router {
    var viewController: UIViewController {
        return slideMenu
    }
}
