//
//  TransactionCardKeyValueCell.swift
//  WavesWallet-iOS
//
//  Created by rprokofev on 11/03/2019.
//  Copyright © 2019 Waves Exchange. All rights reserved.
//

import Foundation
import UIKit
import Extensions

private struct Constants {
    static let topPaddingLarge: CGFloat = 24
    static let topPaddingNormal: CGFloat = 14
}

final class TransactionCardKeyValueCell: UITableViewCell, Reusable {

    struct Model {

        struct Style {
            enum Padding {
                case largePadding
                case normalPadding
            }

            let padding: Padding
            let textColor: UIColor
        }

        let key: String
        let value: String
        let style: Style
    }

    @IBOutlet private var keyLabel: UILabel!
    @IBOutlet private var valueLabel: UILabel!
    @IBOutlet private var topLayoutConstaint: NSLayoutConstraint!

    private var model: Model?

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        separatorInset = .init(top: 0, left: self.bounds.width, bottom: 0, right: 0)
    }

    override func updateConstraints() {

        guard let model = model else { return }

        switch model.style.padding {
        case .largePadding:
            self.topLayoutConstaint.constant = Constants.topPaddingLarge

        case .normalPadding:
            self.topLayoutConstaint.constant = Constants.topPaddingNormal
        }

        super.updateConstraints()
    }
}

// MARK: ViewConfiguration

extension TransactionCardKeyValueCell: ViewConfiguration {

    func update(with model: TransactionCardKeyValueCell.Model) {
        
        self.model = model
        keyLabel.text = model.key
        valueLabel.text = model.value
        valueLabel.textColor = model.style.textColor

        needsUpdateConstraints()
    }
}
