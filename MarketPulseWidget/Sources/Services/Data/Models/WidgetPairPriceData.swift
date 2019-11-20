//
//  PairApi.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 12/26/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation


extension WidgetDataService.DTO {
    
    struct PairPrice: Decodable {
        
        let firstPrice: Double
        let lastPrice: Double
        let volume: Double
        let volumeWaves: Double?
        let quoteVolume: Double?
    }
    
    struct PairPriceSearch: Decodable {
        
        let data: PairPrice
        let amountAsset: String
        let priceAsset: String
    }
}

