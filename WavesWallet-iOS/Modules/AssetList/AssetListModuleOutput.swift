//
//  AssetListModuleOutput.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 10/5/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import DomainLayer

protocol AssetListModuleOutput: AnyObject {
    
    func assetListDidSelectAsset(_ asset: DomainLayer.DTO.SmartAssetBalance)
}
