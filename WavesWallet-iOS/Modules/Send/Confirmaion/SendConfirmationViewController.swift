//
//  SendConfirmationViewController.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 10/18/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import UIKit
import RxSwift
import DomainLayer
import Extensions

private enum Constants {
    static let cornerRadius: CGFloat = 2
    static let animationDuration: TimeInterval = 0.3
}

final class SendConfirmationViewController: UIViewController {

    struct Input {
        let asset: Asset
        let address: String
        let displayAddress: String
        let fee: Money
        let feeAssetID: String
        let feeName: String
        let amount: Money
        let amountWithoutFee: Money
        var attachment: String
        let isGateway: Bool
        let gateWayFeeAmount: Money?
        let gateWayFeeName: String?
    }
    
    @IBOutlet private weak var viewContainer: UIView!
    @IBOutlet private weak var labelBalance: UILabel!
    @IBOutlet private weak var viewRecipient: SendConfirmationRecipientView!
    @IBOutlet private weak var labelFee: UILabel!
    @IBOutlet private weak var labelFeeAmount: UILabel!
    @IBOutlet private weak var labelDescription: UILabel!
    @IBOutlet private weak var labelDescriptionError: UILabel!
    @IBOutlet private weak var textField: UITextField!
    @IBOutlet private weak var buttonConfirm: HighlightedButton!
    @IBOutlet private weak var tickerView: TickerView!
    @IBOutlet private weak var labelAssetName: UILabel!
    @IBOutlet private weak var viewDescription: UIView!
    @IBOutlet private weak var labelGatewayFee: UILabel!
    @IBOutlet private weak var labelGatewayFeeAmount: UILabel!
    @IBOutlet private weak var viewGatewayFee: UIView!
    
    private var isShowError = false
    
    var interactor: SendInteractorProtocol!
    var input: Input!
    weak var resultDelegate: SendResultDelegate?

    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        createBackWhiteButton()
        setupLocalization()
        setupData()
        labelDescriptionError.alpha = 0
        viewDescription.isHidden = input.isGateway
        viewGatewayFee.isHidden = !input.isGateway
        setupButtonState()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        viewContainer.createTopCorners(radius: Constants.cornerRadius)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        removeTopBarLine()
        setupBigNavigationBar()
        navigationItem.backgroundImage = UIImage()
        navigationItem.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.white]
        navigationItem.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.white]
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @IBAction private func confirmTapped(_ sender: Any) {
        
        let vc = StoryboardScene.Send.sendLoadingViewController.instantiate()
        vc.interactor = interactor
        vc.delegate = resultDelegate
        vc.input = input
        navigationController?.pushViewController(vc, animated: true)
        
        UseCasesFactory.instance.analyticManager.trackEvent(.send(.sendConfirm(assetName: input.asset.displayName)))

    }
    
    @IBAction private func descriptionDidChange(_ sender: Any) {
        
        input.attachment = descriptionText
        showError(!isValidAttachment)
        setupButtonState()
    }
    
    private var isValidAttachment: Bool {
        return descriptionText.utf8.count <= Send.ViewModel.maximumDescriptionLength
    }
    
    private func setupButtonState() {
        buttonConfirm.isUserInteractionEnabled = isValidAttachment
        buttonConfirm.backgroundColor = isValidAttachment ? .submit400 : .submit200
    }
    
    private var descriptionText: String {
        return textField.text?.trimmingCharacters(in: CharacterSet.whitespaces) ?? ""
    }
}

// MARK: - UITextFieldDelegate

extension SendConfirmationViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        confirmTapped(buttonConfirm as Any)
        return true
    }
}

// MARK: - UI
private extension SendConfirmationViewController {
    
    func showError(_ isShow: Bool) {
        
        if isShow {
            if !isShowError {
                isShowError = true
                UIView.animate(withDuration: Constants.animationDuration) {
                    self.labelDescriptionError.alpha = 1
                }
            }
           
        }
        else {
            if isShowError {
               isShowError = false
                UIView.animate(withDuration: Constants.animationDuration) {
                    self.labelDescriptionError.alpha = 0
                }
            }
        }
    }
    
    func setupLocalization() {
        title = Localizable.Waves.Sendconfirmation.Label.confirmation
        labelFee.text = Localizable.Waves.Sendconfirmation.Label.fee
        labelDescription.text = Localizable.Waves.Sendconfirmation.Label.description
        labelDescriptionError.text = Localizable.Waves.Sendconfirmation.Label.descriptionIsTooLong
        textField.placeholder = Localizable.Waves.Sendconfirmation.Label.optionalMessage
        buttonConfirm.setTitle(Localizable.Waves.Sendconfirmation.Button.confim, for: .normal)
        labelGatewayFee.text = Localizable.Waves.Sendconfirmation.Label.gatewayFee
    }
    
    func setupData() {
        
        let addressBook: AddressBookInteractorProtocol = AddressBookInteractor()
        addressBook
            .users()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] contacts in

            guard let self = self else { return }
            
            if let contact = contacts.first(where: {$0.address == self.input.displayAddress}) {
                self.viewRecipient.update(with: .init(name: contact.name, address: self.input.displayAddress))

            }
            else {
                self.viewRecipient.update(with: .init(name: nil, address: self.input.displayAddress))
            }

        }).disposed(by: disposeBag)
        
        if let ticker = input.asset.ticker {
            labelAssetName.isHidden = true
            tickerView.update(with: .init(text: ticker, style: .soft))
        }
        else {
            tickerView.isHidden = true
            labelAssetName.text = input.asset.displayName
        }
        labelFeeAmount.text = input.fee.displayText + " " + input.feeName
        labelBalance.attributedText = NSAttributedString.styleForBalance(text: input.amountWithoutFee.displayText, font: labelBalance.font)
        
        let gateWayFeeAmount = input.gateWayFeeAmount?.displayText ?? ""
        let gateWayFeeName = input.gateWayFeeName ?? ""
        
        labelGatewayFeeAmount.text = gateWayFeeAmount + " " + gateWayFeeName
    }
}
