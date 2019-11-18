//
//  TransactionCardHeaderView.swift
//  WavesWallet-iOS
//
//  Created by rprokofev on 13/03/2019.
//  Copyright © 2019 Waves Exchange. All rights reserved.
//

import UIKit
import Extensions

private struct Constants {
    static let cornerRadius: CGFloat = 12
    static let startPoint: CGPoint = CGPoint(x: 0.0, y: 0.5)
    static let endPoint: CGPoint = CGPoint(x: 0.0, y: 1)
}

final class ActionSheetHeaderView: UIView, NibLoadable {

    struct Model {
        let title: String
    }
    
    @IBOutlet private weak var labelTitle: UILabel!
    @IBOutlet private weak var gradientView: UIView!
    @IBOutlet private weak var topBackgroundView: UIView!
    @IBOutlet private weak var separatorView: UIView!

    var isHiddenSepatator: Bool = true {
        didSet {
            self.separatorView.isHidden = self.isHiddenSepatator
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        separatorView.isHidden = true
        isUserInteractionEnabled = false
        backgroundColor = .clear
        layer.cornerRadius = Constants.cornerRadius
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        topBackgroundView.layer.cornerRadius = Constants.cornerRadius
        topBackgroundView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]        
    }
}

extension ActionSheetHeaderView: ViewConfiguration {
    
    func update(with model: ActionSheetHeaderView.Model) {
        self.labelTitle.text = model.title
    }
}
