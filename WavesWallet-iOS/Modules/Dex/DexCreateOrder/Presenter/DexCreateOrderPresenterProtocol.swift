//
//  DexCreateOrderPresenterProtocol.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 9/21/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import RxCocoa
import Extensions
import DomainLayer

protocol DexCreateOrderPresenterProtocol {
    
    typealias Feedback = (Driver<DexCreateOrder.State>) -> Signal<DexCreateOrder.Event>
    var interactor: DexCreateOrderInteractorProtocol! { get set }
    func system(feedbacks: [Feedback], feeAssetId: String)
    
    var pair: DomainLayer.DTO.Dex.Pair! { get set }
}
