//
//  DexListRepositoryRemote.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 12/17/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import RxSwift

public protocol DexPairsPriceRepositoryProtocol {
    
    func pairs(accountAddress: String, pairs: [DomainLayer.DTO.Dex.SimplePair]) -> Observable<[DomainLayer.DTO.Dex.PairPrice]>
    
    func pairsRate(query: DomainLayer.Query.Dex.PairsRate) -> Observable<[DomainLayer.DTO.Dex.PairRate]>
    //TODO: Refactor searchPairs and search
    func searchPairs(_ query: DomainLayer.Query.Dex.SearchPairs) -> Observable<DomainLayer.DTO.Dex.PairsSearch>
    
    func search(by accountAddress: String, searchText: String) -> Observable<[DomainLayer.DTO.Dex.SimplePair]>
}
