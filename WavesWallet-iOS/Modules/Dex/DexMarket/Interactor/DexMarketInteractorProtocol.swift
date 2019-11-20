//
//  DexMarketInteractorProtocol.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 8/9/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import RxSwift
import DomainLayer

protocol DexMarketInteractorProtocol {
    
    func pairs() -> Observable<[DomainLayer.DTO.Dex.SmartPair]>
    func searchPairs(searchWord: String) -> Observable<[DomainLayer.DTO.Dex.SmartPair]>
    func checkMark(pair: DomainLayer.DTO.Dex.SmartPair)
}
