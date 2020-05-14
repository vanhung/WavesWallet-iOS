//
//  SendFeeTableViewCell.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 1/31/19.
//  Copyright © 2019 Waves Exchange. All rights reserved.
//

import Extensions
import RxSwift
import UIKit
import UITools

private enum Constants {
    static let height: CGFloat = 56
    static let noneActiveAlpha: CGFloat = 0.3
}

final class SendFeeTableViewCell: UITableViewCell, Reusable {
    @IBOutlet private weak var iconLogo: UIImageView!
    @IBOutlet private weak var labelTitle: UILabel!
    @IBOutlet private weak var labelSubtitle: UILabel!
    @IBOutlet private weak var iconCheckmark: UIImageView!

    private var disposeBag: DisposeBag = DisposeBag()

    override func prepareForReuse() {
        super.prepareForReuse()
        iconLogo.image = nil
        disposeBag = DisposeBag()
    }
}

extension SendFeeTableViewCell: ViewConfiguration {
    func update(with model: SendFee.DTO.SponsoredAsset) {
        labelTitle.text = model.assetBalance.asset.displayName

        AssetLogo.logo(icon: model.assetBalance.asset.iconLogo,
                       style: .medium)
            .observeOn(MainScheduler.instance)
            .bind(to: iconLogo.rx.image)
            .disposed(by: disposeBag)

        iconCheckmark.image = model.isChecked ? Images.on.image : Images.off.image
        labelTitle.textColor = model.isActive ? .black : .blueGrey
        iconLogo.alpha = model.isActive ? 1 : Constants.noneActiveAlpha
        iconCheckmark.isHidden = !model.isActive

        let feeText = model.fee.displayText + " " + model.assetBalance.asset.displayName
        labelSubtitle.text = model.isActive ? feeText : Localizable.Waves.Sendfee.Label.notAvailable
    }
}

extension SendFeeTableViewCell: ViewHeight {
    static func viewHeight() -> CGFloat {
        return Constants.height
    }
}
