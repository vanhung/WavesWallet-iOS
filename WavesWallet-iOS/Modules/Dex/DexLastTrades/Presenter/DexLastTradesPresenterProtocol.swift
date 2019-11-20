//
//  DexLastTradesPresenterProtocol.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 8/22/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import RxCocoa
import DomainLayer

protocol DexLastTradesPresenterProtocol {
    typealias Feedback = (Driver<DexLastTrades.State>) -> Signal<DexLastTrades.Event>
    var interactor: DexLastTradesInteractorProtocol! { get set }
    func system(feedbacks: [Feedback])
    
    var moduleOutput: DexLastTradesModuleOutput? { get set }
    var priceAsset: DomainLayer.DTO.Dex.Asset! { get set }
    var amountAsset: DomainLayer.DTO.Dex.Asset! { get set }
}
