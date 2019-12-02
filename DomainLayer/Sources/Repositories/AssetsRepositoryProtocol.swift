//
//  AssetsRepository.swift
//  WavesWallet-iOS
//
//  Created by Prokofev Ruslan on 04/08/2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import RxSwift

public enum AssetsRepositoryError: Error {
    case fail
    case notFound
}

public protocol AssetsRepositoryProtocol  {

    func assets(by ids: [String], accountAddress: String) -> Observable<[DomainLayer.DTO.Asset]>
    
    func saveAssets(_ assets:[DomainLayer.DTO.Asset], by accountAddress: String) -> Observable<Bool>
    func saveAsset(_ asset: DomainLayer.DTO.Asset, by accountAddress: String) -> Observable<Bool>

    func isSmartAsset(_ assetId: String, by accountAddress: String) -> Observable<Bool>
   
    func searchAssets(search: String, accountAddress: String) -> Observable<[DomainLayer.DTO.Asset]>
}
