//
//  WalletQuickNoteCell.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 4/29/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import UIKit
import Extensions

fileprivate enum Constants {
    static let padding: CGFloat = 16
    static let pictureSize: CGFloat = 28
    static let paddingPictureRight: CGFloat = 14
    static let separatorHeight: CGFloat = 1
    static let paddingSeparatorTop: CGFloat = 14
    static let paddingSecondTitleTop: CGFloat = 13
    static let paddingThirdTitleTop: CGFloat = 13
    static let paddingThirdTitleBottom: CGFloat = 8
}

final class WalletQuickNoteCell: UITableViewCell, NibReusable {

    typealias Model = Void

    @IBOutlet private weak var viewContent: UIView!
    @IBOutlet private weak var firstTitle: UILabel!
    @IBOutlet private weak var secondTitle: UILabel!
    @IBOutlet private weak var thirdTitle: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        viewContent.backgroundColor = UIColor.basic50
        backgroundColor = UIColor.basic50
        setupLocalization()
    }

    class func cellHeight(with width: CGFloat) -> CGFloat {
        
        let font = UIFont.systemFont(ofSize: 13)
        let text1 = Localizable.Waves.Wallet.Label.Quicknote.Description.first
        let text2 = Localizable.Waves.Wallet.Label.Quicknote.Description.second
        let text3 = Localizable.Waves.Wallet.Label.Quicknote.Description.third

        var height = text1.maxHeightMultiline(font: font, forWidth: width - Constants.padding * 2)
        height += Constants.paddingSeparatorTop + Constants.separatorHeight + Constants.paddingSecondTitleTop
        height += text2.maxHeightMultiline(font: font, forWidth: width - Constants.padding * 2 - Constants.pictureSize - Constants.paddingPictureRight)
        height += Constants.paddingSeparatorTop + Constants.separatorHeight + Constants.paddingThirdTitleTop
        height += text3.maxHeightMultiline(font: font, forWidth: width - Constants.padding * 2)
        return height + Constants.paddingThirdTitleBottom
    }
}

// MARK: Localization

extension WalletQuickNoteCell: Localization {
    func setupLocalization() {
        firstTitle.text = Localizable.Waves.Wallet.Label.Quicknote.Description.first
        secondTitle.text = Localizable.Waves.Wallet.Label.Quicknote.Description.second
        thirdTitle.text = Localizable.Waves.Wallet.Label.Quicknote.Description.third
    }
}

// MARK: ViewConfiguration

extension WalletQuickNoteCell: ViewConfiguration {

    func update(with model: Void) {
        setupLocalization()
    }
}
