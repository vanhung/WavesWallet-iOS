//
//  TransactionCardOrderFilledCell.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 6/5/19.
//  Copyright © 2019 Waves Exchange. All rights reserved.
//

import Extensions
import UIKit
import UITools
import WavesSDKExtensions

final class TransactionCardOrderFilledCell: UITableViewCell, Reusable {
    struct Model {
        let filled: BalanceLabel.Model
    }

    @IBOutlet private weak var balanceLabel: BalanceLabel!
    @IBOutlet private weak var labelTitle: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        labelTitle.text = Localizable.Waves.Transactioncard.Title.filled
    }
}

extension TransactionCardOrderFilledCell: ViewConfiguration {
    func update(with model: TransactionCardOrderFilledCell.Model) {
        balanceLabel.update(with: model.filled)
    }
}
