//
//  AssetListInteractorProtocol.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 10/4/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import RxSwift
import DomainLayer

protocol AssetListInteractorProtocol {
    
    func assets(filters: [AssetList.DTO.Filter], isMyList: Bool) -> Observable<[DomainLayer.DTO.SmartAssetBalance]>
    func searchAssets(searchText: String)

}
