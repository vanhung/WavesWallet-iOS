//
//  DexOrderBookHeaderView.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 8/16/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import UIKit
import Extensions

final class DexOrderBookHeaderView: DexTraderContainerBaseHeaderView, NibOwnerLoadable {
    
    @IBOutlet private weak var labelAmountAssetName: UILabel!
    @IBOutlet private weak var labelPriceAssetName: UILabel!
    @IBOutlet private weak var labelSumAssetName: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadNibContent()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadNibContent()
    }
}

//MARK: - SetupUI

extension DexOrderBookHeaderView: ViewConfiguration {
    
    func update(with model: DexOrderBook.ViewModel.Header) {
        labelAmountAssetName.text = Localizable.Waves.Dexorderbook.Label.amount + " " + model.amountName
        labelPriceAssetName.text = Localizable.Waves.Dexorderbook.Label.price + " " + model.priceName
        labelSumAssetName.text = Localizable.Waves.Dexorderbook.Label.sum + " " + model.sumName
    }
}
