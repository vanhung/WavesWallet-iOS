//
//  StartLeasingLoadingViewController.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 11/20/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import UIKit
import RxSwift
import WavesSDK
import DomainLayer

final class StartLeasingLoadingViewController: UIViewController {

    @IBOutlet private weak var labelTitle: UILabel!
    
    var input: StartLeasingTypes.Input!
    
    private let startLeasingInteractor: StartLeasingInteractorProtocol = StartLeasingInteractor()
    private let transactions = UseCasesFactory.instance.transactions
    private let authorization = UseCasesFactory.instance.authorization
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        switch input.kind {
        case .send(let order):
            labelTitle.text = Localizable.Waves.Startleasingloading.Label.startLeasing
            startLeasing(order: order)

        case .cancel(let cancelOrder):
            labelTitle.text = Localizable.Waves.Startleasingloading.Label.cancelLeasing
            cancelLeasing(cancelOrder: cancelOrder)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        removeTopBarLine()
        navigationItem.hidesBackButton = true
        navigationItem.backgroundImage = UIImage()
    }
    
    private func startLeasing(order: StartLeasingTypes.DTO.Order) {
        startLeasingInteractor
            .createOrder(order: order)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] (transaction) in
            
                guard let self = self else { return }

                let vc = StoryboardScene.StartLeasing.startLeasingCompleteViewController.instantiate()
                vc.kind = self.input.kind
                vc.output = self.input.output
                vc.transaction = transaction
                self.navigationController?.pushViewController(vc, animated: true)

            }, onError: { [weak self] (error) in

                guard let self = self else { return }

                guard let error = error as? NetworkError else { return }
                self.popBackWithFail(error: error)
            })
            .disposed(by: disposeBag)
    }
    
    private func cancelLeasing(cancelOrder: StartLeasingTypes.DTO.CancelOrder) {
        
        cancelOrderRequest(cancelOrder: cancelOrder)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] (transaction) in
            
                guard let self = self else { return }

                let vc = StoryboardScene.StartLeasing.startLeasingCompleteViewController.instantiate()
                vc.kind = self.input.kind
                vc.output = self.input.output
                vc.transaction = transaction
                self.navigationController?.pushViewController(vc, animated: true)

            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                guard let error = error as? NetworkError else { return }
                self.popBackWithFail(error: error)
            })
            .disposed(by: disposeBag)
    }
    
    private func popBackWithFail(error: NetworkError) {
        input.errorDelegate?.startLeasingDidFail(error: error)

        //TODO: Coordinator        
        if let vc = navigationController?.viewControllers.first(where: { (vc) -> Bool in
            return vc is StartLeasingViewController
        }) {
            self.navigationController?.popToViewController(vc, animated: true)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    private func cancelOrderRequest(cancelOrder: StartLeasingTypes.DTO.CancelOrder) -> Observable<DomainLayer.DTO.SmartTransaction> {
        
        return authorization
            .authorizedWallet()
            .flatMap({ [weak self] (wallet) -> Observable<DomainLayer.DTO.SmartTransaction> in

                guard let self = self else { return Observable.empty() }
                let specific = CancelLeaseTransactionSender(leaseId: cancelOrder.leasingTX, fee: cancelOrder.fee.amount)
                return self
                    .transactions
                    .send(by: .cancelLease(specific), wallet: wallet)
            })
    }
}
