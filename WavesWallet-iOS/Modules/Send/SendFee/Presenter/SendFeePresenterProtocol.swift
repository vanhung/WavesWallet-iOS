//
//  SendFeePresenterProtocol.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 1/31/19.
//  Copyright © 2019 Waves Exchange. All rights reserved.
//

import Foundation
import RxCocoa
import Extensions

protocol SendFeePresenterProtocol {
    typealias Feedback = (Driver<SendFee.State>) -> Signal<SendFee.Event>
    var interactor: SendFeeInteractorProtocol! { get set }
    func system(feedbacks: [Feedback])
    
    var assetID: String! { get set }
    var feeAssetID: String! { get set }
    var wavesFee: Money! { get set }
    
}
