//
//  TransactionCardSponsorshipDetailCell.swift
//  WavesWallet-iOS
//
//  Created by rprokofev on 12/03/2019.
//  Copyright © 2019 Waves Exchange. All rights reserved.
//

import Foundation
import UIKit
import Extensions

final class TransactionCardSponsorshipDetailCell: UITableViewCell, Reusable {

    struct Model {
        let balance: BalanceLabel.Model
    }

    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var balanceLabel: BalanceLabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        separatorInset = .init(top: 0, left: self.bounds.width, bottom: 0, right: 0)
    }
}

// MARK: ViewConfiguration

extension TransactionCardSponsorshipDetailCell: ViewConfiguration {

    func update(with model: TransactionCardSponsorshipDetailCell.Model) {

        titleLabel.text = Localizable.Waves.Transactioncard.Title.amountPerTransaction

        balanceLabel.update(with: model.balance)
    }
}
