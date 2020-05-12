//
//  ProfilePushTableCell.swift
//  WavesWallet-iOS
//
//  Created by Prokofev Ruslan on 03/10/2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Extensions
import UIKit
import UITools

private enum Constants {
    static let height: CGFloat = 56
}

final class ProfileDisabledButtomTableCell: UITableViewCell, Reusable, ViewConfiguration {
    typealias Model = String

    @IBOutlet private weak var titleLabel: UILabel!

    class func cellHeight() -> CGFloat {
        return Constants.height
    }

    func update(with model: String) {
        titleLabel.text = model
    }
}
