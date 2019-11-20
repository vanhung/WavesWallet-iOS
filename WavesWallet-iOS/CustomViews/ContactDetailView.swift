//
//  ContactDetailView.swift
//  WavesWallet-iOS
//
//  Created by rprokofev on 07/03/2019.
//  Copyright © 2019 Waves Exchange. All rights reserved.
//

import Foundation
import UIKit
import Extensions

final class ContactDetailView: UIView, NibOwnerLoadable {

    struct Model {
        let title: String
        let address: String
        let name: String?
    }

    @IBOutlet private var titleLabel: UILabel!

    @IBOutlet private var nameLabel: UILabel!

    @IBOutlet private var addressLabel: UILabel!

    @IBOutlet private var stackView: UIStackView!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadNibContent()
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: frame.width, height: UIView.noIntrinsicMetric)
    }
}

// MARK: ViewConfiguration

extension ContactDetailView: ViewConfiguration {

    func update(with model: Model) {

        self.titleLabel.text = model.title

        if let name = model.name {
            self.nameLabel.text = name
            self.nameLabel.isHidden = false
            self.addressLabel.font = UIFont.systemFont(ofSize: 10)
        } else {
            self.nameLabel.isHidden = true
            self.addressLabel.font = UIFont.systemFont(ofSize: 13)
        }

        self.addressLabel.text = model.address
    }
}
