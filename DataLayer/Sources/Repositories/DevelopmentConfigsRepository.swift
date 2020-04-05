//
//  ServerMaintenanceRepository.swift
//  DataLayer
//
//  Created by rprokofev on 19.11.2019.
//  Copyright © 2019 Waves Platform. All rights reserved.
//

import DomainLayer
import Foundation
import Moya
import RxSwift

private struct DevelopmentConfigs: Decodable {
    let serviceAvailable: Bool
    let matcherSwapTimestamp: Date
    let matcherSwapAddress: String
    let exchangeClientSecret: String
    let staking: [Staking]
    let lockedPairs: [String]?
    
    enum CodingKeys: String, CodingKey {
        case serviceAvailable = "service_available"
        case matcherSwapTimestamp = "matcher_swap_timestamp"
        case matcherSwapAddress = "matcher_swap_address"
        case exchangeClientSecret = "exchange_client_secret"
        case staking
        case lockedPairs = "locked_pairs"
    }
}

private struct Staking: Decodable {
    let type: String
    let neutrinoAssetId: String
    let addressByPayoutsAnnualPercent: String
    let addressStakingContract: String
    let addressByCalculateProfit: String
    
    enum CodingKeys: String, CodingKey {
        case type
        case neutrinoAssetId = "neutrino_asset_id"
        case addressByPayoutsAnnualPercent = "address_by_payouts_annual_percent"
        case addressStakingContract = "address_staking_contract"
        case addressByCalculateProfit = "address_by_calculate_profit"
    }
}

public final class DevelopmentConfigsRepository: DevelopmentConfigsRepositoryProtocol {
    private let developmentConfigsProvider: MoyaProvider<ResourceAPI.Service.DevelopmentConfigs> = .anyMoyaProvider()
    
    public func isEnabledMaintenance() -> Observable<Bool> {
        return developmentConfigs()
            .flatMap { Observable.just($0.serviceAvailable == false) }
            .catchError { _ in Observable.just(false) }
    }
    
    public func developmentConfigs() -> Observable<DomainLayer.DTO.DevelopmentConfigs> {
        return developmentConfigsProvider
            .rx
            .request(.get(isDebug: ApplicationDebugSettings.isEnableDebugSettingsTest))
            .map(DevelopmentConfigs.self,
                 atKeyPath: nil,
                 using: JSONDecoder.decoderByDateWithSecond(0),
                 failsOnEmptyData: false)
            .asObservable()
            .map { (config) -> DomainLayer.DTO.DevelopmentConfigs in
                let staking = config.staking.map {
                    DomainLayer.DTO.Staking(type: $0.type,
                                            neutrinoAssetId: $0.neutrinoAssetId,
                                            addressByPayoutsAnnualPercent: $0.addressByPayoutsAnnualPercent,
                                            addressStakingContract: $0.addressStakingContract,
                                            addressByCalculateProfit: $0.addressByCalculateProfit)
                }
                
                return DomainLayer.DTO.DevelopmentConfigs(serviceAvailable: config.serviceAvailable,
                                                          matcherSwapTimestamp: config.matcherSwapTimestamp,
                                                          matcherSwapAddress: config.matcherSwapAddress,
                                                          exchangeClientSecret: config.exchangeClientSecret,
                                                          staking: staking,
                                                          lockedPairs: config.lockedPairs ?? [] )
            }
    }
}
