//
//  ReceiveCryptocurrencyInteractor.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 10/5/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import RxSwift
import WavesSDK
import DomainLayer
import Extensions

final class ReceiveCryptocurrencyInteractor: ReceiveCryptocurrencyInteractorProtocol {
    
    private let auth: AuthorizationUseCaseProtocol = UseCasesFactory.instance.authorization
    private let coinomatRepository = UseCasesFactory.instance.repositories.coinomatRepository
    private let gatewayRepository = UseCasesFactory.instance.repositories.gatewayRepository

    func generateAddress(asset: DomainLayer.DTO.Asset) -> Observable<ResponseType<ReceiveCryptocurrency.DTO.DisplayInfo>> {
        auth.authorizedWallet()
            .flatMap{ [weak self] wallet -> Observable<ResponseType<ReceiveCryptocurrency.DTO.DisplayInfo>> in
          
            guard let self = self, let gatewayType = asset.gatewayType else { return Observable.empty() }
            
            switch gatewayType {
            case .gateway:
                return self.gatewayRepository.startDepositProcess(address: wallet.address, asset: asset)
                    .map { startDeposit -> ResponseType<ReceiveCryptocurrency.DTO.DisplayInfo> in
                        
                        let displayInfo = ReceiveCryptocurrency.DTO.DisplayInfo(address: startDeposit.address,
                                                                                assetName: asset.displayName,
                                                                                assetShort: asset.ticker ?? "",
                                                                                minAmount: startDeposit.minAmount,
                                                                                icon: asset.iconLogo)
                        
                        return ResponseType(output: displayInfo, error: nil)
                    }
                
            case .coinomat:
                guard let currencyFrom = asset.gatewayId,
                    let currencyTo = asset.wavesId else { return Observable.empty() }
                
                let tunnel = self.coinomatRepository.tunnelInfo(asset: asset,
                                                                currencyFrom: currencyFrom,
                                                                currencyTo: currencyTo,
                                                                walletTo: wallet.address)
                
                let rate = self.coinomatRepository.getRate(asset: asset)
                return Observable.zip(tunnel, rate)
                    .flatMap { tunnel, rate -> Observable<ResponseType<ReceiveCryptocurrency.DTO.DisplayInfo>> in
                        
                        let displayInfo = ReceiveCryptocurrency.DTO.DisplayInfo(address: tunnel.address,
                                                                                assetName: asset.displayName,
                                                                                assetShort: currencyFrom,
                                                                                minAmount: tunnel.min,
                                                                                icon: asset.iconLogo)
                        return Observable.just(ResponseType(output: displayInfo, error: nil))
                    }
            }
        }
        .catchError { error -> Observable<ResponseType<ReceiveCryptocurrency.DTO.DisplayInfo>> in
            if let networkError = error as? NetworkError {
                return Observable.just(ResponseType(output: nil, error: networkError))
            }
            
            return Observable.just(ResponseType(output: nil, error: NetworkError.error(by: error)))
        }
    }
}
