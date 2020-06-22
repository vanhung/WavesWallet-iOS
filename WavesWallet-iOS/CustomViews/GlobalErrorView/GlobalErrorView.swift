//
//  GlobalErrorView.swift
//  WavesWallet-iOS
//
//  Created by Prokofev Ruslan on 25/11/2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Extensions
import Reachability
import UIKit
import UITools
import WavesSDKExtensions

final class GlobalErrorView: UIView, NibOwnerLoadable {
    @IBOutlet private var iconImageView: UIImageView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var subtitleLabel: UILabel!
    @IBOutlet private var retryButton: UIButton!
    @IBOutlet private var sendReportButton: UIButton!

    var retryDidTap: (() -> Void)?
    var sendReportDidTap: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadNibContent()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadNibContent()
    }

    @IBAction func handlerActionRetry() {
        let instance = ReachabilityService.instance
        if instance.connection != .none {
            retryDidTap?()
        }
    }

    @IBAction func handlerActionSendReport() {
        sendReportDidTap?()
    }
}

// MARK: ViewConfiguration

extension GlobalErrorView: ViewConfiguration {
    struct Model {
        enum Kind {
            case internetNotWorking
            case serverError
        }

        let kind: Kind
    }

    func update(with model: GlobalErrorView.Model) {
        switch model.kind {
        case .internetNotWorking:
            iconImageView.image = Images.userimgDisconnect80Multy.image
            titleLabel.text = Localizable.Waves.Servererror.Label.noInternetConnection
            subtitleLabel.text = Localizable.Waves.Servererror.Label.noInternetConnectionDescription
            retryButton.setTitle(Localizable.Waves.Servererror.Button.retry, for: .normal)
            sendReportButton.isHidden = true

        case .serverError:
            iconImageView.image = Images.userimgServerdown80Multy.image
            titleLabel.text = Localizable.Waves.Servererror.Label.allBroken
            subtitleLabel.text = Localizable.Waves.Servererror.Label.allBrokenDescription
            retryButton.setTitle(Localizable.Waves.Servererror.Button.retry, for: .normal)
            sendReportButton.setTitle(Localizable.Waves.Servererror.Button.sendReport, for: .normal)
            sendReportButton.isHidden = true
        }
    }
}
