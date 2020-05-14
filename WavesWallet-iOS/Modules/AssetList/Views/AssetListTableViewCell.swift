//
//  AssetListTableViewCell.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 10/4/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import DataLayer
import DomainLayer
import Extensions
import RxSwift
import UIKit
import UITools

private enum Constants {
    static let defaultTopTitleOffset: CGFloat = 10
}

final class AssetListTableViewCell: UITableViewCell, NibReusable {
    @IBOutlet private weak var iconAsset: UIImageView!
    @IBOutlet private weak var labelAssetName: UILabel!
    @IBOutlet private weak var labelAmount: UILabel!
    @IBOutlet private weak var iconCheckmark: UIImageView!
    @IBOutlet private weak var iconFav: UIImageView!
    @IBOutlet private weak var topTitleOffset: NSLayoutConstraint!

    private var disposeBag: DisposeBag = DisposeBag()

    override func prepareForReuse() {
        super.prepareForReuse()
        iconAsset.image = nil
        disposeBag = DisposeBag()
    }
}

extension AssetListTableViewCell: ViewConfiguration {
    struct Model {
        let asset:  Asset
        let balance: Money
        let isChecked: Bool
        let isFavourite: Bool
    }

    func update(with model: Model) {
        let centerOffset = frame.size.height / 2 - labelAssetName.frame.size.height / 2
        topTitleOffset.constant = model.balance.isZero ? centerOffset : Constants.defaultTopTitleOffset
        labelAmount.isHidden = model.balance.isZero

        labelAssetName.text = model.asset.displayName
        iconFav.isHidden = !model.isFavourite

        labelAmount.text = model.balance.displayText

        AssetLogo.logo(icon: model.asset.iconLogo,
                       style: AssetLogo.Style.litle)
            .observeOn(MainScheduler.instance)
            .bind(to: iconAsset.rx.image)
            .disposed(by: disposeBag)

        iconCheckmark.image = model.isChecked ? Images.on.image : Images.off.image
    }
}
