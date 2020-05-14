//
//  DexOrderBookLastPriceCell.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 8/16/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Extensions
import UIKit
import UITools

final class DexOrderBookLastPriceCell: UITableViewCell, Reusable {
    @IBOutlet private weak var labelPrice: UILabel!
    @IBOutlet private weak var labelSpread: UILabel!
    @IBOutlet private weak var iconState: UIImageView!
    @IBOutlet private weak var labelLastPrice: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        labelLastPrice.text = Localizable.Waves.Dexorderbook.Label.lastPrice
    }
}

extension DexOrderBookLastPriceCell: ViewConfiguration {
    func update(with model: DexOrderBook.DTO.LastPrice) {
        labelPrice.text = model.price.displayText

        if model.percent > 0 {
            labelSpread.text = Localizable.Waves.Dexorderbook.Label.spread + " " + String(format: "%.02f", model.percent) + "%"
        } else {
            labelSpread.text = Localizable.Waves.Dexorderbook.Label.spread + " 0" + "%"
        }

        if model.orderType == .sell {
            iconState.image = Images.chartarrow22Error500.image
        } else if model.orderType == .buy {
            iconState.image = Images.chartarrow22Success400.image
        } else {
            iconState.image = Images.chartarrow22Accent100.image
        }
    }
}
