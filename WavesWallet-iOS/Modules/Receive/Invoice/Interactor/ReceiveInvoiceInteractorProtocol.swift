//
//  ReceiveInvoiceInteractorProtocol.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 10/11/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import RxSwift
import WavesSDKExtensions
import DomainLayer
import Extensions

protocol ReceiveInvoiceInteractorProtocol {
    func displayInfo(asset: Asset, amount: Money) -> Observable<ReceiveInvoice.DTO.DisplayInfo>
}
