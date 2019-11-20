//
//  SendFeeInteractorProcotol.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 1/31/19.
//  Copyright © 2019 Waves Exchange. All rights reserved.
//

import Foundation
import RxSwift
import Extensions
import DomainLayer

protocol SendFeeInteractorProtocol {
    func assets() -> Observable<[DomainLayer.DTO.SmartAssetBalance]>
    func calculateFee(assetID: String) -> Observable<Money>
}
