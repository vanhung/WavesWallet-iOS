//
//  NewAccountPasscodeTypes.swift
//  WavesWallet-iOS
//
//  Created by Prokofev Ruslan on 19/09/2018.
//  Copyright © 2018 Waves Platform. All rights reserved.
//

import Foundation

enum PasscodeTypes {
    enum DTO { }
}

extension PasscodeTypes.DTO {
    
    enum Kind {
        case registration(Account)
        case logIn(DomainLayer.DTO.Wallet)
    }

    struct Account: Hashable {
        let privateKey: PrivateKeyAccount
        let password: String
        let name: String
        let needBackup: Bool
    }
}

extension PasscodeTypes {

    enum PasscodeKind: Hashable {
        case newPasscode
        case repeatPasscode
        case enterPasscode
    }

    struct State: Mutating {

        enum Action {
            case registration
            case logIn
            case logInBiometric
            case logout
        }

        var displayState: DisplayState
        var hasBackButton: Bool
        var kind: PasscodeTypes.DTO.Kind
        var action: Action?
        var numbers: [PasscodeKind: [Int]]
        var passcode: String        
    }

    enum Event {
        case completedLogout
        case completedRegistration(DomainLayer.DTO.Wallet)
        case completedLogIn(DomainLayer.DTO.Wallet)
        case tapLogInByPassword
        case handlerError(PasscodeInteractorError)
        case tapBack
        case tapLogoutButton
        case tapBiometricButton
        case completedInputNumbers([Int])
        case viewDidAppear
    }

    struct DisplayState: Mutating {

        enum Error {
            case incorrectPasscode
        }

        var kind: PasscodeKind
        var numbers: [Int]
        var isLoading: Bool
        var isHiddenBackButton: Bool
        var isHiddenLogInByPassword: Bool
        var isHiddenLogoutButton: Bool
        var isHiddenBiometricButton: Bool
        var error: Error?
        var titleLabel: String
        var detailLabel: String?
    }
}