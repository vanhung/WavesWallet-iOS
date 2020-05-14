//
//  WalletSegmentedView.swift
//  WavesWallet-iOS
//
//  Created by mefilt on 12.07.2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Extensions
import Foundation
import UIKit
import UITools

fileprivate enum Constants {
    static let imageEdgeInsetsForButtonWithIcon = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 8)
    static let contentEdgeInsetsForButtonWithIcon = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 8)
    static let contentEdgeInsetsForButtonOnlyText = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
    static let cornerRadius: CGFloat = 2
    static let height: CGFloat = 30
}

final class SegmentedControl: UIControl, NibOwnerLoadable {
    struct Button {
        struct Icon {
            let normal: UIImage
            let selected: UIImage
        }

        let name: String
        let icon: Icon?

        init(name: String, icon: Icon? = nil) {
            self.name = name
            self.icon = icon
        }
    }

    @IBOutlet var scrollView: SegmentedControlScrollView!
    private var model: [Button] = [Button]()

    var selectedIndex: Int {
        get {
            return scrollView.selectedButtonIndex
        }
        set {
            scrollView.selectedWith(index: newValue, animated: false)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadNibContent()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        scrollView.backgroundColor = .basic50
        scrollView.changedValue = { [weak self] _ in
            guard let self = self else { return }
            self.sendActions(for: .valueChanged)
        }
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: Constants.height)
    }

    func setSelectedIndex(_ index: Int, animation _: Bool) {
        guard selectedIndex != index else { return }
        scrollView.selectedWith(index: index, animated: true)
    }
}

// MARK: - ViewAnimatableConfiguration

extension SegmentedControl: ViewAnimatableConfiguration {
    typealias Model = [SegmentedControl.Button]

    func update(with model: [SegmentedControl.Button], animated _: Bool) {
        self.model = model

        scrollView.removeAllButtons()

        model.forEach { model in
            let button = SegmentedControlButton(type: .custom)
            button.update(with: model)
            scrollView.addButton(button)
        }

        scrollView.selectedWith(index: 0, animated: false)
    }
}

// MARK: - Private Button

fileprivate final class SegmentedControlButton: UIButton, ViewConfiguration {
    private var model: SegmentedControl.Button?

    func update(with model: SegmentedControl.Button) {
        self.model = model
        setTitle(model.name, for: .normal)
        setBackgroundImage(UIColor.clear.image, for: .normal)
        setBackgroundImage(UIColor.basic100.image, for: .highlighted)
        setTitleColor(.basic500, for: .normal)
        setTitleColor(.white, for: .selected)
        titleLabel?.textAlignment = .center
        titleLabel?.font = .captionRegular

        if let icon = model.icon {
            setImage(icon.normal, for: .normal)
            setImage(icon.selected, for: .selected)
            imageEdgeInsets = Constants.imageEdgeInsetsForButtonWithIcon
            contentEdgeInsets = Constants.contentEdgeInsetsForButtonWithIcon
        } else {
            setImage(nil, for: .normal)
            setImage(nil, for: .selected)
            imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            contentEdgeInsets = Constants.contentEdgeInsetsForButtonOnlyText
        }

        layer.cornerRadius = Constants.cornerRadius
        autoresizingMask = .flexibleWidth
        translatesAutoresizingMaskIntoConstraints = false
    }
}
