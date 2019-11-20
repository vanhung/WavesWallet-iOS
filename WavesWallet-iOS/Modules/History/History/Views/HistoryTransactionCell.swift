//
//  HistoryAssetCell.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 5/10/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import UIKit
import DomainLayer
import Extensions

private enum Constansts {
    static let height: CGFloat = 76
    static let lastCellOffset: CGFloat = 5
}

final class HistoryTransactionCell: UITableViewCell, Reusable {

    @IBOutlet private(set) var transactionView: HistoryTransactionView!

    class func cellHeight() -> CGFloat {
        return Constansts.height
    }
    
    class func lastCellHeight() -> CGFloat {
        return Constansts.height + Constansts.lastCellOffset
    }
}

extension HistoryTransactionCell: ViewConfiguration {
    
    func update(with model: DomainLayer.DTO.SmartTransaction) {
        transactionView.update(with: model)
    }
}
