//
//  AliasRepositoryRemote.swift
//  WavesWallet-iOS
//
//  Created by Prokofev Ruslan on 27/10/2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import DomainLayer
import Foundation
import Moya
import RxSwift
import WavesSDK
import WavesSDKExtensions

final class AliasesRepository: AliasesRepositoryProtocol {
    private let environmentRepository: ExtensionsEnvironmentRepositoryProtocols

    init(environmentRepository: ExtensionsEnvironmentRepositoryProtocols) {
        self.environmentRepository = environmentRepository
    }

    func aliases(accountAddress: String) -> Observable<[DomainLayer.DTO.Alias]> {
        environmentRepository
            .servicesEnvironment()
            .flatMapLatest { servicesEnvironment
                -> Observable<(aliases: [DataService.DTO.Alias], environment: WalletEnvironment)> in
                servicesEnvironment
                    .wavesServices
                    .dataServices
                    .aliasDataService
                    .aliases(address: accountAddress)
                    .map { (aliases: $0, environment: servicesEnvironment.walletEnvironment) }
            }
            .map { data -> [DomainLayer.DTO.Alias] in
                let list = data.aliases
                let aliasScheme = data.environment.aliasScheme

                return list.map { alias -> DomainLayer.DTO.Alias? in

                    let name = alias.alias
                    let originalName = aliasScheme + name
                    return DomainLayer.DTO.Alias(name: name, originalName: originalName)
                }
                .compactMap { $0 }
            }
    }

    func alias(by name: String, accountAddress: String) -> Observable<String> {
        environmentRepository
            .servicesEnvironment()
            .flatMapLatest { servicesEnvironment -> Observable<String> in
                servicesEnvironment
                    .wavesServices
                    .dataServices
                    .aliasDataService
                    .alias(name: name)
                    .map { $0.address }
                    .catchError { error -> Observable<String> in

                        if let error = error as? NetworkError, error == .notFound {
                            return Observable.error(AliasesRepositoryError.dontExist)
                        }

                        return Observable.error(AliasesRepositoryError.invalid)
                    }
            }
    }

    func saveAliases(by accountAddress: String, aliases: [DomainLayer.DTO.Alias]) -> Observable<Bool> {
        assertMethodDontSupported()
        return Observable.never()
    }
}
