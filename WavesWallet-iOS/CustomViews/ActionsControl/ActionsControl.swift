//
//  ActionsControl.swift
//  WavesWallet-iOS
//
//  Created by rprokofev on 12/03/2019.
//  Copyright © 2019 Waves Exchange. All rights reserved.
//

import Extensions
import Foundation
import UIKit
import UITools

private struct Constants {
    static let spacingBetweenButtons: CGFloat = 8
    static let scrollViewContentEdgeInsets: UIEdgeInsets = .init(top: 0, left: 16, bottom: 0, right: 16)
    static let contentEdgeInsets: UIEdgeInsets = .init(top: 10, left: 20, bottom: 10, right: 12)
    static let imageEdgeInsets: UIEdgeInsets = .init(top: 0, left: -16, bottom: 0, right: 0)
    static let buttonCornerRadius: CGFloat = 4
}

final class ActionsControl: UIView, NibOwnerLoadable {
    struct Model {
        enum Effect {
            case changeIconForTime(UIImage, TimeInterval)
            case changeTitleForTime(String, TimeInterval)
            case changeTitleColorForTime(UIColor, TimeInterval)
            case impactOccurred
            case loading
        }

        struct Button {
            let backgroundColor: UIColor
            let selectedBackgroundColor: UIColor
            let textColor: UIColor
            let text: String
            let icon: UIImage
            let effectsOnTap: [Effect]
            let tapHanler: () -> Void
        }

        let buttons: [Button]
    }

    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet private var stackView: UIStackView!

    @IBOutlet private var rightGradientView: GradientView!
    @IBOutlet private var leftGradientView: GradientView!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadNibContent()
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: frame.width, height: UIView.noIntrinsicMetric)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        scrollView.delegate = self

        stackView.spacing = Constants.spacingBetweenButtons
        scrollView.contentInset = Constants.scrollViewContentEdgeInsets

        rightGradientView.startColor = UIColor.white.withAlphaComponent(0.0)
        rightGradientView.endColor = UIColor.white
        rightGradientView.direction = .custom(GradientView.Settings(startPoint: CGPoint(x: 0.0, y: 0),
                                                                    endPoint: CGPoint(x: 1, y: 0),
                                                                    locations: [0.0, 1]))
        leftGradientView.startColor = UIColor.white
        leftGradientView.endColor = UIColor.white.withAlphaComponent(0.0)
        leftGradientView.direction = .custom(GradientView.Settings(startPoint: CGPoint(x: 0.0, y: 0),
                                                                   endPoint: CGPoint(x: 1, y: 0),
                                                                   locations: [0, 1.0]))
    }
}

extension ActionsControl: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.x > 0 {
            leftGradientView.isHidden = false
        } else {
            leftGradientView.isHidden = true
        }
    }
}

private final class ActionButton: UIButton {
    private var effectsOnTap: [ActionsControl.Model.Effect] = []
    private var tapHanler: (() -> Void)?

    init(_ model: ActionsControl.Model.Button) {
        super.init(frame: CGRect.zero)

        effectsOnTap = model.effectsOnTap
        tapHanler = model.tapHanler
        titleLabel?.font = .systemFont(ofSize: 13, weight: .regular)

        setImage(model.icon, for: .normal)
        setImage(model.icon, for: .highlighted)

        setTitle(model.text, for: .normal)
        setTitleColor(model.textColor, for: .normal)
        setBackgroundImage(model.backgroundColor.image, for: .normal)
        setBackgroundImage(model.selectedBackgroundColor.image, for: .highlighted)
        layer.cornerRadius = Constants.buttonCornerRadius
        layer.masksToBounds = true
        contentEdgeInsets = Constants.contentEdgeInsets
        imageEdgeInsets = Constants.imageEdgeInsets

        addTarget(self, action: #selector(handlerTapAction), for: .touchUpInside)
    }

    @objc func handlerTapAction() {
        for effect in effectsOnTap {
            switch effect {
            case let .changeIconForTime(image, interval):

                let oldImage = imageView?.image
                setImage(image, for: .normal)
                setImage(image, for: .highlighted)
                isUserInteractionEnabled = false

                DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
                    self.setImage(oldImage, for: .normal)
                    self.setImage(oldImage, for: .highlighted)
                    self.isUserInteractionEnabled = true
                }
            case let .changeTitleForTime(title, interval):

                let oldTitle = self.title(for: .normal)
                setTitle(title, for: .normal)
                isUserInteractionEnabled = false

                DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
                    self.setTitle(oldTitle, for: .normal)
                    self.isUserInteractionEnabled = true
                }

            case let .changeTitleColorForTime(color, interval):

                let oldColor = titleColor(for: .normal)
                setTitleColor(color, for: .normal)
                isUserInteractionEnabled = false

                DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
                    self.setTitleColor(oldColor, for: .normal)
                    self.isUserInteractionEnabled = true
                }

            case .impactOccurred:
                ImpactFeedbackGenerator.impactOccurred()

            case .loading:

                let activityIndicator = UIActivityIndicatorView()
                activityIndicator.hidesWhenStopped = true
                activityIndicator.startAnimating()
                activityIndicator.style = .white
                activityIndicator.translatesAutoresizingMaskIntoConstraints = false

                setImage(nil, for: .normal)
                setTitle("", for: .normal)
                isUserInteractionEnabled = false

                addSubview(activityIndicator)

                let constraint = widthAnchor.constraint(equalToConstant: frame.width)
                centerXAnchor.constraint(equalTo: activityIndicator.centerXAnchor).isActive = true
                centerYAnchor.constraint(equalTo: activityIndicator.centerYAnchor).isActive = true

                constraint.isActive = true
            }
        }
        tapHanler?()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ActionsControl: ViewConfiguration {
    func update(with model: ActionsControl.Model) {
        stackView.arrangedSubviews.forEach { stackView.removeArrangedSubview($0) }
        stackView.subviews.forEach { $0.removeFromSuperview() }

        model.buttons.forEach { stackView.addArrangedSubview(ActionButton($0)) }

        stackView.addArrangedSubview(UIView())
    }
}
