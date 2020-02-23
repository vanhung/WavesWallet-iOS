//
//  DexLastTradesHeaderView.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 8/22/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import UIKit
import Extensions

final class DexLastTradesHeaderView: DexTraderContainerBaseHeaderView, NibOwnerLoadable {
    
    @IBOutlet private weak var labelSum: UILabel!
    @IBOutlet private weak var labelAmount: UILabel!
    @IBOutlet private weak var labelPrice: UILabel!
    @IBOutlet private weak var labelTime: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadNibContent()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadNibContent()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupTitles()
    }
}

// MARK: - SetupUI
private extension DexLastTradesHeaderView {
    
    func setupTitles() {
        
        labelTime.text = Localizable.Waves.Dexlasttrades.Label.time
        labelAmount.text = Localizable.Waves.Dexlasttrades.Label.amount
        labelPrice.text = Localizable.Waves.Dexlasttrades.Label.price
        labelSum.text = Localizable.Waves.Dexlasttrades.Label.sum
    }
}
