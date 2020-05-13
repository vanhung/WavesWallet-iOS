//
//  SendViewController.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 10/15/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import UIKit
import RxSwift
import RxFeedback
import RxCocoa
import WavesSDKExtensions
import WavesSDK
import Extensions
import DomainLayer
import TTTAttributedLabel

protocol SendResultDelegate: AnyObject {
    func sendResultDidFail(_ error: NetworkError)
    func sendResultDidTapFinish()
}

private enum Constants {
    static let animationDuration: TimeInterval = 0.3
    
    static let percent50 = 50
    static let percent10 = 10
    static let percent5 = 5
    
    static let oldMoneroRegAddress = "^([a-km-zA-HJ-NP-Z1-9]{95})$"
    static let newMoneroRegAddress = "^([a-km-zA-HJ-NP-Z1-9]{106})$"
    static let moneroNewsLink = "https://coinswitch.co/news/monero-hard-fork-2019-coming-up-on-november-30th-everything-you-need-to-know"
}

// TODO: Refactor all module
final class SendViewController: UIViewController {

    @IBOutlet private weak var assetView: AssetSelectView!
    @IBOutlet private weak var viewWarning: UIView!
    @IBOutlet private weak var labelWarningTitle: UILabel!
    @IBOutlet private weak var labelWarningSubtitle: UILabel!
    @IBOutlet private weak var amountView: AmountInputView!
    @IBOutlet private weak var recipientAddressView: AddressInputView!
    @IBOutlet private weak var buttonContinue: HighlightedButton!
    @IBOutlet private weak var viewFee: TransactionFeeView!
    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet private weak var activityIndicatorButton: UIActivityIndicatorView!
    @IBOutlet private weak var viewAmountError: UIView!
    @IBOutlet private weak var labelAmountError: UILabel!
    @IBOutlet private weak var coinomatErrorView: UIView!
    @IBOutlet private weak var viewBottomContent: UIView!
    @IBOutlet private weak var viewBottomContentHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var moneroAddressErrorView: UIView!
    @IBOutlet private weak var labelMoneroAddressError: TTTAttributedLabel!
    
    private let popoverViewControllerTransitioning = ModalViewControllerTransitioning {

    }
    
    private var selectedAsset: DomainLayer.DTO.SmartAssetBalance?
    private var amount: Money?
    private var wavesFee: Money?
    private var feeAssetID = WavesSDKConstants.wavesAssetId
    private var feeAssetBalance: DomainLayer.DTO.SmartAssetBalance?
    private var currentFee: Money?
    
    private let sendEvent: PublishRelay<Send.Event> = PublishRelay<Send.Event>()
    var presenter: SendPresenterProtocol!
    
    var inputModel: Send.DTO.InputModel!
    
    private var isValidAlias: Bool = false
    private var hasNeedReloadGateWayInfo: Bool = false
    private var gateWayInfo: Send.DTO.GatewayInfo?
    private var isLoadingAssetBalanceAfterScan = false
    private var errorSnackKey: String?
   
    var backTappedAction:(() -> Void)?
    
    var availableBalance: Money {
        
        guard let asset = selectedAsset else { return Money(0, 0)}
        
        var balance: Int64 = 0
        if isValidCryptocyrrencyAddress {
            balance = asset.availableBalance - (gateWayInfo?.fee.amount ?? 0)
        }
        else {
            if feeAssetID == asset.assetId {
                if asset.asset.isWaves {
                    balance = asset.availableBalance - (currentFee?.amount ?? WavesSDKConstants.WavesTransactionFeeAmount)
                }
                else {
                    balance = asset.availableBalance - (currentFee?.amount ?? 0)
                }
            }
            else {
                balance = asset.availableBalance
            }
        }
        return Money(balance, asset.asset.precision)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = Localizable.Waves.Send.Label.send
        createBackButton()
        setupRecipientAddress()
        setupLocalization()
        setupFeedBack()
        viewFee.isSelectedAssetFee = true
        viewFee.delegate = self
        hideGatewayInfo(animation: false)
        hideCoinomatError(animation: false)
        updateAmountError(animation: false)
        amountView.input = { [weak self] in
            return self?.inputAmountValues ?? []
        }
        assetView.delegate = self
        amountView.delegate = self
        amountView.setupRightLabelText("")
        labelMoneroAddressError.delegate = self
        moneroAddressErrorView.isHidden = true
        
        switch inputModel! {
        case .selectedAsset(let asset):
            assetView.isSelectedAssetMode = false
            
            //TODO: need refactor code to correct initial state
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                self.setupAssetInfo(asset)
                self.amountView.setDecimals(asset.asset.precision, forceUpdateMoney: false)
            }
            
        case .resendTransaction(let tx):
            updateAmountData()
            viewFee.showLoadingState()
            recipientAddressView.setupText(tx.address, animation: false)
            amount = tx.amount
            amountView.setAmount(tx.amount)
            assetView.showLoadingState()
            
            //TODO: need refactor code to correct initial state
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                self.sendEvent.accept(.getAssetById(tx.asset.id))
                self.acceptAddress(tx.address)
                if !self.isValidAddress(self.recipientAddressView.text) {
                    self.validateAddress()
                }
            }

        case .empty:
            viewFee.isHidden = true
            updateAmountData()
            
        case .deepLink(let link):
            //TODO: need refactor code to correct initial state

            DispatchQueue.main.asyncAfter(deadline: .now()) {
                
                let address = link.recipient
                self.recipientAddressView.setupText(address, animation: false)
                self.acceptAddress(address)
                if !self.isValidAddress(address) {
                    self.validateAddress()
                }
                
                if let assetId = link.assetId, link.amount > 0 {
                    self.showLoadingAssetState(isLoadingAmount: true)
                    self.sendEvent.accept(.getDecimalsForDeepLinkAsset(assetId))
                }
                else {
                    self.addressInputViewDidScanAddress(address, amount: nil, assetID: link.assetId)
                }
            }
        }
        
        setupButtonState()
    }

    override func backTapped() {
        if let dismiss = backTappedAction {
            dismiss()
        }
        else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupBigNavigationBar()
    }
    
    private func setupAssetInfo(_ assetBalance: DomainLayer.DTO.SmartAssetBalance) {

        gateWayInfo = nil
        wavesFee = nil
        currentFee = nil
        viewFee.showLoadingState()
        selectedAsset = assetBalance
        assetView.update(with: .init(assetBalance: assetBalance, isOnlyBlockMode: inputModel.selectedAsset != nil))
        setupButtonState()

        let loadGateway = self.isValidCryptocyrrencyAddress && !self.isValidLocalAddress
        sendEvent.accept(.didSelectAsset(assetBalance, loadGatewayInfo: loadGateway))
        if loadGateway {
            showLoadingGatewayInfo()
        }
        else {
            hideCoinomatError(animation: false)
            hideGatewayInfo(animation: false)
        }
        
        updateAmountData()
        updateMoneraAddressErrorView(animation: false)
        recipientAddressView.decimals = selectedAsset?.asset.precision ?? 0
    }
    
    private func showConfirmScreen() {
        guard let amountWithoutFee = self.amount else { return }
        guard let asset = selectedAsset?.asset else { return }
        guard let fee = currentFee else { return }
        
        let feeName = feeAssetID == WavesSDKConstants.wavesAssetId ? "WAVES" : (feeAssetBalance?.asset.displayName ?? "")
        var address = recipientAddressView.text
        var amount = amountWithoutFee
        var isGateway = false
        var attachment = ""
        
        if let gateWay = gateWayInfo, isValidCryptocyrrencyAddress {
            address = gateWay.address
            isGateway = true
            attachment = gateWay.attachment
            
            //Coinomate take fee from transaction
            //in 'availableBalance' I substract fee from coinomate that user can input valid amount with fee.
            amount = Money(amount.amount + gateWay.fee.amount, amount.decimals)
        }
        
        
        let vc = StoryboardScene.Send.sendConfirmationViewController.instantiate()
        vc.interactor = presenter.interactor
        vc.resultDelegate = self
        vc.input = .init(asset: asset,
                         address: address,
                         displayAddress: recipientAddressView.text,
                         fee: fee,
                         feeAssetID: feeAssetID,
                         feeName: feeName,
                         amount: amount,
                         amountWithoutFee: amountWithoutFee,
                         attachment: attachment,
                         isGateway: isGateway,
                         gateWayFeeAmount: gateWayInfo?.fee,
                         gateWayFeeName: gateWayInfo?.assetName)
        
        navigationController?.pushViewController(vc, animated: true)
        
        UseCasesFactory.instance.analyticManager.trackEvent(.send(.sendTap(assetName: asset.displayName)))
    }
    
    @IBAction private func continueTapped(_ sender: Any) {
        showConfirmScreen()
    }
}

// MARK: - TransactionFeeViewDelegate
extension SendViewController: TransactionFeeViewDelegate {
    func transactionFeeViewDidTap() {
        
        guard let assetID = selectedAsset?.assetId else { return }
        guard let wavesFee = wavesFee else { return }
        
        let vc = SendFeeModuleBuilder(output: self).build(input: .init(wavesFee: wavesFee,
                                                                       assetID: assetID,

                                                                       feeAssetID: feeAssetID))
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = popoverViewControllerTransitioning
        self.present(vc, animated: true, completion: nil)
    }
}

// MARK: - SendFeeModuleOutput
extension SendViewController: SendFeeModuleOutput {
    
    func sendFeeModuleDidSelectAssetFee(_ asset: DomainLayer.DTO.SmartAssetBalance, fee: Money) {

        self.dismiss(animated: true, completion: nil)
        feeAssetID = asset.assetId
        feeAssetBalance = asset
        currentFee = fee
        updateActualFee()
        setupButtonState()
        updateAmountError(animation: true)
        updateAmountData()
    }
}

// MARK: - SendResultDelegate
extension SendViewController: SendResultDelegate {
    func sendResultDidTapFinish() {
        if let action = backTappedAction {
            action()
        }
    }
    
    func sendResultDidFail(_ error: NetworkError) {
        
        navigationController?.popToViewController(self, animated: true)
        
        switch error {
        case .scriptError:
        _ = TransactionScriptErrorView.show()

        default:
            showNetworkErrorSnack(error: error)
        }
    }
}

// MARK: - FeedBack
private extension SendViewController {
    
    func setupFeedBack() {
        
        let feedback = bind(self) { owner, state -> Bindings<Send.Event> in
            return Bindings(subscriptions: owner.subscriptions(state: state), events: owner.events())
        }
        
        presenter.system(feedbacks: [feedback])        
    }
    
    func events() -> [Signal<Send.Event>] {
        return [sendEvent.asSignal()]
    }
    
    func subscriptions(state: Driver<Send.State>) -> [Disposable] {
        let subscriptionSections = state
            .drive(onNext: { [weak self] state in
                
                guard let self = self else { return }
                switch state.action {
                case .none:
                    return
                default:
                    break
                }
                
                switch state.action {
                
                case .didGetWavesFee(let fee):
                    self.updateWavesFee(fee: fee)
                    self.updateAmountData()

                case .didHandleFeeError(let error):
                    self.showFeeError(error)
                    
                case .didGetAssetBalance(let assetBalance):
                    
                    if self.isLoadingAssetBalanceAfterScan && assetBalance == nil {
                        self.showErrorSnackWithoutAction(title: Localizable.Waves.Send.Label.Error.assetIsNotValid)
                    }
                    else if assetBalance?.asset.isSpam == true {
                        self.showErrorSnackWithoutAction(title: Localizable.Waves.Send.Label.Error.sendingToSpamAsset)
                    }
                    
                    self.hideLoadingAssetState(isLoadAsset: assetBalance != nil)
                    
                    if let asset = assetBalance {
                        self.setupAssetInfo(asset)
                        self.amountView.setDecimals(asset.asset.precision, forceUpdateMoney: true)
                        if !self.isValidAddress(self.recipientAddressView.text) {
                            self.validateAddress()
                        }
                    }
                    
                    self.updateAmountData()

                    
                case .didFailInfo(let error):
                    
                    switch error {
                    case .internetNotWorking:
                        self.hideCoinomatError(animation: true)
                        self.showNetworkErrorSnack(error: error)

                    default:
                        self.showCoinomatError()
                    }
                    self.hideGatewayInfo(animation: true)
                    
                case .didGetInfo(let info):
                    self.showGatewayInfo(info: info)
                    self.updateAmountData()
                    
                case .aliasDidFinishCheckValidation(let isValidAlias):
                    self.hideCheckingAliasState(isValidAlias: isValidAlias)
                    self.setupButtonState()

                case .didGetWavesAsset(let asset):
                    self.feeAssetBalance = asset
                    self.updateAmountError(animation: true)
                    self.updateAmountData()
                    
                case .didGetDeepLinkAssetDecimals(let decimals):
                    
                    if case .deepLink(let link) = self.inputModel {
                        let amount = Money(value: Decimal(link.amount), decimals)
                        self.addressInputViewDidScanAddress(link.recipient, amount: amount, assetID: link.assetId)
                    }
                default:
                    break
                }
                
            })
        
        return [subscriptionSections]
    }
}

// MARK: - MoneyTextFieldDelegate
extension SendViewController: AmountInputViewDelegate {
    
    func amountInputView(didChangeValue value: Money) {
        amount = value
        
        self.gateWayInfo = nil
        hasNeedReloadGateWayInfo = true
        validateAddress()
        
        updateAmountError(animation: true)
        setupButtonState()
    }
}

// MARK: - AssetListModuleOutput
extension SendViewController: AssetListModuleOutput {
    func assetListDidSelectAsset(_ asset: DomainLayer.DTO.SmartAssetBalance) {
        
        setupAssetInfo(asset)
        amountView.setDecimals(asset.asset.precision, forceUpdateMoney: true)
        validateAddress()
    }
}

// MARK: - AssetSelectViewDelegate
extension SendViewController: AssetSelectViewDelegate {
   
    func assetViewDidTapChangeAsset() {
        let assetInput = AssetList.DTO.Input(filters: [.all],
                                             selectedAsset: selectedAsset,
                                             showAllList: false)
        
        let vc = AssetListModuleBuilder(output: self).build(input: assetInput)
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - Data
private extension SendViewController {
    var inputAmountValues: [Money] {
        
        var values: [Money] = []
        if availableBalance.amount > 0 {
            
            values.append(availableBalance)
            
            let n5 = Decimal(availableBalance.amount) * (Decimal(Constants.percent5) / 100.0)
            let n10 = Decimal(availableBalance.amount) * (Decimal(Constants.percent10) / 100.0)
            let n50 = Decimal(availableBalance.amount) * (Decimal(Constants.percent50) / 100.0)
            
            values.append(Money(n50.int64Value, availableBalance.decimals))
            values.append(Money(n10.int64Value, availableBalance.decimals))
            values.append(Money(n5.int64Value, availableBalance.decimals))
        }
        
        return values
    }
    
    func updateAmountData() {
        
        var fields: [String] = []
        
        if availableBalance.amount > 0 {
            fields.append(contentsOf: [Localizable.Waves.Send.Button.useTotalBalanace,
                                       String(Constants.percent50) + "%",
                                       String(Constants.percent10) + "%",
                                       String(Constants.percent5) + "%"])
        }
        
        amountView.update(with: fields)
    }
}

// MARK: - UI
private extension SendViewController {

    
    func showFeeError(_ error: DisplayError) {
        
        switch error {
        case .globalError(let isInternetNotWorking):
            
            if isInternetNotWorking {
                errorSnackKey = showWithoutInternetSnack { [weak self] in
                    self?.sendEvent.accept(.refreshFee)
                }
            } else {
                errorSnackKey = showErrorNotFoundSnack(didTap: { [weak self] in
                    self?.sendEvent.accept(.refreshFee)
                })
            }
        case .internetNotWorking:
            errorSnackKey = showWithoutInternetSnack { [weak self] in
                self?.sendEvent.accept(.refreshFee)
            }
            
        case .message(let text):
            errorSnackKey = showErrorSnack(title: text, didTap: { [weak self] in
                self?.sendEvent.accept(.refreshFee)
            })
            
        case .none, .scriptError:
            errorSnackKey = showErrorNotFoundSnack(didTap: { [weak self] in
                self?.sendEvent.accept(.refreshFee)
            })
        }
    }
    
    func updateWavesFee(fee: Money) {
        
        if let errorSnackKey = errorSnackKey {
            hideSnack(key: errorSnackKey)
        }

        wavesFee = fee
        if feeAssetID != WavesSDKConstants.wavesAssetId, let asset = feeAssetBalance?.asset {
            currentFee = SendFee.DTO.calculateSponsoredFee(by: asset, wavesFee: fee)
        }
        else {
            currentFee = fee
        }
        viewFee.isHidden = false
        viewFee.hideLoadingState()
        updateActualFee()
        setupButtonState()
    }
    
    func updateActualFee() {
        if feeAssetID == WavesSDKConstants.wavesAssetId {
            let fee = currentFee ?? UIGlobalConstants.WavesTransactionFee
            viewFee.update(with: .init(fee: fee, assetName: nil))
        }
        else {
            guard let name = feeAssetBalance?.asset.displayName,
                let fee = currentFee else { return }
            
            viewFee.update(with: .init(fee: fee, assetName: name))
        }
    }
    
    func showLoadingAssetState(isLoadingAmount: Bool) {
        isLoadingAssetBalanceAfterScan = true
        assetView.isSelectedAssetMode = false
        recipientAddressView.isBlockAddressMode = true        
        setupButtonState()
        assetView.showLoadingState()
        amountView.isBlockMode = isLoadingAmount
        if isLoadingAmount {
            amountView.showAnimation()
        }
    }
    
    func hideLoadingAssetState(isLoadAsset: Bool) {
     
        assetView.hideLoadingState(isLoadAsset: isLoadAsset)
        isLoadingAssetBalanceAfterScan = false
        setupButtonState()
    }
    
    func showFeeError(_ error: String, animation: Bool) {
        if viewAmountError.isHidden {
            viewAmountError.isHidden = false
            viewAmountError.alpha = animation ? 0 : 1
            
            if animation {
                UIView.animate(withDuration: Constants.animationDuration) {
                    self.viewAmountError.alpha = 1
                }
            }
        }
        
        labelAmountError.text = error
    }
    
    func updateAmountError(animation: Bool) {
        
        let amountInput = amount?.amount ?? 0
        
        let isShowAmountError = selectedAsset != nil && !isValidAmount && amountInput > 0
        
        if let gateWayInfo = gateWayInfo, isValidCryptocyrrencyAddress, isShowAmountError {
            var feeText: String = ""
            let currentFeeText = currentFee?.displayText ?? ""
            
            if feeAssetID == WavesSDKConstants.wavesAssetId {
                feeText = currentFeeText + " " + "WAVES"
            }
            else {
                feeText = currentFeeText + " " + (feeAssetBalance?.asset.displayName ?? "")
            }
            
            let gateWayFee = gateWayInfo.fee.displayText + " " + gateWayInfo.assetShortName
            let error = Localizable.Waves.Send.Label.Error.notFundsFeeGateway(feeText, gateWayFee)
            showFeeError(error, animation: animation)
        }
        else if amountInput > 0 && !isValidFee && feeAssetBalance != nil {
            showFeeError(Localizable.Waves.Send.Label.Error.notFundsFee, animation: animation)
        }
        else {
            if !viewAmountError.isHidden {
                if animation {
                    UIView.animate(withDuration: Constants.animationDuration, animations: {
                        self.viewAmountError.alpha = 0
                        
                    }) { (complete) in
                        self.viewAmountError.isHidden = true
                    }
                }
                else {
                    viewAmountError.isHidden = true
                }
               
            }
        }
        
        let gatewayName = gateWayInfo?.assetShortName ?? ""
        if !isCorrectMinCryptocyrrencyAmount {
            let min = gateWayInfo?.minAmount.displayText ?? ""
            amountView.showErrorMessage(message: Localizable.Waves.Send.Label.Error.minimun(min, gatewayName), isShow: true)
        }
        else if !isCorrectMaxCryptocyrrencyAmount {
            let max = gateWayInfo?.maxAmount.displayText ?? ""
            amountView.showErrorMessage(message: Localizable.Waves.Send.Label.Error.maximum(max, gatewayName), isShow: true)
        }
        else {
            amountView.showErrorMessage(message: Localizable.Waves.Send.Label.Error.insufficientFunds, isShow: isShowAmountError)
        }
    }
    
    func showLoadingButtonState() {
        activityIndicatorButton.startAnimating()
    }
    
    func hideButtonLoadingButtonsState() {
        activityIndicatorButton.stopAnimating()
    }
    
    func setupButtonState() {
        
        var isValidateGateway = true
        if isValidCryptocyrrencyAddress && gateWayInfo == nil {
            isValidateGateway = false
        }
        let canContinueAction = isValidateGateway &&
            isValidAddress(recipientAddressView.text) &&
            selectedAsset != nil &&
            isValidAmount &&
            isValidFee &&
            (amount?.amount ?? 0) > 0 &&
            isValidMinMaxGatewayAmount &&
            !isLoadingAssetBalanceAfterScan &&
            currentFee != nil &&
            selectedAsset?.asset.isSpam == false
        
        buttonContinue.isUserInteractionEnabled = canContinueAction
        buttonContinue.backgroundColor = canContinueAction ? .submit400 : .submit200
    }
    
    func showLoadingGatewayInfo(isHidden: Bool = true) {
        hideCoinomatError(animation: false)
        viewWarning.isHidden = isHidden
        activityIndicatorButton.isHidden = false
        activityIndicatorButton.startAnimating()
    }
    
    func showCoinomatError() {

        view.endEditing(true)
        viewBottomContentHeightConstraint.isActive = true

        coinomatErrorView.isHidden = false
        coinomatErrorView.alpha = 0
        activityIndicatorButton.stopAnimating()
        
        UIView.animate(withDuration: Constants.animationDuration, animations: {
            self.coinomatErrorView.alpha = 1
            self.viewBottomContent.alpha = 0
            self.view.layoutIfNeeded()
        }) { (complete) in
            self.viewBottomContent.isHidden = true
        }
    }
    
    func hideCoinomatError(animation: Bool) {
        
        if coinomatErrorView.isHidden {
            return
        }
        
        viewBottomContent.isHidden = false
        viewBottomContentHeightConstraint.isActive = false
        coinomatErrorView.isHidden = true
        if animation {
            UIView.animate(withDuration: Constants.animationDuration) {
                self.viewBottomContent.alpha = 1
            }
        }
        else {
            viewBottomContent.alpha = 1
        }
    }
    
    func hideGatewayInfo(animation: Bool) {
        updateAmountError(animation: animation)
        activityIndicatorButton.stopAnimating()

        if viewWarning.isHidden {
            return
        }
        viewWarning.isHidden = true
        if animation {
            UIView.animate(withDuration: Constants.animationDuration) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    func hideCheckingAliasState(isValidAlias: Bool) {
        self.isValidAlias = isValidAlias
        recipientAddressView.checkIfValidAddress()
        recipientAddressView.hideLoadingState()
    }
    
    func showGatewayInfo(info: Send.DTO.GatewayInfo) {
        
        hideCoinomatError(animation: false)
        gateWayInfo = info
        
        labelWarningTitle.text = Localizable.Waves.Send.Label.gatewayFee + " " + info.fee.displayText + " " + info.assetShortName
        
        let min = info.minAmount.displayText + " " + info.assetShortName
        let max = info.maxAmount.displayText + " " + info.assetShortName

        labelWarningSubtitle.text = Localizable.Waves.Send.Label.Warning.subtitle(info.assetName, min, max)
                
        
        activityIndicatorButton.stopAnimating()
        
        if viewWarning.isHidden == true {
            viewWarning.isHidden = false
            viewWarning.alpha = 0
            UIView.animate(withDuration: Constants.animationDuration, animations: {
                   self.viewWarning.alpha = 1
                   self.view.layoutIfNeeded()
            })
         }
        
   
        setupButtonState()
        updateAmountError(animation: true)
        updateMoneraAddressErrorView(animation: true)
    }
    
    func updateMoneraAddressErrorView(animation: Bool) {
        let address = recipientAddressView.text
        if selectedAsset?.asset.isMonero == true && address.count > 0 {
            if NSPredicate(format: "SELF MATCHES %@", Constants.oldMoneroRegAddress).evaluate(with: address) {
                moneroAddressErrorView.isHidden = false
            }
            else {
                moneroAddressErrorView.isHidden = true
            }
        }
        else {
            moneroAddressErrorView.isHidden = true
        }
    }
    
    func setupLocalization() {
        
        let keyLink = Localizable.Waves.Send.Label.Error.moneroOldAddressKeyLink
        labelMoneroAddressError.text = Localizable.Waves.Send.Label.Error.moneroOldAddress(keyLink)
        
        let range = (labelMoneroAddressError.attributedText.string as NSString).range(of: keyLink)

        labelMoneroAddressError.addLink(to: URL(string: Constants.moneroNewsLink), with: range)
        buttonContinue.setTitle(Localizable.Waves.Send.Button.continue, for: .normal)
    }
    
    func setupRecipientAddress() {
        
        let input = AddressInputView.Input(title: Localizable.Waves.Send.Label.recipient,
                                           error: Localizable.Waves.Send.Label.addressNotValid,
                                           placeHolder: Localizable.Waves.Send.Label.recipientAddress,
                                           contacts: [],
                                           canChangeAsset: self.inputModel.selectedAsset == nil)
        recipientAddressView.update(with: input)
        recipientAddressView.delegate = self
        recipientAddressView.errorValidation = { [weak self] text in
            return self?.isValidAddress(text) ?? false
        }
    }
}

// MARK: - AddressInputViewDelegate

extension SendViewController: AddressInputViewDelegate {
  
    func addressInputViewDidRemoveBlockMode() {
        
        if !assetView.isOnlyBlockMode {
            selectedAsset = nil
            assetView.isSelectedAssetMode = true
            assetView.removeSelectedAssetState()
            recipientAddressView.decimals = 0
            viewFee.isHidden = true
        }
        
        if amountView.isBlockMode {
            amountView.isBlockMode = false
            amountView.clearMoney()
            updateAmountData()
        }
        
        setupButtonState()
        sendEvent.accept(.cancelGetingAsset)
        updateMoneraAddressErrorView(animation: true)
    }
    
    func addressInputViewDidTapNext() {
        
        if coinomatErrorView.isHidden == false {
            view.endEditing(true)
            return
        }

        amountView.activateTextField()
    }
    
    func addressInputViewDidEndEditing() {
        validateAddress()
        if isValidCryptocyrrencyAddress {
            if let info = gateWayInfo, viewWarning.isHidden {
                showGatewayInfo(info: info)
            }
        }
        else {
            hideGatewayInfo(animation: true)
            hideCoinomatError(animation: true)
        }
        updateMoneraAddressErrorView(animation: true)
    }
    
    func addressInputViewDidSelectAddressBook() {
        let controller = AddressBookModuleBuilder(output: self).build(input: .init(isEditMode: false))
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func addressInputViewDidScanAddress(_ address: String, amount: Money?, assetID: String?) {
        
        if assetID != nil {
            recipientAddressView.isBlockAddressMode = true
            assetView.isSelectedAssetMode = false
            amountView.isBlockMode = amount?.isZero == false
        }
        
        if let asset = assetID, selectedAsset?.assetId != asset, inputModel.selectedAsset == nil {
            sendEvent.accept(.getAssetById(asset))
            showLoadingAssetState(isLoadingAmount: amount != nil)
            wavesFee = nil
            currentFee = nil
            viewFee.showLoadingState()
        }
        
        amountView.hideAnimation()
        if let amount = amount {
            if !amount.isZero {
                self.amount = amount
                amountView.setAmount(amount)
            }
            updateAmountData()
            updateAmountError(animation: false)
        }
        
        acceptAddress(address)
        if !recipientAddressView.isKeyboardShow {
            validateAddress()
        }
        clearGatewayAndUpdateInputAmount()
        updateMoneraAddressErrorView(animation: true)
    }
    
    func addressInputViewDidDeleteAddress() {
        acceptAddress("")
        
        hideGatewayInfo(animation: true)
        hideCoinomatError(animation: true)
        clearGatewayAndUpdateInputAmount()
        updateMoneraAddressErrorView(animation: true)
    }
    
    func addressInputViewDidChangeAddress(_ address: String) {
        acceptAddress(address)
        clearGatewayAndUpdateInputAmount()
        hideGatewayInfo(animation: true)
        hideCoinomatError(animation: true)
        updateMoneraAddressErrorView(animation: true)
    }
    
    func addressInputViewDidSelectContactAtIndex(_ index: Int) {
        
    }
    
    private func acceptAddress(_ address: String) {
        isValidAlias = false
        setupButtonState()
        sendEvent.accept(.didChangeRecipient(address))
    }
    
    private func clearGatewayAndUpdateInputAmount() {
        if gateWayInfo != nil {
            gateWayInfo = nil
            updateAmountData()
        }
    }
    
    func addressInputViewDidStartLoadingInfo() {
        showLoadingAssetState(isLoadingAmount: true)
    }
}


// MARK: - AddressBookModuleOutput

extension SendViewController: AddressBookModuleOutput {
   
    func addressBookDidSelectContact(_ contact: DomainLayer.DTO.Contact) {
        recipientAddressView.setupText(contact.address, animation: false)
        acceptAddress(contact.address)
        validateAddress()
        clearGatewayAndUpdateInputAmount()
    }
}

// MARK: - UIScrollViewDelegate
extension SendViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        setupTopBarLine()
    }
}

// MARK: - Validation
private extension SendViewController {

    var isCorrectMinCryptocyrrencyAmount: Bool {
        if let info = gateWayInfo, let amount = amount, amount.decimalValue > 0,
            isValidCryptocyrrencyAddress, selectedAsset != nil {
            return amount.decimalValue >= info.minAmount.decimalValue
        }
        return true
    }
    
    var isCorrectMaxCryptocyrrencyAmount: Bool {
        if let info = gateWayInfo, let amount = amount, amount.decimalValue > 0,
            isValidCryptocyrrencyAddress, selectedAsset != nil {
            return amount.decimalValue <= info.maxAmount.decimalValue
        }
        return true
    }
    
    var isValidMinMaxGatewayAmount: Bool {
        guard let amount = amount else { return false }

        if isValidCryptocyrrencyAddress {
            if amount.amount >= (gateWayInfo?.minAmount.amount ?? 0) &&
                amount.amount <= (gateWayInfo?.maxAmount.amount ?? 0) {
                return true
            }
            return false
        }
        return true
    }
    
    var isValidFee: Bool {
        return (feeAssetBalance?.availableBalance ?? 0) >= currentFee?.amount ?? 0
    }
    
    var isValidAmount: Bool {
        guard let amount = amount else { return false }
        return availableBalance.amount >= amount.amount
    }
    
    var canValidateAliasOnServer: Bool {
        let alias = recipientAddressView.text
        return alias.count >= Send.ViewModel.minimumAliasLength &&
        alias.count <= Send.ViewModel.maximumAliasLength
    }

    var isValidLocalAddress: Bool {
        return AddressValidator.isValidAddress(address: recipientAddressView.text)
    }
    
    var isValidCryptocyrrencyAddress: Bool {
        let address = recipientAddressView.text

        if let regExp = selectedAsset?.asset.addressRegEx, regExp.count > 0 {
            
            return NSPredicate(format: "SELF MATCHES %@", regExp).evaluate(with: address) &&
                selectedAsset?.asset.isGateway == true &&
                selectedAsset?.asset.isFiat == false &&
                isValidLocalAddress == false
        } else if selectedAsset?.asset.isVostok == true {
            return AddressValidator.isValidVostokAddress(address: address)
        }
        return false
    }

    var validationAddressAsset: Asset? {
        if selectedAsset == nil {
            switch inputModel! {
            case .resendTransaction(let tx):
                return tx.asset
            
            default:
                break
            }
        }
        
        return selectedAsset?.asset
    }

    func isValidAddress(_ address: String) -> Bool {
        guard let asset = validationAddressAsset else { return true }

        if asset.isWaves || asset.isWavesToken || asset.isFiat {
            return isValidLocalAddress || isValidAlias
        }
        else {
            return isValidLocalAddress || isValidCryptocyrrencyAddress || isValidAlias
        }
    }

    func canInputOnlyLocalAddressOrAlias(_ asset: Asset) -> Bool {
         return asset.isWaves || asset.isWavesToken || asset.isFiat
    }
    
    func isCryptoCurrencyAsset(_ asset: Asset) -> Bool {
        return asset.isGateway && !asset.isFiat
    }
    
    func addressNotRequireMinimumLength(_ address: String) -> Bool {
        return address.count > 0 && address.count < Send.ViewModel.minimumAliasLength
    }
    
    func validateAddress() {
        let address = recipientAddressView.text
        guard let asset = validationAddressAsset else { return }

        if addressNotRequireMinimumLength(address) {
            recipientAddressView.checkIfValidAddress()
            return
        }

        if canInputOnlyLocalAddressOrAlias(asset) {
            if !isValidLocalAddress && !isValidAlias && canValidateAliasOnServer {
                sendEvent.accept(.checkValidationAlias)
                recipientAddressView.showLoadingState()
            }
            else {
                recipientAddressView.checkIfValidAddress()
            }
        }
        else if isCryptoCurrencyAsset(asset) {
            if !isValidLocalAddress {
                if isValidCryptocyrrencyAddress {
                    if gateWayInfo == nil {                        
                        sendEvent.accept(.getGatewayInfo(self.amount ?? Money(0, 0)))
                        showLoadingGatewayInfo(isHidden: !hasNeedReloadGateWayInfo)
                        hasNeedReloadGateWayInfo = false
                    }
                    recipientAddressView.checkIfValidAddress()
                }
                else {
                    if !isValidAlias && canValidateAliasOnServer {
                        sendEvent.accept(.checkValidationAlias)
                        recipientAddressView.showLoadingState()
                    }
                    else {
                        recipientAddressView.checkIfValidAddress()
                    }
                }
            }
            else {
                recipientAddressView.checkIfValidAddress()
            }
        }
        else {
            recipientAddressView.checkIfValidAddress()
        }
    }
}

private extension DeepLink {
    
    var assetId: String? {
        return QRCodeParser.parseAssetID(url.absoluteString)
    }
    
    var amount: Double {
        return QRCodeParser.parseAmount(url.absoluteString)
    }
    var recipient: String {
        return QRCodeParser.parseAddress(url.absoluteString)
    }
}

// MARK: - TTTAttributedLabelDelegate
extension SendViewController: TTTAttributedLabelDelegate {
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        UIApplication.shared.openURLAsync(url)
    }
}
