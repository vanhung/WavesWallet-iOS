//
//  Response.swift
//  WavesWallet-iOS
//
//  Created by mefilt on 09.07.2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation

extension WidgetDataService {
    struct Response<T: Decodable>: Decodable {
        let type: String
        let data: T
        let lastCursor: String?

        enum CodingKeys: String, CodingKey {
            case type = "__type"
            case data
            case lastCursor
        }
    }
    
    struct OptionalResponse<T: Decodable>: Decodable {
        let type: String
        let data: T?
        let lastCursor: String?
        
        enum CodingKeys: String, CodingKey {
            case type = "__type"
            case data
            case lastCursor
        }
    }
}
