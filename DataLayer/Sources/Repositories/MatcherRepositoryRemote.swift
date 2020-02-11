//
//  MatcherRepositoryRemote.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 12/26/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import RxSwift
import Moya
import WavesSDKCrypto
import WavesSDK
import DomainLayer
import Extensions

final class MatcherRepositoryRemote: MatcherRepositoryProtocol {

    private let environmentRepository: ExtensionsEnvironmentRepositoryProtocols
    
    init(environmentRepository: ExtensionsEnvironmentRepositoryProtocols) {
        self.environmentRepository = environmentRepository
    }
    
    func matcherPublicKey() -> Observable<PublicKeyAccount> {
        
        return environmentRepository
            .servicesEnvironment()
            .flatMapLatest({ (servicesEnvironment) -> Observable<PublicKeyAccount> in
                
                return servicesEnvironment
                    .wavesServices
                    .matcherServices
                    .publicKeyMatcherService
                    .publicKey()                                        
                    .map {
                        return PublicKeyAccount(publicKey: Base58Encoder.decode($0))
                    }
            })
    }

    func settingsIdsPairs() -> Observable<[String]> {
     
        return environmentRepository
            .servicesEnvironment()
            .flatMapLatest({ (servicesEnvironment) -> Observable<[String]> in
                
                return servicesEnvironment
                    .wavesServices
                    .matcherServices
                    .orderBookMatcherService
                    .settings()
                    .map {
                        return $0.priceAssets
                    }
            })
    }
}
