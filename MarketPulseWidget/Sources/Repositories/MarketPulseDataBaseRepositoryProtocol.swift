//
//  MarketPulseRepositoryProtocol.swift
//  MarketPulseWidget
//
//  Created by Pavel Gubin on 01.08.2019.
//  Copyright © 2019 Waves Exchange. All rights reserved.
//

import Foundation
import RxSwift

protocol MarketPulseDataBaseRepositoryProtocol {
    
    //TODO: Rename to assets
    func chachedAssets() -> Observable<[MarketPulse.DTO.Asset]>
    func saveAsssets(assets: [MarketPulse.DTO.Asset]) -> Observable<Bool>
}
