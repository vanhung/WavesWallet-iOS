//
//  AuthorizationUseCaseProtocol.swift
//  WavesWallet-iOS
//
//  Created by Prokofev Ruslan on 09/10/2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import RxSwift

public enum AuthorizationType {
    case passcode(String)
    // The password by format sha512
    case password(String)
    case biometric
}

public enum AuthorizationUseCaseError: Error {
    case fail
    case walletAlreadyExist
    case walletNotFound
    case passcodeNotCreated
    case passcodeIncorrect
    case passwordIncorrect
    case permissionDenied
    case attemptsEnded
    case biometricDisable
    case biometricUserCancel
    case biometricLockout
    case biometricUserFallback
}

public enum AuthorizationAuthStatus {
    case detectBiometric
    case waiting
    case completed(DomainLayer.DTO.Wallet)
}

public enum AuthorizationVerifyAccessStatus {
    case detectBiometric
    case waiting
    case completed(DomainLayer.DTO.SignedWallet)
}

public protocol AuthorizationInteractorLocalizableProtocol {
    var fallbackTitle: String { get }
    var cancelTitle: String { get }
    var readFromkeychain: String { get }
    var saveInkeychain: String { get }
}

public protocol AuthorizationUseCaseProtocol {

    func existWallet(by publicKey: String) -> Observable<DomainLayer.DTO.Wallet>
    func wallets() -> Observable<[DomainLayer.DTO.Wallet]>
    func registerWallet(_ wallet: DomainLayer.DTO.WalletRegistation) -> Observable<DomainLayer.DTO.Wallet>
    func deleteWallet(_ wallet: DomainLayer.DTO.Wallet) -> Observable<Bool>
    func changeWallet(_ wallet: DomainLayer.DTO.Wallet) -> Observable<DomainLayer.DTO.Wallet>

    func lastWalletLoggedIn() -> Observable<DomainLayer.DTO.Wallet?>
    func walletsLoggedIn() -> Observable<[DomainLayer.DTO.Wallet]>

    //passcodeNotCreated or permissionDenied
    func hasPermissionToLoggedIn(_ wallet: DomainLayer.DTO.Wallet) -> Observable<Bool>

    // Return AuthorizationUseCaseError permissionDenied
    func authorizedWallet() -> Observable<DomainLayer.DTO.SignedWallet>
    func isAuthorizedWallet(_ wallet: DomainLayer.DTO.Wallet) -> Observable<Bool>

    // Return AuthorizationUseCaseError
    func auth(type: AuthorizationType, wallet: DomainLayer.DTO.Wallet) -> Observable<AuthorizationAuthStatus>
    func verifyAccess(type: AuthorizationType, wallet: DomainLayer.DTO.Wallet) -> Observable<AuthorizationVerifyAccessStatus>

    func registerBiometric(wallet: DomainLayer.DTO.Wallet, passcode: String) -> Observable<AuthorizationAuthStatus>
    func unregisterBiometric(wallet: DomainLayer.DTO.Wallet, passcode: String) -> Observable<AuthorizationAuthStatus>
    func unregisterBiometricUsingBiometric(wallet: DomainLayer.DTO.Wallet) -> Observable<AuthorizationAuthStatus>

    func logout(wallet publicKey: String) -> Observable<DomainLayer.DTO.Wallet>
    func logout() -> Observable<DomainLayer.DTO.Wallet>
    func revokeAuth() -> Observable<Bool>

    func changePasscode(wallet: DomainLayer.DTO.Wallet, oldPasscode: String, passcode: String) -> Observable<DomainLayer.DTO.Wallet>
    func changePasscodeByPassword(wallet: DomainLayer.DTO.Wallet, passcode: String, password: String) -> Observable<DomainLayer.DTO.Wallet>

    func changePassword(wallet: DomainLayer.DTO.Wallet, passcode: String, oldPassword: String, newPassword: String) -> Observable<DomainLayer.DTO.Wallet>
}
