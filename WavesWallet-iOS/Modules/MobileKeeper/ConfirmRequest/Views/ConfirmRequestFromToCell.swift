//
//  ConfirmRequestFromToCell.swift
//  WavesWallet-iOS
//
//  Created by rprokofev on 27.08.2019.
//  Copyright © 2019 Waves Exchange. All rights reserved.
//

import Foundation
import UIKit
import Extensions
import IdentityImg
import Kingfisher

private enum Constants {
    static let iconSize: CGSize = CGSize(width: 28, height: 28)
}

final class ConfirmRequestFromToCell: UITableViewCell, Reusable {
    
    struct Model {
        let accountName: String
        let address: String
        let dAppIcon: String
        let dAppName: String
    }
    
    @IBOutlet private var dAppAddressView: ConfirmRequestAddressView!
    @IBOutlet private var walletAddressView: ConfirmRequestAddressView!
    
    private let identity: Identity = Identity(options: Identity.defaultOptions)

    override func awakeFromNib() {
        super.awakeFromNib()
        selectedBackgroundView = UIView()
        selectionStyle = .none
    }
}

// MARK: ViewConfiguration

extension ConfirmRequestFromToCell: ViewConfiguration {
    
    func update(with model: Model) {
        
        let image = identity.createImage(by: model.address, size: Constants.iconSize) ?? UIImage()
                
        walletAddressView.update(with: .init(title: Localizable.Waves.Transactioncard.Title.from,
                                             address: model.accountName,
                                             image: image))
        
        dAppAddressView.update(with: .init(title: Localizable.Waves.Keeper.Label.to,
                                            address: model.dAppName,
                                            image: UIImage()))
        

        if let url = URL(string: model.dAppIcon) {
            dAppAddressView.iconImageView.kf.setImage(with: url) { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .failure:
                    self.dAppAddressView.iconImageView.image = AssetLogo.createLogo(name: model.dAppName,
                                                                                    logoColor: .clearBlue,
                                                                                    style: .medium)
                default:
                    break
                }
            }
        }
        else {
            dAppAddressView.iconImageView.image = AssetLogo.createLogo(name: model.dAppName,
                                                                       logoColor: .clearBlue,
                                                                       style: .medium)
        }
    }
}

final class ConfirmRequestAddressView: UIView, Reusable {
    
    struct Model {
        let title: String
        let address: String
        let image: UIImage
    }
    
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet fileprivate var iconImageView: UIImageView!
    @IBOutlet private var addressLabel: UILabel!

    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        iconImageView.layer.cornerRadius = iconImageView.frame.height * 0.5
    }
}

// MARK: ViewConfiguration

extension ConfirmRequestAddressView: ViewConfiguration {
    
    func update(with model: Model) {
        self.titleLabel.text = model.title
        self.addressLabel.text = model.address
        self.iconImageView.image = model.image
    }
}

