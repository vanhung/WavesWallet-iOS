//
//  LastTradesRepositoryProtocol.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 12/5/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import RxSwift

public protocol LastTradesRepositoryProtocol {
    func lastTrades(serverEnvironment: ServerEnvironment,
                    amountAsset: Asset,
                    priceAsset: Asset,
                    limit: Int) -> Observable<[DomainLayer.DTO.Dex.LastTrade]>
}
