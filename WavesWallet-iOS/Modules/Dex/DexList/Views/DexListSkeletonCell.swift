//
//  DexListSkeletonCell.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 7/25/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import UIKit
import Extensions

final class DexListSkeletonCell: SkeletonTableCell, Reusable {

    @IBOutlet weak var viewContainer: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        viewContainer.addTableCellShadowStyle()
    }
    
    class func cellHeight() -> CGFloat {
        return DexListCell.cellHeight()
    }
    
}
