//
//  SendLoadingViewController.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 10/23/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import UIKit
import RxSwift
import DomainLayer

final class SendLoadingViewController: UIViewController {

    @IBOutlet private weak var labelSending: UILabel!
    
    weak var delegate: SendResultDelegate?
    var input: SendConfirmationViewController.Input!
    
    var interactor: SendInteractorProtocol!
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        labelSending.text = Localizable.Waves.Sendloading.Label.sending
        navigationItem.hidesBackButton = true
        send()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        removeTopBarLine()
        navigationItem.backgroundImage = UIImage()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    private func showComplete() {
        let vc = StoryboardScene.Send.sendCompleteViewController.instantiate()
        vc.delegate = delegate
        vc.input = .init(assetName: input.asset.displayName,
                         amount: input.amount,
                         address: input.displayAddress,
                         amountWithoutFee: input.amountWithoutFee)
        
        //TODO: Move to coordinator
        var viewControllers = navigationController?.viewControllers.filter { $0 != self } ?? []
        viewControllers.append(vc)
        navigationController?.setViewControllers(viewControllers    , animated: true)
    }
    
    private func send() {
      
        interactor
            .send(fee: input.fee, recipient: input.address, asset: input.asset, amount: input.amount, attachment: input.attachment, feeAssetID: input.feeAssetID, isGatewayTransaction: input.isGateway)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] status in
                guard let self = self else { return }
                switch status {
                case .success:
                    self.showComplete()
                
                case .error(let error):
                    self.delegate?.sendResultDidFail(error)
                }
                
        }).disposed(by: disposeBag)
    }
}
