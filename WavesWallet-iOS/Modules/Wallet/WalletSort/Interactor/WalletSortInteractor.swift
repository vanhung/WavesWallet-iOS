//
//  NewWalletSortInteractor.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 4/17/19.
//  Copyright © 2019 Waves Exchange. All rights reserved.
//

import Foundation
import RxSwift
import DomainLayer

final class WalletSortInteractor: WalletSortInteractorProtocol {
 
    private let authorizationInteractor: AuthorizationUseCaseProtocol = UseCasesFactory.instance.authorization
    private let assetsBalanceSettings: AssetsBalanceSettingsUseCaseProtocol = UseCasesFactory.instance.assetsBalanceSettings
    
    private let disposeBag: DisposeBag = DisposeBag()
    
    func updateAssetSettings(assets: [WalletSort.DTO.Asset]) {
        
        let settings = assets.map {DomainLayer.DTO.AssetBalanceSettings(assetId: $0.id,
                                                                        sortLevel: $0.sortLevel,
                                                                        isHidden: $0.isHidden,
                                                                        isFavorite: $0.isFavorite)}
        authorizationInteractor
            .authorizedWallet()
            .flatMap { [weak self] (wallet) -> Observable<Bool> in
                guard let self = self else { return Observable.empty() }
                return self.assetsBalanceSettings.updateAssetsSettings(by: wallet.address,
                                                                       settings: settings)
        }
        .subscribe()
        .disposed(by: disposeBag)
    }
}
