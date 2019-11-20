//
//  TokenBurnViewController.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 11/13/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import UIKit
import RxSwift
import WavesSDK
import RxCocoa
import Extensions
import DomainLayer

private enum Constants {
    static let animationDuration: TimeInterval = 0.3
}

protocol TokenBurnTransactionDelegate: AnyObject {
    
    func tokenBurnDidSuccessBurn(amount: Money)
}

final class TokenBurnViewController: UIViewController {

    @IBOutlet private weak var assetView: AssetSelectView!
    @IBOutlet private weak var amountView: AmountInputView!
    @IBOutlet private weak var buttonContinue: HighlightedButton!
    @IBOutlet private weak var viewFeeError: UIView!
    @IBOutlet private weak var labelFeeError: UILabel!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var viewFee: TransactionFeeView!

    var asset: DomainLayer.DTO.SmartAssetBalance!
    weak var delegate: TokenBurnTransactionDelegate?
    
    private let disposeBag = DisposeBag()
    private let interactor = TokenBurnInteractor()
    private var errorSnackKey: String?
    
    private var wavesBalance: Money?
    private var amount: Money?
    private var fee: Money?
    private var isShowError = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
   
        createBackButton()
        setupLocalization()
        setupData()
        setupButtonContinue()
        loadWavesBalance()
        loadFee()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupBigNavigationBar()
        hideTopBarLineForIOS12()
    }
   
    @IBAction private func continueTapped(_ sender: Any) {
        guard let amount = self.amount else { return }
        guard let fee = self.fee else { return }
        
        let vc = StoryboardScene.Asset.tokenBurnConfirmationViewController.instantiate()
        vc.input = .init(asset: asset, amount: amount, fee: fee, delegate: delegate, errorDelegate: self)
        navigationController?.pushViewController(vc, animated: true)
        
        UseCasesFactory.instance.analyticManager.trackEvent(.tokenBurn(.continueTap))
    }
}


//MARK: - TokenBurnLoadingViewControllerDelegate
extension TokenBurnViewController: TokenBurnLoadingViewControllerDelegate {
    
    func tokenBurnLoadingViewControllerDidFail(error: Error) {
        
        switch error {
        case let error as NetworkError:
            switch error {
            case .scriptError:
                _ = TransactionScriptErrorView.show()
            default:
                showNetworkErrorSnack(error: error)
            }
        default:
            showErrorNotFoundSnack()
        }
    }
}



//MARK: - Data
private extension TokenBurnViewController {
    
    func loadWavesBalance() {
        
        interactor
            .getWavesBalance()
            .asDriver { (error) -> SharedSequence<DriverSharingStrategy, Money> in
                return SharedSequence.just(Money(0, 0))
            }.drive(onNext: { [weak self] (wavesBalance) in
                
                guard let self = self else { return }
                self.wavesBalance = wavesBalance
                self.setupButtonContinue()
                self.activityIndicator.stopAnimating()
                self.updateFeeError()
                
            })
            .disposed(by: disposeBag)
    }
    
    var input: [Money] {
        return [availableBalance]
    }
    
    var isValidFee: Bool {
        guard let balance = wavesBalance else { return false }
        guard let fee = fee else { return false }
        return balance.amount >= fee.amount
    }
    
    var availableBalance: Money {
        return Money(asset.availableBalance, asset.asset.precision)
    }
    
    var isValidInputAmount: Bool {
        guard let amount = self.amount else { return false }
        return amount.amount <= availableBalance.amount && amount.amount > 0
    }
}

//MARK: - AmountInputViewDelegate
extension TokenBurnViewController: AmountInputViewDelegate {
    
    func amountInputView(didChangeValue value: Money) {
        
        amount = value
        setupButtonContinue()
        showLoadingIndicatorIfNeed()
        updateFeeError()
        
        let isShowError = value.amount > availableBalance.amount
        amountView.showErrorMessage(message: Localizable.Waves.Tokenburn.Label.Error.insufficientFunds, isShow: isShowError)
    }
}

//MARK: - UIScrollViewDelegate
extension TokenBurnViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        setupTopBarLine()
    }
}

//MARK: - UI
private extension TokenBurnViewController {
    
    func loadFee() {
        viewFee.showLoadingState()

        interactor
            .getFee(assetID: asset.assetId)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] (fee) in
                guard let self = self else { return }
                self.updateFee(fee)
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                if let error = error as? TransactionsUseCaseError, error == .commissionReceiving {
                    self.showFeeError(DisplayError.message(Localizable.Waves.Transaction.Error.Commission.receiving))
                } else {
                    self.showFeeError(DisplayError(error: error))
                }
            })
            .disposed(by: disposeBag)
    }
    
    func showFeeError(_ error: DisplayError) {
        
        switch error {
        case .globalError(let isInternetNotWorking):
            
            if isInternetNotWorking {
                errorSnackKey = showWithoutInternetSnack { [weak self] in
                    self?.loadFee()
                }
            } else {
                errorSnackKey = showErrorNotFoundSnack(didTap: { [weak self] in
                    self?.loadFee()
                })
            }
        case .internetNotWorking:
            errorSnackKey = showWithoutInternetSnack { [weak self] in
                self?.loadFee()
            }
            
        case .message(let text):
            errorSnackKey = showErrorSnack(title: text, didTap: { [weak self] in
                self?.loadFee()
            })
            
        case .none, .scriptError:
            errorSnackKey = showErrorNotFoundSnack(didTap: { [weak self] in
                self?.loadFee()
            })
        }
    }
    
    func updateFee(_ fee: Money) {
        
        if let errorSnackKey = errorSnackKey {
            hideSnack(key: errorSnackKey)
        }
        
        viewFee.update(with: .init(fee: fee, assetName: nil))
        viewFee.hideLoadingState()
        self.fee = fee
        setupButtonContinue()
    }
    
    func setupButtonContinue() {
        let canContinue = isValidInputAmount && isValidFee
        buttonContinue.isUserInteractionEnabled = canContinue
        buttonContinue.backgroundColor = canContinue ? .submit400 : .submit200
    }
    
    func updateFeeError() {
        
        if let money = amount, money.amount > 0, wavesBalance != nil  {
            let isShow = isValidFee ? false : true
            showError(isShow)
        }
        else {
            showError(false)
        }
    }
    
    func showError(_ show: Bool) {
        
        if isShowError != show {
            isShowError = show
            UIView.animate(withDuration: Constants.animationDuration) {
                self.viewFeeError.alpha = show ? 1 : 0
            }
        }
    }
    
    func showLoadingIndicatorIfNeed() {
        if let money = amount, money.amount > 0, wavesBalance == nil {
            activityIndicator.isHidden = false
            activityIndicator.startAnimating()
        }
        else {
            if activityIndicator.isAnimating {
                activityIndicator.stopAnimating()
            }
        }
    }
    
    func setupData() {
        viewFeeError.alpha = 0
        assetView.isSelectedAssetMode = false
        assetView.update(with: .init(assetBalance: asset, isOnlyBlockMode: true))
        
        amountView.delegate = self
        amountView.setDecimals(asset.asset.precision, forceUpdateMoney: false)
        
        if !availableBalance.isZero {
            amountView.input = { [weak self] in
                return self?.input ?? []
            }
            amountView.update(with: [Localizable.Waves.Tokenburn.Button.useTotalBalanace])
        }
    }
    
    func setupLocalization() {
        title = Localizable.Waves.Tokenburn.Label.tokenBurn
        amountView.setupRightLabelText(asset.asset.displayName)
        amountView.setupTitle(Localizable.Waves.Tokenburn.Label.quantityTokensBurned)
        buttonContinue.setTitle(Localizable.Waves.Tokenburn.Button.continue, for: .normal)
        labelFeeError.text = Localizable.Waves.Tokenburn.Label.Error.notFundsFee
    }
}
