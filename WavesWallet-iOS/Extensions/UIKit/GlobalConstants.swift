//
//  GlobalConstants.swift
//  WavesWallet-iOS
//
//  Created by mefilt on 16/10/2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import WavesSDK
import Extensions

enum UIGlobalConstants {

    static let WavesTransactionFee = Money(WavesSDKConstants.WavesTransactionFeeAmount,
                                           WavesSDKConstants.WavesDecimals)

    
    static let limitPriceOrderPercent: Int = 5
    
    #if DEBUG
    static let accountNameMinLimitSymbols: Int = 2
    static let accountNameMaxLimitSymbols: Int = 24
    static let minLengthPassword: Int = 2
    static let minimumSeedLength = 10
    #else
    static let accountNameMinLimitSymbols: Int = 2
    static let accountNameMaxLimitSymbols: Int = 24
    static let minLengthPassword: Int = 6
    static let minimumSeedLength = 25
    #endif
    
    static let termsOfUse = "https://wavesplatform.com/files/docs/Waves_privacy_policy.pdf"
    static let termsOfConditions = "https://wavesplatform.com/files/docs/Waves_terms_and_conditions.pdf"
}

