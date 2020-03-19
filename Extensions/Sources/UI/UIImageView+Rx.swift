//
//  UIImageView+Rx.swift
//  WavesWallet-iOS
//
//  Created by mefilt on 13/02/2019.
//  Copyright © 2019 Waves Exchange. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

public extension Reactive where Base: UIImageView {

    /// Bindable sink for `image` property.
    var imageAnimationFadeIn: Binder<UIImage?> {
        return Binder(base) { imageView, image in

            if imageView.image == nil {
                imageView.image = image
                return
            }

            UIView.transition(with: imageView,
                              duration: 0.3,
                              options: .transitionCrossDissolve,
                              animations:
                {
                    let object = imageView as UIImageView
                    object.image = image
            }, completion: { _ in })
        }
    }
}
