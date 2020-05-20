//
//  TokenBurnLoadingInteractor.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 11/15/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import RxSwift
import DomainLayer
import Extensions

protocol TokenBurnSendInteractorProtocol {
    
    func burnAsset(asset: DomainLayer.DTO.SmartAssetBalance, fee: Money, quiantity: Money) -> Observable<TokenBurnTypes.TransactionStatus>
    func getFee(assetID: String) -> Observable<Money>
}
