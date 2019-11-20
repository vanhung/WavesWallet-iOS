//
//  SendFeeInteractor.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 1/31/19.
//  Copyright © 2019 Waves Exchange. All rights reserved.
//

import Foundation
import RxSwift
import DomainLayer
import Extensions

final class SendFeeInteractor: SendFeeInteractorProtocol {
    
    private let balance = UseCasesFactory.instance.accountBalance
    private let auth = UseCasesFactory.instance.authorization
    private let transactions = UseCasesFactory.instance.transactions
    
    func assets() -> Observable<[DomainLayer.DTO.SmartAssetBalance]> {
        return balance.balances().map({ (smartAssets) -> [DomainLayer.DTO.SmartAssetBalance] in
            return smartAssets.filter({$0.asset.isWaves || $0.asset.isSponsored})
        })
    }
    
    func calculateFee(assetID: String) -> Observable<Money> {
        return auth.authorizedWallet().flatMap({ [weak self] (wallet) -> Observable<Money> in
            guard let self = self else { return Observable.empty() }
            return self.transactions.calculateFee(by: .sendTransaction(assetID: assetID), accountAddress: wallet.address)
        })
    }
}
