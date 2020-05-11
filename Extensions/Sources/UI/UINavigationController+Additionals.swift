//
//  UINavigationController+Additionals.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 7/19/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import UIKit

public extension UINavigationController {
    func pushViewControllerAndSetLast(_ viewController: UIViewController) {
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            self.viewControllers = [self.viewControllers.last!]
        }
        pushViewController(viewController, animated: true)
        CATransaction.commit()
    }
}

public extension UIImage {
    static func shadowImage(color: UIColor) -> UIImage? {
        UIGraphicsBeginImageContext(CGSize(width: 0.5, height: 0.5))
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
        color.setFill()
        ctx.fill(CGRect(x: 0, y: 0, width: 0.5, height: 0.5))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
