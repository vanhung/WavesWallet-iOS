//
//  ReceiveCardViewController.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 10/2/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxFeedback
import WavesSDKExtensions
import WavesSDK
import DomainLayer
import Extensions

final class ReceiveCardViewController: UIViewController {

    @IBOutlet private weak var assetView: AssetSelectView!
    @IBOutlet private weak var textFieldMoney: MoneyTextField!
    @IBOutlet private weak var labelAmountIn: UILabel!
    @IBOutlet private weak var labelChangeCurrency: UILabel!
    @IBOutlet private weak var viewContainer: UIView!
    @IBOutlet private weak var viewWarning: UIView!
    @IBOutlet private weak var acitivityIndicatorAmount: UIActivityIndicatorView!
    @IBOutlet private weak var acitivityIndicatorWarning: UIActivityIndicatorView!
    @IBOutlet private weak var labelWarningMinimumAmount: UILabel!
    @IBOutlet private weak var labelWarningInfo: UILabel!
    @IBOutlet private weak var buttonContinue: HighlightedButton!
    @IBOutlet private weak var activityIndicatorWavesAmount: UIActivityIndicatorView!
    @IBOutlet private weak var labelAmountWaves: UILabel!
    
    private let sendEvent: PublishRelay<ReceiveCard.Event> = PublishRelay<ReceiveCard.Event>()
    var presenter: ReceiveCardPresenterProtocol!
    
    private var selectedFiat = ReceiveCard.DTO.FiatType.usd
    private var amountUSDInfo: ReceiveCard.DTO.AmountInfo?
    private var amountEURInfo: ReceiveCard.DTO.AmountInfo?
    private var asset: DomainLayer.DTO.SmartAssetBalance?
    private var amount: Money = Money(0, WavesSDKConstants.FiatDecimals)
    private var urlLink = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewContainer.addTableCellShadowStyle()
        setupLocalization()
        setupFeedBack()
        setupButtonState()
        setupFiatText()
        assetView.isSelectedAssetMode = false
        assetView.setupReveiceWavesLoadingState()
        viewWarning.isHidden = true
        textFieldMoney.moneyDelegate = self
        textFieldMoney.setDecimals(amount.decimals, forceUpdateMoney: false)
        hideLoadingmountWaves(amount: nil)
    }

    @IBAction private func continueTapped(_ sender: Any) {
    
        guard let url = URL(string: urlLink) else { return }
        UIApplication.shared.openURLAsync(url)
        let vc = StoryboardScene.Receive.receiveCardCompleteViewController.instantiate()
        navigationController?.pushViewController(vc, animated: false)
        
        UseCasesFactory.instance.analyticManager.trackEvent(.receive(.cardReceiveTap))
    }
    
    @IBAction private func changeCurrency(_ sender: Any) {
    
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        controller.addAction(.init(title: Localizable.Waves.Receivecard.Button.cancel, style: .cancel, handler: nil))
        
        let actionUSD = UIAlertAction(title: ReceiveCard.DTO.FiatType.usd.text, style: .default) { (action) in
           
            if self.selectedFiat == .usd {
                return
            }
           
            self.selectedFiat = .usd
            self.setupFiatText()
            self.setupButtonState()
            if let amountInfo = self.amountUSDInfo {
                self.sendEvent.accept(.updateAmountWithUSDFiat)
                self.setupAmountInfo(amountInfo)
            }
            else {
                self.sendEvent.accept(.getUSDAmountInfo)
                self.setupLoadingAmountInfo()
            }
            self.showLoadingAmountWaves()
        }
        controller.addAction(actionUSD)
        
        let actionEUR = UIAlertAction(title: ReceiveCard.DTO.FiatType.eur.text, style: .default) { (action) in
           
            if self.selectedFiat == .eur {
                return
            }
            
            self.selectedFiat = .eur
            self.setupFiatText()
            self.setupButtonState()
            if let amountInfo = self.amountEURInfo {
                self.sendEvent.accept(.updateAmountWithEURFiat)
                self.setupAmountInfo(amountInfo)
            }
            else {
                self.sendEvent.accept(.getEURAmountInfo)
                self.setupLoadingAmountInfo()
            }
            self.showLoadingAmountWaves()
        }
        controller.addAction(actionEUR)
        present(controller, animated: true, completion: nil)
    }
}


// MARK: - FeedBack
private extension ReceiveCardViewController {
    
    func setupFeedBack() {
        
        let feedback = bind(self) { owner, state -> Bindings<ReceiveCard.Event> in
            return Bindings(subscriptions: owner.subscriptions(state: state), events: owner.events())
        }
        
        presenter.system(feedbacks: [feedback])
    }
    
    func events() -> [Signal<ReceiveCard.Event>] {
        return [sendEvent.asSignal()]
    }
    
    func subscriptions(state: Driver<ReceiveCard.State>) -> [Disposable] {
        let subscriptionSections = state
            .drive(onNext: { [weak self] state in
                
                guard let self = self else { return }
                switch state.action {
                case .none:
                    return
                default:
                    break
                }
                
                self.amountUSDInfo = state.amountUSDInfo
                self.amountEURInfo = state.amountEURInfo
                self.asset = state.assetBalance
                self.urlLink = state.link
                
                switch state.action {
                    
                case .didGetInfo:
                    self.setupInfo()

                case .didFailGetInfo(let error):
                    self.showError(error)

                case .didGetWavesAmount(let amount):
                    self.hideLoadingmountWaves(amount: amount)
                
                case .didFailGetWavesAmount:
                    self.hideLoadingmountWaves(amount: nil)
                    
                default:
                    break
                }
            })
        
        return [subscriptionSections]
    }
}

// MARK: - MoneyTextFieldDelegate
extension ReceiveCardViewController: MoneyTextFieldDelegate {
    func moneyTextField(_ textField: MoneyTextField, didChangeValue value: Money) {
        
        if amount != value {
            showLoadingAmountWaves()
        }
        
        amount = value
        setupButtonState()
        sendEvent.accept(.updateAmount(value))
    }
}

// MARK: - UI
private extension ReceiveCardViewController {
    
    func hideLoadingmountWaves(amount: Money?) {
        activityIndicatorWavesAmount.stopAnimating()

        let amount = amount?.displayText ?? "0"
        labelAmountWaves.text = "≈ \(amount) WAVES"
    }
    
    func showLoadingAmountWaves() {
        activityIndicatorWavesAmount.isHidden = false
        activityIndicatorWavesAmount.startAnimating()
        labelAmountWaves.text = nil
    }
    
    func setupLoadingAmountInfo() {
        acitivityIndicatorWarning.isHidden = false
        acitivityIndicatorWarning.startAnimating()
        viewWarning.isHidden = true
    }
    
    func setupFiatText() {
        labelAmountIn.text = Localizable.Waves.Receive.Label.amountIn + " " + selectedFiat.text
    }
    
    func setupAmountInfo(_ amountInfo: ReceiveCard.DTO.AmountInfo) {
        
        let minimum = amountInfo.minAmount.displayTextWithoutSpaces + " " + selectedFiat.text
        let maximum = amountInfo.maxAmount.displayTextWithoutSpaces + " " + selectedFiat.text
        
        labelWarningMinimumAmount.text = Localizable.Waves.Receivecard.Label.minimunAmountInfo(minimum, maximum)
        viewWarning.isHidden = false
    }
    
    
    func setupInfo() {
        
        guard let asset = asset else { return }

        acitivityIndicatorAmount.stopAnimating()
        acitivityIndicatorWarning.stopAnimating()
        assetView.update(with: .init(assetBalance: asset, isOnlyBlockMode: true))
        setupButtonState()
        
        if selectedFiat == .usd {
            guard let amountInfo = amountUSDInfo else { return }
            setupAmountInfo(amountInfo)
        }
        else if selectedFiat == .eur {
            guard let amountInfo = amountEURInfo else { return }
            setupAmountInfo(amountInfo)
        }
    }
    
    func showError(_ error: NetworkError) {
        acitivityIndicatorAmount.stopAnimating()
        acitivityIndicatorWarning.stopAnimating()
        
        showNetworkErrorSnack(error: error,
                              customTitle: Localizable.Waves.Receive.Error.serviceUnavailable)
    }
    
    func setupButtonState() {
        
        var canContinueAction = false
        if selectedFiat == .usd {
            if let info = amountUSDInfo {
                if amount.decimalValue >= info.minAmount.decimalValue &&
                    amount.decimalValue <= info.maxAmount.decimalValue {
                    canContinueAction = true
                }
            }
        }
        else if selectedFiat == .eur {
            if let info = amountEURInfo {
                if amount.decimalValue >= info.minAmount.decimalValue &&
                    amount.decimalValue <= info.maxAmount.decimalValue {
                    canContinueAction = true
                }
            }
        }
        buttonContinue.isUserInteractionEnabled = canContinueAction
        buttonContinue.backgroundColor = canContinueAction ? .submit400 : .submit200
    }
    
    func setupLocalization() {
        labelChangeCurrency.text = Localizable.Waves.Receivecard.Label.changeCurrency
        labelWarningInfo.text = Localizable.Waves.Receivecard.Label.warningInfo
        buttonContinue.setTitle(Localizable.Waves.Receive.Button.continue, for: .normal)
    }
}
