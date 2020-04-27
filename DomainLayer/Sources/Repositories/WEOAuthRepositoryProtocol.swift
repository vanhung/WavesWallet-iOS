//
//  WavesExchangeAuthProtocol.swift
//  DomainLayer
//
//  Created by rprokofev on 12.03.2020.
//  Copyright © 2020 Waves Platform. All rights reserved.
//

import Foundation
import RxSwift

public extension DomainLayer.DTO {
    enum WEOAuth {}
}

public extension DomainLayer.DTO.WEOAuth {
    
    struct Token {
        
        public let accessToken: String
        
        public init(accessToken: String) {
            self.accessToken = accessToken
        }
    }
}

public protocol WEOAuthRepositoryProtocol {
    func oauthToken(serverEnvironment: ServerEnvironment,
                    signedWallet: DomainLayer.DTO.SignedWallet) -> Observable<DomainLayer.DTO.WEOAuth.Token>
}