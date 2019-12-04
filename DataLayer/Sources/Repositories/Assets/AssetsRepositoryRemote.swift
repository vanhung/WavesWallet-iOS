//
//  AssetsRepositoryRemote.swift
//  WavesWallet-iOS
//
//  Created by Prokofev Ruslan on 04/08/2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import RxSwift
import Moya
import CSV
import WavesSDKExtensions
import WavesSDK
import DomainLayer
import Extensions

private enum Constants {
    static let searchAssetsLimit: Int = 100
    static let vostokAssetDescription = "Waves Enterprise System Token."
    static let vostokAssetId = "Vostok"
}

final class AssetsRepositoryRemote: AssetsRepositoryProtocol {
    
    private let environmentRepository: EnvironmentRepositoryProtocols
    
    private let spamAssetsRepository: SpamAssetsRepositoryProtocol
    
    private let accountSettingsRepository: AccountSettingsRepositoryProtocol
    
    init(environmentRepository: EnvironmentRepositoryProtocols,
         spamAssetsRepository: SpamAssetsRepositoryProtocol,
         accountSettingsRepository: AccountSettingsRepositoryProtocol) {
        self.environmentRepository = environmentRepository
        self.spamAssetsRepository = spamAssetsRepository
        self.accountSettingsRepository = accountSettingsRepository
    }
    
    func assets(by ids: [String], accountAddress: String) -> Observable<[DomainLayer.DTO.Asset]> {

        return environmentRepository
            .servicesEnvironment()
            .flatMap({ [weak self] (servicesEnvironment) -> Observable<[DomainLayer.DTO.Asset]> in
                
            guard let self = self else { return Observable.empty() }
            
            let walletEnviroment = servicesEnvironment.walletEnvironment

            let spamAssets = self.spamAssets(accountAddress: accountAddress)

            let assetsList = servicesEnvironment
                .wavesServices
                .dataServices
                .assetsDataService
                .assets(ids: ids)
            
            return Observable.zip(assetsList, spamAssets)
                .map({ (assets, spamAssets) -> [DomainLayer.DTO.Asset] in
                    
                    let map = walletEnviroment.hashMapAssets()
                    let mapGeneralAssets = walletEnviroment.hashMapGeneralAssets()
                    
                    let spamIds = spamAssets.reduce(into: [String: Bool](), {$0[$1] = true })

                    return assets.map { DomainLayer.DTO.Asset(asset: $0,
                                                              info: map[$0.id],
                                                              isSpam: spamIds[$0.id] == true,
                                                              isMyWavesToken: $0.sender == accountAddress,
                                                              isGeneral: mapGeneralAssets[$0.id] != nil) }
                })
        })
    }

    //TODO: Refactor method
    func searchAssets(search: String, accountAddress: String) -> Observable<[DomainLayer.DTO.Asset]> {
        
        return environmentRepository
            .servicesEnvironment()
            .flatMap({ [weak self] (servicesEnvironment) -> Observable<[DomainLayer.DTO.Asset]> in
                
                guard let self = self else { return Observable.empty() }
                
                let walletEnviroment = servicesEnvironment.walletEnvironment
                
                let spamAssets = self.spamAssets(accountAddress: accountAddress)
                
                let assetsList = servicesEnvironment
                    .wavesServices
                    .dataServices
                    .assetsDataService
                    .searchAssets(search: search, limit: Constants.searchAssetsLimit)
                
                return Observable.zip(assetsList, spamAssets)
                    .map({ (assets, spamAssets) -> [DomainLayer.DTO.Asset] in
                        
                        let map = walletEnviroment.hashMapAssets()
                        let mapGeneralAssets = walletEnviroment.hashMapGeneralAssets()
                        
                        let spamIds = spamAssets.reduce(into: [String: Bool](), {$0[$1] = true })
                        
                        return assets.map { DomainLayer.DTO.Asset(asset: $0,
                                                                  info: map[$0.id],
                                                                  isSpam: spamIds[$0.id] == true,
                                                                  isMyWavesToken: $0.sender == accountAddress,
                                                                  isGeneral: mapGeneralAssets[$0.id] != nil) }
                    })
            })
    }

    func saveAssets(_ assets:[DomainLayer.DTO.Asset], by accountAddress: String) -> Observable<Bool> {
        assertMethodDontSupported()
        return Observable.never()
    }

    func saveAsset(_ asset: DomainLayer.DTO.Asset, by accountAddress: String) -> Observable<Bool> {
        assertMethodDontSupported()
        return Observable.never()
    }

    func isSmartAsset(_ assetId: String, by accountAddress: String) -> Observable<Bool> {

        if assetId == WavesSDKConstants.wavesAssetId {
            return Observable.just(false)
        }

        return environmentRepository
            .servicesEnvironment()
            .map { $0.wavesServices }
            .flatMap({ (wavesServices) -> Observable<Bool> in                
                
                return wavesServices
                    .nodeServices
                    .assetsNodeService
                    .assetDetails(assetId: assetId)
                    .map { $0.scripted == true }
            })
    }
}

fileprivate extension AssetsRepositoryRemote {
    
    func spamAssets(accountAddress: String) -> Observable<[SpamAssetId]> {
        
        return self.accountSettingsRepository.accountSettings(accountAddress: accountAddress)
            .flatMap { [weak self] (settings) -> Observable<[SpamAssetId]> in
             
                guard let self = self else { return Observable.never() }
                
                if settings?.isEnabledSpam ?? true {
                    return self.spamAssetsRepository.spamAssets(accountAddress: accountAddress)
                } else {
                    return Observable.just([])
                }
            }
    }
}

fileprivate extension WalletEnvironment {

    func hashMapAssets() -> [String: WalletEnvironment.AssetInfo] {
        
        var allAssets = generalAssets
        if let additionalAssets = assets {
            allAssets.append(contentsOf: additionalAssets)
        }
        
        return allAssets.reduce([String: WalletEnvironment.AssetInfo](), { map, info -> [String: WalletEnvironment.AssetInfo] in
            var new = map
            new[info.assetId] = info
            return new
        })
    }
    
    func hashMapGeneralAssets() -> [String: WalletEnvironment.AssetInfo] {
        
        let allAssets = generalAssets
        
        return allAssets.reduce([String: WalletEnvironment.AssetInfo](), { map, info -> [String: WalletEnvironment.AssetInfo] in
            var new = map
            new[info.assetId] = info
            return new
        })
    }
}

fileprivate extension DomainLayer.DTO.Asset {

    init(asset: DataService.DTO.Asset, info: WalletEnvironment.AssetInfo?, isSpam: Bool, isMyWavesToken: Bool, isGeneral: Bool) {
        var isWaves = false
        var isFiat = false
        let isGateway = info?.isGateway ?? false
        let isWavesToken = isFiat == false && isGateway == false && isWaves == false
        var name = asset.name
        var description = asset.description
        
        //TODO: Current code need move to AssetsInteractor!
        if let info = info {
            if info.assetId == WavesSDKConstants.wavesAssetId {
                isWaves = true
            }
            
            if info.gatewayId == Constants.vostokAssetId {
                description = Constants.vostokAssetDescription
            }
            
            name = info.displayName
            isFiat = info.isFiat
        }
        
        self.init(id: asset.id,
                  gatewayId: info?.gatewayId,
                  wavesId: info?.wavesId,
                  displayName: name,
                  precision: asset.precision,
                  description: description,
                  height: asset.height,
                  timestamp: asset.timestamp,
                  sender: asset.sender,
                  quantity: asset.quantity,
                  ticker: asset.ticker,
                  isReusable: asset.reissuable,
                  isSpam: isSpam,
                  isFiat: isFiat,
                  isGeneral: isGeneral,
                  isMyWavesToken: isMyWavesToken,
                  isWavesToken: isWavesToken,
                  isGateway: isGateway,
                  isWaves: isWaves,
                  modified: Date(),
                  addressRegEx: info?.addressRegEx ?? "",
                  iconLogoUrl: info?.iconUrls?.default,
                  hasScript: asset.hasScript,
                  minSponsoredFee: asset.minSponsoredFee ?? 0,
                  gatewayType: info?.gatewayType)
    }
}
