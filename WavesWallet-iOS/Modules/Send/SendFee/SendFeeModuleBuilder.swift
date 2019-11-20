//
//  SendFeeModuleBuilder.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 1/31/19.
//  Copyright © 2019 Waves Exchange. All rights reserved.
//

import UIKit
import Extensions
import DomainLayer

protocol SendFeeModuleOutput: AnyObject {
    
    func sendFeeModuleDidSelectAssetFee(_ asset: DomainLayer.DTO.SmartAssetBalance, fee: Money)
}

private enum Constants {
    static let minimumHeight: CGFloat = 314
}

struct SendFeeModuleBuilder: ModuleBuilderOutput {
    
    var output: SendFeeModuleOutput
    
    struct Input {
        let wavesFee: Money
        let assetID: String
        let feeAssetID: String
    }
    
    func build(input: Input) -> UIViewController {
        
        let interactor: SendFeeInteractorProtocol = SendFeeInteractor()
        var presenter: SendFeePresenterProtocol = SendFeePresenter()
        presenter.interactor = interactor
        presenter.assetID = input.assetID
        presenter.feeAssetID = input.feeAssetID
        presenter.wavesFee = input.wavesFee
        
        let vc = StoryboardScene.Send.sendFeeViewController.instantiate()
        vc.presenter = presenter
        vc.delegate = output
    
        return vc
    }
}
