//
//  WalletHistorySkeletonCell.swift
//  WavesWallet-iOS
//
//  Created by mefilt on 17.07.2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import UIKit
import Extensions

final class WalletHistorySkeletonCell: SkeletonTableCell, NibReusable {
    
    @IBOutlet private weak var viewContent: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        viewContent.addTableCellShadowStyle()
        backgroundColor = UIColor.basic50
    }

    class func cellHeight() -> CGFloat {
        return 56
    }
}
