//
//  DexInfoTypes.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 8/11/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import DomainLayer
import Extensions

enum DexInfoPair {
    enum DTO {}
}

extension DexInfoPair.DTO {
    
    struct Pair: Mutating {
        let amountAsset: Asset
        let priceAsset: Asset
        let isGeneral: Bool
    }
}
