//
//  StakingTransferButtonCell.swift
//  WavesWallet-iOS
//
//  Created by rprokofev on 19.02.2020.
//  Copyright © 2020 Waves Platform. All rights reserved.
//

import Foundation
import Extensions
import UIKit
import TTTAttributedLabel

final class StakingTransferButtonCell: UITableViewCell, NibReusable {
                        
    @IBOutlet private var button: BlueButton!
    
    var didTouchButton: (() -> Void)? {
        didSet {
            button.didTouchButton = didTouchButton
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        button.didTouchButton = didTouchButton
    }
}


// MARK: ViewConfiguration

extension StakingTransferButtonCell: ViewConfiguration {
 
    func update(with model: BlueButton.Model) {
                

    }
}

