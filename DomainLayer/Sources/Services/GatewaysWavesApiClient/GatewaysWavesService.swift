//
//  GatewaysWavesApiClientService.swift
//  DomainLayer
//
//  Created by rprokofev on 28.04.2020.
//  Copyright © 2020 Waves Platform. All rights reserved.
//

import Foundation
import RxSwift

public protocol GatewaysWavesService {
    
    func assetBindingsRequest(serverEnvironment: ServerEnvironment,
                              oAToken: WEOAuthTokenDTO,
                              request: AssetBindingsRequest) -> Observable<[GatewaysAssetBinding]>
    
    func withdrawalTransferBinding(serverEnvironment: ServerEnvironment,
                                   oAToken: WEOAuthTokenDTO,
                                   request: TransferBindingRequest) -> Observable<GatewaysTransferBinding>

    func depositTransferBinding(serverEnvironment: ServerEnvironment,
                                oAToken: WEOAuthTokenDTO,
                                request: TransferBindingRequest) -> Observable<GatewaysTransferBinding>
}
