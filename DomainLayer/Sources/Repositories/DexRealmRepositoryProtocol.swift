//
//  DexRepositoryProtocol.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 10/28/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import RxSwift

public protocol DexRealmRepositoryProtocol {
    
    func save(pair: DomainLayer.DTO.Dex.SavePair, accountAddress: String) -> Observable<Bool>
    func delete(by id: String, accountAddress: String) -> Observable<Bool> 
    func list(by accountAddress: String) -> Observable<[DomainLayer.DTO.Dex.FavoritePair]>
    func checkmark(pairs: [DomainLayer.DTO.Dex.SmartPair], accountAddress: String) -> Observable<[DomainLayer.DTO.Dex.SmartPair]>
    func updateSortLevel(ids: [String: Int], accountAddress: String) -> Observable<Bool>
}
