//
//  SkeletonAnimatable.swift
//  WavesWallet-iOS
//
//  Created by mefilt on 16.08.2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import Skeleton

enum SkeletonDirection: Int {
    case left
    case right
}

protocol SkeletonAnimatable: GradientsOwner {

    func startAnimation(to dir: SkeletonDirection)
    func stopAnimation()
}

private enum AssociatedKeys {
    static var direction = "direction"
    static var isHaveListener = "isHaveListener"
}

extension SkeletonAnimatable where Self: UIView {

    fileprivate var direction: SkeletonDirection {

        get {
            return associatedObject(for: &AssociatedKeys.direction) ?? .right
        }

        set {
            setAssociatedObject(newValue, for: &AssociatedKeys.direction)
        }
    }

    fileprivate var isHaveListener: Bool {

        get {
            return associatedObject(for: &AssociatedKeys.isHaveListener) ?? false
        }

        set {
            setAssociatedObject(newValue, for: &AssociatedKeys.isHaveListener)
        }
    }

    private func startListener() {
        if isHaveListener {
            return
        }

        isHaveListener = true
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    private func stopListener() {
        isHaveListener = false
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    func startAnimation(to dir: SkeletonDirection = .right) {

        stopAnimation()

        self.direction = dir

        let direction: Direction = dir == .left ? .left : .right
        slide(to: direction)
        startListener()
    }

    func stopAnimation() {
        stopListener()
        stopSliding()
    }
}

fileprivate extension UIView { 
    @objc func didBecomeActive() {
        if let skeleton = self as? (UIView & SkeletonAnimatable) {
            skeleton.startAnimation(to: skeleton.direction)
        }
    }

    @objc func didEnterBackground() {
        if let skeleton = self as? (UIView & SkeletonAnimatable) {
            skeleton.stopAnimation()
        }
    }
}
