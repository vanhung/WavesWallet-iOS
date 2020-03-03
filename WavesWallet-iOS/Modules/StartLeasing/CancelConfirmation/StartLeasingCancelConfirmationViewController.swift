//
//  StartLeasingCancelConfirmationViewController.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 11/20/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import UIKit
import RxSwift
import WavesSDKExtensions
import WavesSDK
import Extensions
import DomainLayer

private enum Constants {
    static let cornerRadius: CGFloat = 2
}

final class StartLeasingCancelConfirmationViewController: UIViewController {
    @IBOutlet private weak var viewContainer: UIView!
    @IBOutlet private weak var buttonCancel: HighlightedButton!
    @IBOutlet private weak var labelAmount: UILabel!
    @IBOutlet private weak var tickerView: TickerView!
    @IBOutlet private weak var labelLeasingTxTitle: UILabel!
    @IBOutlet private weak var labelLeasingTx: UILabel!
    @IBOutlet private weak var labelFeeTitle: UILabel!
    @IBOutlet private weak var labelFee: UILabel!
    @IBOutlet private weak var activityIndicatorFee: UIActivityIndicatorView!
    
    var cancelOrder: StartLeasingTypes.DTO.CancelOrder!
    weak var output: StartLeasingModuleOutput?

    private var fee: Money?
    private let transactionInteractor = UseCasesFactory.instance.transactions
    private let auth = UseCasesFactory.instance.authorization
    private var disposeBag = DisposeBag()
    
    private var errorSnackKey: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        createBackWhiteButton()
        setupLocalization()
        setupData()
        loadFee()
        setupButtonCancel()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        viewContainer.createTopCorners(radius: Constants.cornerRadius)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        removeTopBarLine()
        setupBigNavigationBar()
        navigationItem.backgroundImage = UIImage()
        navigationItem.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        navigationItem.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
    }
    
    private func setupButtonCancel() {
        let canContinueAction = cancelOrder.fee.amount > 0
        buttonCancel.isUserInteractionEnabled = canContinueAction
        buttonCancel.backgroundColor = canContinueAction ? .error400 : .error200
    }
    
    private func setupData() {
        tickerView.update(with: .init(text: WavesSDKConstants.wavesAssetId, style: .soft))
        labelAmount.text = cancelOrder.amount.displayText
        labelLeasingTx.text = cancelOrder.leasingTX
        labelFee.text = cancelOrder.fee.displayText + " " + WavesSDKConstants.wavesAssetId
    }
    
    private func setupLocalization() {
        title = Localizable.Waves.Startleasingconfirmation.Label.confirmation
        labelLeasingTxTitle.text = Localizable.Waves.Startleasingconfirmation.Label.leasingTX
        labelFeeTitle.text = Localizable.Waves.Startleasingconfirmation.Label.fee
        buttonCancel.setTitle(Localizable.Waves.Startleasingconfirmation.Button.cancelLeasing, for: .normal)
    }

    @IBAction private func cancelLeasing(_ sender: Any) {
    
        if cancelOrder.fee.isZero {
            return
        }
        
        let vc = StoryboardScene.StartLeasing.startLeasingLoadingViewController.instantiate()
        vc.input = .init(kind: .cancel(cancelOrder), errorDelegate: self, output: output)
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - StartLeasingErrorDelegate
extension StartLeasingCancelConfirmationViewController: StartLeasingErrorDelegate {
    func startLeasingDidFail(error: NetworkError) {
        switch error {
        case .scriptError:
            TransactionScriptErrorView.show()
        default:
            showNetworkErrorSnack(error: error)
        }
    }
}

private extension StartLeasingCancelConfirmationViewController {
    
    func loadFee() {
        labelFee.isHidden = true
        
        auth
            .authorizedWallet()
            .flatMap { [weak self] wallet -> Observable<Money> in
                guard let self = self else { return Observable.empty() }
                return self.transactionInteractor.calculateFee(by: .cancelLease, accountAddress: wallet.address)
            }
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] fee in
                guard let self = self else { return }
                self.updateFee(fee)
            }, onError: { [weak self] error in
                if let error = error as? TransactionsUseCaseError, error == .commissionReceiving {
                    self?.showFeeError(DisplayError.message(Localizable.Waves.Transaction.Error.Commission.receiving))
                } else {
                    self?.showFeeError(DisplayError(error: error))
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
        
        cancelOrder.fee = fee
        labelFee.text = cancelOrder.fee.displayText + " " + WavesSDKConstants.wavesAssetId
        labelFee.isHidden = false
        setupButtonCancel()
        activityIndicatorFee.stopAnimating()
    }
}
