//
//  ReceiveCardInteractorProtocol.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 10/7/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import RxSwift
import DomainLayer
import Extensions

protocol ReceiveCardInteractorProtocol {
    
    func getInfo(fiatType: ReceiveCard.DTO.FiatType) -> Observable<ResponseType<ReceiveCard.DTO.Info>>
    func getWavesAmount(fiatAmount: Money, fiatType: ReceiveCard.DTO.FiatType) -> Observable<ResponseType<Money>>
}
