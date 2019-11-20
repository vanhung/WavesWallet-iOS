//
//  DexChartInteractorProtocol.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 8/28/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import RxSwift
import DomainLayer

protocol DexChartInteractorProtocol {
    
    var pair: DexTraderContainer.DTO.Pair! { get set }
    
    func candles(timeFrame: DomainLayer.DTO.Candle.TimeFrameType, timeStart: Date, timeEnd: Date) -> Observable<[DomainLayer.DTO.Candle]>
    
}
