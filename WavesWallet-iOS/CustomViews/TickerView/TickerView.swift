//
//  SpamView.swift
//  WavesWallet-iOS
//
//  Created by mefilt on 07.08.2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import UIKit
import Extensions

fileprivate enum Constants {
    static let height: CGFloat = 16
    static let cornerRadius: CGFloat = 2
}

final class TickerView: UIView, NibOwnerLoadable {

    struct Model {

        enum Style {
            case soft // Example Money Ticker
            case normal // Example Spam Ticker
        }

        let text: String
        let style: Style
    }

    @IBOutlet private(set) var titleLabel: UILabel!
    private var style: Model.Style = .soft

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadNibContent()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        switch style {
        case .normal:
            backgroundColor = .basic100
            layer.clip(cornerRadius: Constants.cornerRadius)
            layer.removeBorder()
            
        case .soft:
            backgroundColor = .white
            layer.border(cornerRadius: Constants.cornerRadius, borderWidth: 0.5, borderColor: .info500)
        }
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: Constants.height)
    }
}

extension TickerView: ViewConfiguration {

    func update(with model: TickerView.Model) {

        titleLabel.text = model.text
        titleLabel.textColor = .info500
        self.style = model.style
        setNeedsLayout()        
    }
}

extension TickerView {
    static var spamTicker: TickerView.Model {
        return .init(text: Localizable.Waves.General.Ticker.Title.spam,
                     style: .normal)
    }
}
