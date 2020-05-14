//
//  AddAddressNameTextField.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 9/24/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Extensions
import QRCodeReader
import UIKit
import UITools

private enum Constansts {
    static let rightButtonOffset: CGFloat = 45
    static let animationDuration: TimeInterval = 0.3
}

protocol AddAddressTextFieldDelegate: AnyObject {
    func addAddressTextField(_ textField: AddAddressTextField, didChange text: String)
    func addressTextFieldTappedNext()
}

final class AddAddressTextField: UIView, NibOwnerLoadable {
    @IBOutlet private weak var addressTextField: InputTextField!
    @IBOutlet private var buttonDelete: UIButton!
    @IBOutlet private var buttonScan: UIButton!

    private var isShowDeleteButton = false

    weak var delegate: AddAddressTextFieldDelegate?

    var text: String {
        set {
            addressTextField.value = newValue
            setupButtonsState(animation: false)
        }
        get {
            return addressTextField.value ?? ""
        }
    }

    var error: String? {
        set {
            addressTextField.error = newValue
        }
        get {
            return addressTextField.error
        }
    }

    var isEnabled: Bool = true {
        didSet {
            addressTextField.isEnabled = isEnabled
            buttonDelete.isHidden = !isEnabled
            buttonScan.isHidden = !isEnabled
        }
    }

    var trimmingText: String {
        return text.trimmingCharacters(in: CharacterSet.whitespaces)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadNibContent()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        addressTextField.returnKey = .next

        addressTextField.update(with: .init(title: Localizable.Waves.Addaddressbook.Label.address,
                                            kind: .text,
                                            placeholder: Localizable.Waves.Addaddressbook.Label.address))

        addressTextField.textFieldShouldReturn = { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.addressTextFieldTappedNext()
        }

        addressTextField.changedValue = { [weak self] _, value in
            guard let self = self else { return }
            self.delegate?.addAddressTextField(self, didChange: value ?? "")
            self.setupButtonsState(animation: true)
        }

        addressTextField.rightView = buttonScan
        buttonDelete.alpha = 0
        setupButtonsState(animation: false)
    }

    @discardableResult override func becomeFirstResponder() -> Bool {
        return addressTextField.becomeFirstResponder()
    }

    private lazy var readerVC: QRCodeReaderViewController = QRCodeReaderFactory.deffaultCodeReader
}

// MARK: - Actions

private extension AddAddressTextField {
    @IBAction func deleteTapped(_: Any) {
        addressTextField.value = nil
        setupButtonsState(animation: true)
        delegate?.addAddressTextField(self, didChange: text)
    }

    @IBAction func scanTapped(_: Any) {
        CameraAccess.requestAccess(success: { [weak self] in
            guard let self = self else { return }
            self.showScanner()
        }, failure: { [weak self] in
            guard let self = self else { return }
            let alert = CameraAccess.alertController
            self.firstAvailableViewController().present(alert, animated: true, completion: nil)
        })
    }
}

private extension AddAddressTextField {
    func setupButtonsState(animation: Bool) {
        if !text.isEmpty {
            if !isShowDeleteButton {
                isShowDeleteButton = true

                UIView.animate(withDuration: animation ? Constansts.animationDuration : 0) {
                    self.buttonDelete.alpha = 1
                    self.buttonScan.alpha = 0
                    self.addressTextField.rightView = self.buttonDelete
                }
            }
        } else {
            if isShowDeleteButton {
                isShowDeleteButton = false
                UIView.animate(withDuration: animation ? Constansts.animationDuration : 0) {
                    self.buttonDelete.alpha = 0
                    self.buttonScan.alpha = 1
                    self.addressTextField.rightView = self.buttonScan
                }
            }
        }
    }
}

// MARK: - QRCodeReaderViewController

private extension AddAddressTextField {
    func showScanner() {
        guard QRCodeReader.isAvailable() else { return }
        readerVC.completionBlock = { (result: QRCodeReaderResult?) in

            if let value = result?.value {
                let address = QRCodeParser.parseAddress(value)
                self.addressTextField.value = address

                self.setupButtonsState(animation: true)
                self.delegate?.addAddressTextField(self, didChange: self.text)
            }

            self.firstAvailableViewController().dismiss(animated: true, completion: nil)
        }

        firstAvailableViewController().present(readerVC, animated: true)
    }
}
