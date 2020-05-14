//
//  SweetSnackbarView.swift
//  SweetSnackbar
//
//  Created by Prokofev Ruslan on 17/10/2018.
//  Copyright © 2018 Waves. All rights reserved.
//

import Extensions
import UIKit
import UITools

private enum Constants {
    static let durationAnimation: TimeInterval = 1.8
    static let multiplyPIAnimation: Double = 4
    static let bottomPadding: CGFloat = 16
}

final class SweetSnackView: UIView, NibLoadable {
    @IBOutlet private var leftLayout: NSLayoutConstraint!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var subtitleLabel: UILabel!
    @IBOutlet private var leftAtIconConstraint: NSLayoutConstraint!
    @IBOutlet private var leftAtSuperviewConstraint: NSLayoutConstraint!
    @IBOutlet private var bottomAtSuperviewConstraint: NSLayoutConstraint!
    @IBOutlet private var iconImageView: UIImageView!

    private var isHiddenIcon: Bool = true
    private var isStartedAnimation: Bool = true
    private(set) var model: SweetSnack?

    var bottomOffsetPadding: CGFloat = 0 {
        didSet {
            bottomAtSuperviewConstraint.constant = bottomOffsetPadding + Constants.bottomPadding
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func updateConstraints() {
        leftAtIconConstraint.isActive = !isHiddenIcon
        leftAtSuperviewConstraint.isActive = isHiddenIcon

        super.updateConstraints()
    }

    func update(model: SweetSnack) {
        self.model = model

        backgroundColor = model.backgroundColor
        if let icon = model.icon {
            isHiddenIcon = false
            iconImageView.image = icon
            iconImageView.isHidden = false
        } else {
            isHiddenIcon = true
            iconImageView.image = nil
            iconImageView.isHidden = true
        }

        if model.subtitle != nil {
            titleLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
            subtitleLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        } else {
            titleLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        }

        titleLabel.text = model.title
        subtitleLabel.text = model.subtitle
        subtitleLabel.isHidden = model.subtitle == nil

        setNeedsUpdateConstraints()
    }

    func startAnimationIcon() {
        isStartedAnimation = true

        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.fromValue = 0
        animation.repeatCount = Float.infinity
        animation.duration = Constants.durationAnimation
        animation.toValue = Double.pi * -Constants.multiplyPIAnimation
        animation.isCumulative = true
        animation.timingFunction = TimingFunction.easeOut.caMediaTimingFuction

        iconImageView.layer.removeAllAnimations()
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handlerDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
        iconImageView.layer.add(animation, forKey: "rotate")
    }

    func stopAnimationIcon() {
        isStartedAnimation = false
        iconImageView.layer.removeAllAnimations()
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    @objc private func handlerDidBecomeActive() {
        if isStartedAnimation {
            startAnimationIcon()
        }
    }
}
