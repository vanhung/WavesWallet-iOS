//
//  ImportAccountViewController.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 6/29/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import UIKit
import TTTAttributedLabel
import AVFoundation
import Extensions
import DomainLayer

protocol ImportAccountViewControllerDelegate: AnyObject {
    func scanTapped()
}

final class ImportAccountScanViewController: UIViewController {
    
    @IBOutlet final weak var stepOneTitleLabel: UILabel!
    @IBOutlet final weak var stepTwoTitleLabel: UILabel!
    @IBOutlet final weak var stepTwoDetailLabel: UILabel!
    @IBOutlet final weak var stepThreeTitleLabel: UILabel!
    @IBOutlet final weak var scanPairingButton: UIButton!
    
    @IBOutlet var pairingButtonLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var pairingButtonRightConstraint: NSLayoutConstraint!
    
    weak var delegate: ImportAccountViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .basic50
        
        setupLocalization()
        setupConstraints()
    }
    
    private func setupLocalization() {
        stepOneTitleLabel.text = Localizable.Waves.Import.Scan.Label.Step.One.title
        stepTwoDetailLabel.text = Localizable.Waves.Import.Scan.Label.Step.Two.detail
        stepTwoTitleLabel.text = Localizable.Waves.Import.Scan.Label.Step.Two.title
        stepThreeTitleLabel.text = Localizable.Waves.Import.Scan.Label.Step.Three.title
        scanPairingButton.setTitle(Localizable.Waves.Import.Scan.Button.title, for: .normal)
        scanPairingButton.addTableCellShadowStyle()
    }
    
    private func setupConstraints() {
        if Platform.isIphone5 {
            pairingButtonLeftConstraint.constant = 24
            pairingButtonRightConstraint.constant = 24
        } else {
            pairingButtonLeftConstraint.constant = 32
            pairingButtonRightConstraint.constant = 32
        }
    }
    
    // MARK: - Actions
    
    @IBAction func scanTapped(_ sender: Any) {

        UseCasesFactory
            .instance
            .analyticManager
            .trackEvent(.importAccount(.startImportScan))
        
        CameraAccess.requestAccess(success: { [weak self] in
            guard let self = self else { return }
            self.delegate?.scanTapped()
        }, failure: { [weak self] in
            guard let self = self else { return }
            let alert = CameraAccess.alertController
            self.present(alert, animated: true, completion: nil)
        })
    
    }
    
}
