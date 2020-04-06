//
//  NewAccountPasscodeInteractor.swift
//  WavesWallet-iOS
//
//  Created by Prokofev Ruslan on 19/09/2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import RxSwift
import DomainLayer
import WavesSDKExtensions
import Intercom
import DeviceKit

protocol PasscodeInteractorProtocol {

    func changePassword(wallet: DomainLayer.DTO.Wallet, passcode: String, oldPassword: String, newPassword: String) -> Observable<DomainLayer.DTO.Wallet>
    func changePasscodeByPassword(wallet: DomainLayer.DTO.Wallet, passcode: String, password: String) -> Observable<DomainLayer.DTO.Wallet>
    func changePasscode(wallet: DomainLayer.DTO.Wallet, oldPasscode: String, passcode: String) -> Observable<DomainLayer.DTO.Wallet>

    func registrationAccount(_ account: PasscodeTypes.DTO.Account, passcode: String) -> Observable<AuthorizationAuthStatus>

    func logIn(wallet: DomainLayer.DTO.Wallet, passcode: String) -> Observable<AuthorizationAuthStatus>
    func logInBiometric(wallet: DomainLayer.DTO.Wallet) -> Observable<AuthorizationAuthStatus>
    func logout(wallet: DomainLayer.DTO.Wallet) -> Observable<Bool>

    func setEnableBiometric(wallet: DomainLayer.DTO.Wallet, passcode: String, isOn: Bool) -> Observable<AuthorizationAuthStatus>
    func disabledBiometricUsingBiometric(wallet: DomainLayer.DTO.Wallet) -> Observable<AuthorizationAuthStatus>

    func verifyAccessUsingBiometric(wallet: DomainLayer.DTO.Wallet) -> Observable<AuthorizationVerifyAccessStatus>
    func verifyAccess(wallet: DomainLayer.DTO.Wallet, passcode: String) -> Observable<AuthorizationVerifyAccessStatus>
}

final class PasscodeInteractor: PasscodeInteractorProtocol {


    private let authorizationInteractor: AuthorizationUseCaseProtocol = UseCasesFactory.instance.authorization

    func changePassword(wallet: DomainLayer.DTO.Wallet, passcode: String, oldPassword: String, newPassword: String) -> Observable<DomainLayer.DTO.Wallet> {
        return authorizationInteractor
            .changePassword(wallet: wallet, passcode: passcode, oldPassword: oldPassword, newPassword: newPassword)
            .catchError(weak: self, handler: { (owner, error) -> Observable<DomainLayer.DTO.Wallet> in
                return Observable.error(error)
            })
            .subscribeOn(ConcurrentDispatchQueueScheduler(queue: DispatchQueue.global()))
            .share()
    }

    func changePasscode(wallet: DomainLayer.DTO.Wallet, oldPasscode: String, passcode: String) -> Observable<DomainLayer.DTO.Wallet> {
        return authorizationInteractor
            .changePasscode(wallet: wallet, oldPasscode: oldPasscode, passcode: passcode)
            .catchError(weak: self, handler: { (owner, error) -> Observable<DomainLayer.DTO.Wallet> in
                return Observable.error(error)
            })            
            .subscribeOn(ConcurrentDispatchQueueScheduler(queue: DispatchQueue.global()))
            .share()
    }

    func changePasscodeByPassword(wallet: DomainLayer.DTO.Wallet, passcode: String, password: String) -> Observable<DomainLayer.DTO.Wallet> {
        return authorizationInteractor
            .changePasscodeByPassword(wallet: wallet, passcode: passcode, password: password)
            .catchError(weak: self, handler: { (owner, error) -> Observable<DomainLayer.DTO.Wallet> in
                return Observable.error(error)
            })
            .subscribeOn(ConcurrentDispatchQueueScheduler(queue: DispatchQueue.global()))
            .share()
    }

    func registrationAccount(_ account: PasscodeTypes.DTO.Account, passcode: String) -> Observable<AuthorizationAuthStatus> {

        let query = DomainLayer.DTO.WalletRegistation.init(name: account.name,
                                               address: account.privateKey.address,
                                               privateKey: account.privateKey,
                                               isBackedUp: !account.needBackup,
                                               password: account.password,
                                               passcode: passcode)

        return authorizationInteractor
            .registerWallet(query)
            .flatMap({ [weak self] wallet -> Observable<AuthorizationAuthStatus> in
                guard let self = self else {  return Observable.empty() }
                return self.auth(type: .passcode(passcode),
                                 wallet: wallet)
            })
            .catchError(weak: self, handler: { (owner, error) -> Observable<AuthorizationAuthStatus> in
                return Observable.error(error)
            })
            .subscribeOn(ConcurrentDispatchQueueScheduler(queue: DispatchQueue.global()))
            .share()
    }

    func logInBiometric(wallet: DomainLayer.DTO.Wallet) -> Observable<AuthorizationAuthStatus> {
        auth(type: .biometric, wallet: wallet)
            .catchError(weak: self, handler: { (owner, error) -> Observable<AuthorizationAuthStatus> in
                return Observable.error(error)
            })
            .subscribeOn(ConcurrentDispatchQueueScheduler(queue: DispatchQueue.global()))
            .share()
    }

    func logIn(wallet: DomainLayer.DTO.Wallet, passcode: String) -> Observable<AuthorizationAuthStatus> {
        auth(type: .passcode(passcode), wallet: wallet)
            .catchError(weak: self, handler: { (owner, error) -> Observable<AuthorizationAuthStatus> in
                return Observable.error(error)
            })
            .subscribeOn(ConcurrentDispatchQueueScheduler(queue: DispatchQueue.global()))
            .share()
    }

    func verifyAccessUsingBiometric(wallet: DomainLayer.DTO.Wallet) -> Observable<AuthorizationVerifyAccessStatus> {
        return authorizationInteractor
            .verifyAccess(type: .biometric, wallet: wallet)
            .catchError(weak: self, handler: { (owner, error) -> Observable<AuthorizationVerifyAccessStatus> in
                return Observable.error(error)
            })
            .subscribeOn(ConcurrentDispatchQueueScheduler(queue: DispatchQueue.global()))
            .share()
    }

    func verifyAccess(wallet: DomainLayer.DTO.Wallet, passcode: String) -> Observable<AuthorizationVerifyAccessStatus> {
        return authorizationInteractor
            .verifyAccess(type: .passcode(passcode), wallet: wallet)
            .catchError(weak: self, handler: { (owner, error) -> Observable<AuthorizationVerifyAccessStatus> in
                return Observable.error(error)
            })
            .subscribeOn(ConcurrentDispatchQueueScheduler(queue: DispatchQueue.global()))
            .share()
    }

    func disabledBiometricUsingBiometric(wallet: DomainLayer.DTO.Wallet) -> Observable<AuthorizationAuthStatus> {
        return authorizationInteractor
            .unregisterBiometricUsingBiometric(wallet: wallet)
            .catchError(weak: self, handler: { (owner, error) -> Observable<AuthorizationAuthStatus> in
                return Observable.error(error)
            })
            .subscribeOn(ConcurrentDispatchQueueScheduler(queue: DispatchQueue.global()))
            .share()
    }

    func setEnableBiometric(wallet: DomainLayer.DTO.Wallet, passcode: String, isOn: Bool) -> Observable<AuthorizationAuthStatus> {

        var biometric: Observable<AuthorizationAuthStatus>!

        if isOn {
            biometric = authorizationInteractor.registerBiometric(wallet: wallet, passcode: passcode)
        } else {
            biometric = authorizationInteractor.unregisterBiometric(wallet: wallet, passcode: passcode)
        }

        return biometric
            .catchError(weak: self, handler: { (owner, error) -> Observable<AuthorizationAuthStatus> in
                return Observable.error(error)
            })
            .subscribeOn(ConcurrentDispatchQueueScheduler(queue: DispatchQueue.global()))
            .share()
    }

    func logout(wallet: DomainLayer.DTO.Wallet) -> Observable<Bool> {
        return authorizationInteractor.logout(wallet: wallet.publicKey)
            .map { _ in return true }
            .subscribeOn(ConcurrentDispatchQueueScheduler(queue: DispatchQueue.global()))
            .share()
    }
    
    private func auth(type: AuthorizationType,
                      wallet: DomainLayer.DTO.Wallet) -> Observable<AuthorizationAuthStatus> {
        self
            .authorizationInteractor.auth(type: type,
            wallet: wallet)
            .do(onNext: { (status) in
                switch status {
                case .completed(let wallet):
                    Intercom.registerUser(withUserId: wallet.address)
                    
                    let attributes = ICMUserAttributes()
                    attributes.userId = wallet.address
                    attributes.customAttributes = ["platform": "iOS",
                                                   "version": Bundle.main.versionAndBuild,
                                                   "device": Device.current.model ?? "",
                                                   "carrierName": UIDevice.current.carrierName,
                                                   "os": UIDevice.current.osVersion,
                                                   "deviceId": UIDevice.uuid]
                    Intercom.updateUser(attributes)
                default:
                    break
                }
            })
    }
}
    
