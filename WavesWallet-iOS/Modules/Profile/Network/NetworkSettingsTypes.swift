//
//  NetworkTypes.swift
//  WavesWallet-iOS
//
//  Created by mefilt on 22/10/2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import WavesSDKExtensions
import DomainLayer
import Extensions

enum NetworkSettingsTypes {
    enum DTO { }
}

extension NetworkSettingsTypes {

    enum Query {
        case resetEnvironmentOnDeffault
        case saveEnvironments
        case successSaveEnvironments
    }

    struct State: Mutating {
        var wallet: DomainLayer.DTO.Wallet
        var accountSettings: DomainLayer.DTO.AccountSettings?
        var environment: WalletEnvironment?
        var displayState: DisplayState
        var query: Query?
        var isValidSpam: Bool        
    }

    enum Event {
        case readyView
        case setEnvironmets(WalletEnvironment, DomainLayer.DTO.AccountSettings?, DomainLayer.DTO.AccountEnvironment?)
        case setDeffaultEnvironmet(WalletEnvironment)
        case handlerError(Error)
        case inputSpam(String?)
        case switchSpam(Bool)
        case successSave
        case tapSetDeffault
        case tapSave
        case completedQuery
    }

    struct DisplayState: Mutating {

        var spamUrl: String?
        var isSpam: Bool
        var isAppeared: Bool
        var isLoading: Bool
        var isEnabledSaveButton: Bool
        var isEnabledSetDeffaultButton: Bool
        var isEnabledSpamSwitch: Bool
        var isEnabledSpamInput: Bool
        var spamError: String?
    }
}
