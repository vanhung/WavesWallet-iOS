//
//  AuthorizationInteractor.swift
//  WavesWallet-iOS
//
//  Created by Prokofev Ruslan on 24/09/2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Extensions
import Foundation
import KeychainAccess
import LocalAuthentication
import RxSwift
import WavesSDKCrypto
import WavesSDKExtensions

private enum Constants {
    static let service = "com.wavesplatform.wallets"
}

private extension Wallet {
    init(id: String, query: WalletRegistation) {
        name = query.name
        address = query.privateKey.address
        publicKey = query.privateKey.getPublicKeyStr()
        isLoggedIn = false
        isBackedUp = query.isBackedUp
        hasBiometricEntrance = false
        self.id = id
        isNeedShowWalletCleanBanner = false
    }
}

private extension AuthorizationUseCase {
    func registerData(_ wallet: WalletRegistation) -> Observable<RegisterData> {
        return Observable.create { observer -> Disposable in

            let id = UUID().uuidString
            let seedId = UUID().uuidString
            let keyForPassword = UUID().uuidString.sha512()
            let password = wallet.password
            guard let secret: String = password.aesEncrypt(withKey: keyForPassword) else {
                observer.onError(AuthorizationUseCaseError.fail)
                return Disposables.create()
            }

            observer.onNext(RegisterData(id: id,
                                         seedId: seedId,
                                         keyForPassword: keyForPassword,
                                         password: password,
                                         secret: secret))
            observer.onCompleted()
            return Disposables.create()
        }
    }

    func changePasscodeByPasswordData(password: String, walletEncryption: DomainWalletEncryption)
        -> Observable<ChangePasscodeByPasswordData> {
        return Observable.create { observer -> Disposable in

            let keyForPassword = UUID().uuidString.sha512()
            guard let secret: String = password.aesEncrypt(withKey: keyForPassword) else {
                observer.onError(AuthorizationUseCaseError.fail)
                return Disposables.create()
            }

            observer.onNext(ChangePasscodeByPasswordData(keyForPassword: keyForPassword,
                                                         password: password,
                                                         secret: secret,
                                                         seedId: walletEncryption.seedId))

            observer.onCompleted()
            return Disposables.create()
        }
    }

    func changePasswordData(_ wallet: Wallet, password: String, walletEncryption: DomainWalletEncryption)
        -> Observable<ChangePasswordData> {
        Observable.create { observer -> Disposable in

            let keyForPassword = UUID().uuidString.sha512()
            let password = password
            guard let secret: String = password.aesEncrypt(withKey: keyForPassword) else {
                observer.onError(AuthorizationUseCaseError.fail)
                return Disposables.create()
            }

            let seedId = UUID().uuidString

            observer.onNext(ChangePasswordData(wallet: wallet,
                                               keyForPassword: keyForPassword,
                                               password: password,
                                               secret: secret,
                                               seedId: seedId,
                                               oldSeedId: walletEncryption.seedId))

            observer.onCompleted()
            return Disposables.create()
        }
    }
}

private struct ChangePasswordData {
    var wallet: Wallet
    let keyForPassword: String
    let password: String
    let secret: String
    let seedId: String
    let oldSeedId: String
}

private struct ChangePasscodeByPasswordData {
    let keyForPassword: String
    let password: String
    let secret: String
    let seedId: String
}

private struct RegisterData {
    let id: String
    let seedId: String
    let keyForPassword: String
    let password: String
    let secret: String
}

private final class SeedRepositoryMemory {
    private static var map: [String: WalletSeed] = [:]

    private let serialQueue = DispatchQueue(label: "authorization.mutex")

    func append(_ seed: WalletSeed) {
        serialQueue.sync {
            SeedRepositoryMemory.map[seed.publicKey] = seed
        }
    }

    func remove(_ publicKey: String) {
        _ = serialQueue.sync {
            SeedRepositoryMemory.map.removeValue(forKey: publicKey)
        }
    }

    func seed(_ publicKey: String) -> WalletSeed? {
        return serialQueue.sync {
            return SeedRepositoryMemory.map[publicKey]
        }
    }

    func hasSeed(_ publicKey: String) -> Bool {
        return serialQueue.sync {
            return SeedRepositoryMemory.map[publicKey] != nil
        }
    }

    func removeAll() {
        serialQueue.sync {
            SeedRepositoryMemory.map.removeAll()
        }
    }
}

final class AuthorizationUseCase: AuthorizationUseCaseProtocol {
    private let localWalletRepository: WalletsRepositoryProtocol
    private let localWalletSeedRepository: WalletSeedRepositoryProtocol
    private let remoteAuthenticationRepository: AuthenticationRepositoryProtocol
    private let accountSettingsRepository: AccountSettingsRepositoryProtocol
    private let userRepository: UserRepository

    private let analyticManager: AnalyticManagerProtocol
    private let localizable: AuthorizationInteractorLocalizableProtocol

    init(localWalletRepository: WalletsRepositoryProtocol,
         localWalletSeedRepository: WalletSeedRepositoryProtocol,
         remoteAuthenticationRepository: AuthenticationRepositoryProtocol,
         accountSettingsRepository: AccountSettingsRepositoryProtocol,
         localizable: AuthorizationInteractorLocalizableProtocol,
         analyticManager: AnalyticManagerProtocol,
         userRepository: UserRepository) {
        self.localWalletRepository = localWalletRepository
        self.localWalletSeedRepository = localWalletSeedRepository
        self.remoteAuthenticationRepository = remoteAuthenticationRepository
        self.accountSettingsRepository = accountSettingsRepository
        self.localizable = localizable
        self.analyticManager = analyticManager
        self.userRepository = userRepository
    }

    private let seedRepositoryMemory: SeedRepositoryMemory = SeedRepositoryMemory()

    func auth(type: AuthorizationType, wallet: Wallet) -> Observable<AuthorizationAuthStatus> {
        return verifyAccessWallet(type: type, wallet: wallet)
            .flatMap { [weak self] status -> Observable<AuthorizationVerifyAccessStatus> in

                guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }
                guard case let .completed(signedWallet) = status else { return Observable.just(status) }
                let wallet = signedWallet.wallet
                let seed = signedWallet.seed

                self.seedRepositoryMemory.append(seed)

                let updateUserUID = self.updateUserUID(signedWallet: signedWallet)
                let setIsLoggedIn = self.setIsLoggedIn(wallet: wallet)

                return Observable.zip(setIsLoggedIn, updateUserUID)
                    .flatMap { [weak self] wallet, uid -> Observable<AuthorizationVerifyAccessStatus> in

                        self?.analyticManager.setUID(uid: uid)
                        return Observable.just(AuthorizationVerifyAccessStatus.completed(.init(wallet: wallet, seed: seed)))
                    }
            }
            .map { (status) -> AuthorizationAuthStatus in
                switch status {
                case .detectBiometric:
                    return AuthorizationAuthStatus.detectBiometric

                case .waiting:
                    return AuthorizationAuthStatus.waiting

                case let .completed(signedWallet):
                    return AuthorizationAuthStatus.completed(signedWallet.wallet)
                }
            }.sweetDebug("auth")
    }

    func verifyAccess(type: AuthorizationType, wallet: Wallet) -> Observable<AuthorizationVerifyAccessStatus> {
        return verifyAccessWallet(type: type, wallet: wallet)
    }

    func lastWalletLoggedIn() -> Observable<Wallet?> {
        return walletsLoggedIn()
            .flatMap { wallets -> Observable<Wallet?> in
                Observable.just(wallets.first)
            }
    }

    func walletsLoggedIn() -> Observable<[Wallet]> {
        return localWalletRepository
            .wallets(specifications: .init(isLoggedIn: true))
            .catchError { [weak self] error -> Observable<[Wallet]> in
                guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }
                return Observable.error(self.handlerError(error))
            }
    }

    func hasPermissionToLoggedIn(_ wallet: Wallet) -> Observable<Bool> {
        return localWalletRepository.walletEncryption(by: wallet.publicKey)
            .flatMap { walletEncrypted -> Observable<Bool> in
                if walletEncrypted.kind.secret == nil {
                    return Observable.error(AuthorizationUseCaseError.passcodeNotCreated)
                }

                return Observable.just(true)
            }
            .catchError { [weak self] error -> Observable<Bool> in
                guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }
                return Observable.error(self.handlerError(error))
            }
    }

    func isAuthorizedWallet(_ wallet: Wallet) -> Observable<Bool> {
        return Observable.just(seedRepositoryMemory.hasSeed(wallet.publicKey))
    }

    func authorizedWallet() -> Observable<SignedWallet> {
        return lastWalletLoggedIn()
            .flatMap { [weak self] wallet -> Observable<SignedWallet> in

                guard let self = self else { return Observable.never() }
                guard let wallet = wallet else { return Observable.error(AuthorizationUseCaseError.permissionDenied) }
                guard let seed = self.seedRepositoryMemory.seed(wallet.publicKey)
                else { return Observable.error(AuthorizationUseCaseError.permissionDenied) }
                return self.signedWallet(wallet: wallet, seed: seed)
            }
    }

    func changePasscode(wallet: Wallet, oldPasscode: String, passcode: String) -> Observable<Wallet> {
        remoteAuthenticationRepository
            .changePasscode(with: wallet.id, oldPasscode: oldPasscode, passcode: passcode)
            .map { _ in wallet }
            .flatMap { [weak self] wallet -> Observable<Wallet> in
                guard let self = self else { return Observable.never() }
                return self.reRegisterBiometric(wallet: wallet, passcode: passcode)
            }
            .catchError { [weak self] error -> Observable<Wallet> in
                guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }
                return Observable.error(self.handlerError(error))
            }
    }

    func changePasscodeByPassword(wallet: Wallet, passcode: String, password: String) -> Observable<Wallet> {
        return localWalletRepository
            .walletEncryption(by: wallet.publicKey)
            .flatMap { [weak self] walletEncryption -> Observable<ChangePasscodeByPasswordData> in
                guard let self = self else { return Observable.never() }
                return self.changePasscodeByPasswordData(password: password, walletEncryption: walletEncryption)
            }
            .flatMap { [weak self] data -> Observable<ChangePasscodeByPasswordData> in

                guard let self = self else { return Observable.never() }
                return self.localWalletRepository.saveWalletEncryption(.init(publicKey: wallet.publicKey,
                                                                             kind: .passcode(secret: data.secret),
                                                                             seedId: data.seedId))
                    .map { _ in data }
            }
            .flatMap { [weak self] data -> Observable<Wallet> in

                guard let self = self else { return Observable.never() }

                return self
                    .remoteAuthenticationRepository
                    .registration(with: wallet.id,
                                  keyForPassword: data.keyForPassword,
                                  passcode: passcode)
                    .map { _ in wallet }
            }
            .flatMap { [weak self] wallet -> Observable<Wallet> in
                guard let self = self else { return Observable.never() }
                return self.reRegisterBiometric(wallet: wallet, passcode: passcode)
            }
            .catchError { [weak self] error -> Observable<Wallet> in
                guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }
                return Observable.error(self.handlerError(error))
            }
    }

    func changePassword(wallet: Wallet,
                        passcode: String,
                        oldPassword: String,
                        newPassword: String) -> Observable<Wallet> {
        return verifyAccessWalletUsingPasscode(passcode, wallet: wallet)
            .sweetDebug("Verify acccess")

            .flatMap { [weak self] _ -> Observable<DomainWalletEncryption> in
                guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }
                return self.localWalletRepository.walletEncryption(by: wallet.publicKey)
            }
            .flatMap { [weak self] walletEncryption -> Observable<(WalletSeed, ChangePasswordData)> in

                guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }
                let currentSeed = self.localWalletSeedRepository.seed(for: wallet.address,
                                                                      publicKey: wallet.publicKey,
                                                                      seedId: walletEncryption.seedId,
                                                                      password: oldPassword)

                let changeData = self.changePasswordData(wallet, password: newPassword, walletEncryption: walletEncryption)

                return Observable.zip(currentSeed, changeData)
            }
            .sweetDebug("Create ChangePasswordData")

            .flatMap { [weak self] (seed, passwordData) -> Observable<ChangePasswordData> in
                // I dont use model seed. After migration first version, seed dont have address :(
                guard let self = self else { return Observable.never() }
                return self.localWalletSeedRepository
                    .saveSeed(for: WalletSeed(publicKey: passwordData.wallet.publicKey,
                                              seed: seed.seed,
                                              address: passwordData.wallet.address),
                              seedId: passwordData.seedId,
                              password: passwordData.password)
                    .map { _ in passwordData }
            }
            .sweetDebug("Save seed")

            .flatMap { [weak self] (passwordData) -> Observable<ChangePasswordData> in

                guard let self = self else { return Observable.never() }
                return self
                    .localWalletRepository
                    .saveWalletEncryption(DomainWalletEncryption(publicKey: passwordData.wallet.publicKey,
                                                           kind: .passcode(secret: passwordData.secret),
                                                           seedId: passwordData.seedId))
                    .map { _ in passwordData }
            }
            .sweetDebug("Save secret and seedId")

            .flatMap { [weak self] passwordData -> Observable<ChangePasswordData> in
                guard let self = self else { return Observable.never() }
                return self
                    .localWalletRepository
                    .saveWallet(passwordData.wallet)
                    .map { wallet -> ChangePasswordData in
                        var newPasswordData = passwordData
                        newPasswordData.wallet = wallet
                        return newPasswordData
                    }
            }
            .sweetDebug("Save Wallet")

            .flatMap { [weak self] passwordData -> Observable<ChangePasswordData> in
                guard let self = self else { return Observable.never() }
                return self
                    .localWalletSeedRepository
                    .deleteSeed(for: passwordData.wallet.address,
                                seedId: passwordData.oldSeedId)
                    .map { _ in passwordData }
            }
            .sweetDebug("Delete old seed")

            .flatMap { [weak self] data -> Observable<Wallet> in
                guard let self = self else { return Observable.never() }
                return self
                    .remoteAuthenticationRepository
                    .registration(with: data.wallet.id,
                                  keyForPassword: data.keyForPassword,
                                  passcode: passcode)
                    .map { _ in data.wallet }
            }
            .sweetDebug("Firebase register")
            .flatMap { [weak self] wallet -> Observable<Wallet> in
                guard let self = self else { return Observable.never() }
                return self.reRegisterBiometric(wallet: wallet, passcode: passcode)
            }
            .sweetDebug("Biometric")
    }
}

// MARK: - Wallets methods

extension AuthorizationUseCase {
    func existWallet(by publicKey: String) -> Observable<Wallet> {
        return localWalletRepository
            .wallet(by: publicKey)
            .catchError { (error) -> Observable<Wallet> in
                switch error {
                case let walletError as RepositoryError:
                    switch walletError {
                    case .notFound:
                        return Observable.error(AuthorizationUseCaseError.walletNotFound)

                    default:
                        return Observable.error(AuthorizationUseCaseError.fail)
                    }
                default:
                    return Observable.error(AuthorizationUseCaseError.fail)
                }
            }
    }

    func wallets() -> Observable<[Wallet]> {
        return localWalletRepository
            .wallets()
            .catchError { [weak self] error -> Observable<[Wallet]> in
                guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }
                return Observable.error(self.handlerError(error))
            }
    }

    func registerWallet(_ registration: WalletRegistation) -> Observable<Wallet> {
        return existWallet(by: registration.privateKey.getPublicKeyStr())
            .flatMap { _ -> Observable<RegisterData> in
                Observable.error(AuthorizationUseCaseError.walletAlreadyExist)
            }
            .catchError { [weak self] error -> Observable<RegisterData> in
                guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }

                if let authError = error as? AuthorizationUseCaseError,
                    case AuthorizationUseCaseError.walletAlreadyExist = authError {
                    return Observable.error(error)
                }

                return self.registerData(registration)
            }
            .flatMap { [weak self] registerData -> Observable<(RegisterData, WalletSeed, Wallet)> in

                guard let self = self else { return Observable.never() }
                let model = Wallet(id: registerData.id, query: registration)

                let seedId = registerData.seedId

                let saveSeed = self
                    .localWalletSeedRepository
                    .saveSeed(for: .init(publicKey: registration.privateKey.getPublicKeyStr(),
                                         seed: registration.privateKey.wordsStr,
                                         address: registration.privateKey.address),
                              seedId: seedId,
                              password: registerData.password)

                return saveSeed.map { (registerData, $0, model) }
            }
            .flatMap { [weak self] data -> Observable<(RegisterData, WalletSeed, Wallet)> in

                guard let self = self else { return Observable.never() }

                let publicKey = data.1.publicKey
                let secret = data.0.secret
                let seedId = data.0.seedId

                let saveSeed = self
                    .localWalletRepository
                    .saveWalletEncryption(DomainWalletEncryption(publicKey: publicKey,
                                                           kind: .passcode(secret: secret),
                                                           seedId: seedId))
                return saveSeed.map { _ in data }
            }
            .flatMap { [weak self] (data) -> Observable<Wallet> in

                guard let self = self else { return Observable.never() }

                let id = data.2.id
                let keyForPassword = data.0.keyForPassword

                return self
                    .remoteAuthenticationRepository
                    .registration(with: id,
                                  keyForPassword: keyForPassword,
                                  passcode: registration.passcode)
                    .map { _ in data.2 }
            }
            .flatMap { [weak self] wallet -> Observable<Wallet> in
                guard let self = self else { return Observable.never() }

                // Deffault setting for account
                let settings = DomainLayer.DTO.AccountSettings(isEnabledSpam: true)
                return self.accountSettingsRepository
                    .saveAccountSettings(accountAddress: wallet.address,
                                         settings: settings)
                    .map { _ in wallet }
            }
            .flatMap { [weak self] wallet -> Observable<Wallet> in
                guard let self = self else { return Observable.never() }
                return self.localWalletRepository.saveWallet(wallet)
            }
            .catchError { [weak self] error -> Observable<Wallet> in
                guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }
                return Observable.error(self.handlerError(error))
            }
            .share()
            .subscribeOn(ConcurrentDispatchQueueScheduler(queue: DispatchQueue.global()))
    }

    func deleteWallet(_ wallet: Wallet) -> Observable<Bool> {
        let deleleteWalletSeed = localWalletRepository
            .walletEncryption(by: wallet.publicKey)
            .flatMap { [weak self] walletEncryption -> Observable<Bool> in
                guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }
                return self.localWalletSeedRepository.deleteSeed(for: wallet.address, seedId: walletEncryption.seedId)
            }

        return Observable.zip([localWalletRepository.removeWallet(wallet),
                               deleleteWalletSeed,
                               localWalletRepository.removeWalletEncryption(by: wallet.publicKey)])
            .map { _ in true }
            .catchError { [weak self] error -> Observable<Bool> in
                guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }
                return Observable.error(self.handlerError(error))
            }
    }

    func changeWallet(_ wallet: Wallet) -> Observable<Wallet> {
        return localWalletRepository
            .saveWallet(wallet)
            .catchError { [weak self] error -> Observable<Wallet> in
                guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }
                return Observable.error(self.handlerError(error))
            }
    }
}

// MARK: - Logout methods

extension AuthorizationUseCase {
    func logout() -> Observable<Wallet> {
        walletsLoggedIn().flatMap(weak: self, selector: { $0.logout })
    }

    func revokeAuth() -> Observable<Bool> {
        return Observable.create { [weak self] observer -> Disposable in

            guard let self = self else {
                observer.onError(AuthorizationUseCaseError.fail)
                return Disposables.create()
            }

            self.seedRepositoryMemory.removeAll()
            observer.onNext(true)
            observer.onCompleted()
            return Disposables.create()
        }
    }

    func logout(wallet publicKey: String) -> Observable<Wallet> {
        return Observable.create { [weak self] observer -> Disposable in

            guard let self = self else { return Disposables.create() }

            let disposable = self
                .localWalletRepository
                .wallet(by: publicKey)
                .flatMap { [weak self] wallet -> Observable<Wallet> in
                    guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }
                    let newWallet = wallet.mutate(transform: { $0.isLoggedIn = false })
                    return self
                        .localWalletRepository
                        .saveWallet(newWallet)
                }
                .flatMap { [weak self] (wallet) -> Observable<Wallet> in
                    guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }
                    return self.revokeAuth().map { _ in wallet }
                }
                .catchError { [weak self] error -> Observable<Wallet> in
                    guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }
                    return Observable.error(self.handlerError(error))
                }
                .subscribe(onNext: { completed in
                    observer.onNext(completed)
                    observer.onCompleted()
                })

            return Disposables.create([disposable])
        }
    }
}

// MARK: - Biometric methods

extension AuthorizationUseCase {
    func registerBiometric(wallet: Wallet, passcode: String) -> Observable<AuthorizationAuthStatus> {
        let auth = verifyAccessWalletUsingPasscode(passcode, wallet: wallet)
            .flatMap { [weak self] signedWallet -> Observable<AuthorizationAuthStatus> in

                guard let self = self else { return Observable.never() }

                let savePasscode = self
                    .savePasscodeInKeychain(wallet: signedWallet.wallet, passcode: passcode, localizedFallbackTitle: "")
                    .flatMap { [weak self] _ -> Observable<Wallet> in
                        guard let self = self else { return Observable.never() }
                        return self.setHasBiometricEntrance(wallet: signedWallet.wallet, hasBiometricEntrance: true)
                    }
                    .map { AuthorizationAuthStatus.completed($0) }

                return Observable.merge(.just(AuthorizationAuthStatus.detectBiometric), savePasscode)
            }

        return Observable.merge(.just(AuthorizationAuthStatus.waiting), auth)
    }

    func unregisterBiometric(wallet: Wallet, passcode: String) -> Observable<AuthorizationAuthStatus> {
        let auth = getPasswordByPasscode(passcode, wallet: wallet)
            .flatMap { [weak self] password -> Observable<SignedWallet> in
                guard let self = self else { return Observable.never() }
                return self.verifyAccessWalletUsingPassword(password, wallet: wallet)
            }
            .flatMap { [weak self] signedWallet -> Observable<AuthorizationAuthStatus> in
                guard let self = self else { return Observable.never() }
                return self.removePasscodeInKeychainWithoutContext(wallet: signedWallet.wallet)
                    .flatMap { [weak self] _ -> Observable<AuthorizationAuthStatus> in
                        guard let self = self else { return Observable.never() }

                        let removeBiometric = self
                            .setHasBiometricEntrance(wallet: signedWallet.wallet, hasBiometricEntrance: false)
                            .map { AuthorizationAuthStatus.completed($0) }

                        return Observable.merge(.just(AuthorizationAuthStatus.detectBiometric), removeBiometric)
                    }
            }

        return Observable.merge(.just(AuthorizationAuthStatus.waiting), auth)
    }

    func unregisterBiometricUsingBiometric(wallet: Wallet) -> Observable<AuthorizationAuthStatus> {
        let passcode = passcodeFromKeychain(wallet: wallet)
            .flatMap { [weak self] passcode -> Observable<AuthorizationAuthStatus> in
                guard let self = self else { return Observable.never() }
                return self.unregisterBiometric(wallet: wallet, passcode: passcode)
            }

        return Observable.merge(.just(AuthorizationAuthStatus.detectBiometric), passcode)
    }

    private func reRegisterBiometric(wallet: Wallet, passcode: String) -> Observable<Wallet> {
        if wallet.hasBiometricEntrance {
            return registerBiometric(wallet: wallet, passcode: passcode)
                .filter { status -> Bool in
                    if case .completed = status {
                        return true
                    } else {
                        return false
                    }
                }
                .flatMap { status -> Observable<Wallet> in
                    if case let .completed(wallet) = status {
                        return Observable.just(wallet)
                    }
                    return Observable.empty()
                }
                .catchError { [weak self] _ -> Observable<Wallet> in
                    guard let self = self else { return Observable.never() }
                    var newWallet = wallet
                    newWallet.hasBiometricEntrance = false
                    return self.localWalletRepository.saveWallet(newWallet)
                }
        } else {
            return Observable.just(wallet)
        }
    }
}

// MARK: - Keychain methods

private extension AuthorizationUseCase {
    private func removePasscodeInKeychain(wallet: Wallet) -> Observable<Bool> {
        return biometricAccess()
            .flatMap { [weak self] (context) -> Observable<Bool> in
                guard let self = self else { return Observable<Bool>.never() }
                return self.removePasscodeInKeychain(wallet: wallet, context: context)
            }
    }

    private func removePasscodeInKeychain(wallet: Wallet, context: LAContext) -> Observable<Bool> {
        return Observable<Bool>.create { observer -> Disposable in

            do {
                let keychain = Keychain(service: Constants.service)
                    .authenticationContext(context)
                    .accessibility(.whenUnlocked, authenticationPolicy: AuthenticationPolicy.touchIDCurrentSet)

                try keychain.remove(wallet.publicKey)

                observer.onNext(true)
                observer.onCompleted()
            } catch _ {
                observer.onError(AuthorizationUseCaseError.biometricDisable)
            }

            return Disposables.create {}
        }
    }

    private func removePasscodeInKeychainWithoutContext(wallet: Wallet) -> Observable<Bool> {
        return Observable<Bool>.create { observer -> Disposable in

            do {
                let keychain = Keychain(service: Constants.service)
                    .accessibility(.whenUnlocked, authenticationPolicy: AuthenticationPolicy.touchIDCurrentSet)

                try keychain.remove(wallet.publicKey)

                observer.onNext(true)
                observer.onCompleted()
            } catch _ {
                observer.onError(AuthorizationUseCaseError.biometricDisable)
            }

            return Disposables.create {}
        }
    }

    private func biometricAccess(localizedFallbackTitle: String? = nil) -> Observable<LAContext> {
        return Observable<LAContext>.create { [weak self] observer -> Disposable in

            guard let self = self else {
                observer.onError(AuthorizationUseCaseError.fail)
                return Disposables.create()
            }

            let context = LAContext()

            context.localizedFallbackTitle = localizedFallbackTitle ?? self.localizable.fallbackTitle
            context.localizedCancelTitle = self.localizable.cancelTitle

            var error: NSError?
            if context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                context.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics,
                                       localizedReason: self.localizable.readFromkeychain,
                                       reply:
                                       { _, error in

                                           if let error = error {
                                               context.invalidate()
                                               if let error = error as? LAError {
                                                   SweetLogger
                                                       .error("biometricDisable \(error.code) \(error.localizedDescription)")
                                                   observer.onError(error.authorizationUseCaseError)
                                               } else {
                                                   SweetLogger.error("biometricDisable Not Found \(error)")
                                                   observer.onError(AuthorizationUseCaseError.biometricDisable)
                                               }

                                           } else {
                                               observer.onNext(context)
                                               observer.onCompleted()
                                           }
                })

            } else {
                context.invalidate()
                if let error = error as? LAError {
                    SweetLogger.error("biometricDisable \(error.code) \(error.localizedDescription)")
                    observer.onError(error.authorizationUseCaseError)
                } else {
                    SweetLogger.error("canEvaluatePolicy false AuthorizationUseCaseError.biometricDisable")
                    observer.onError(AuthorizationUseCaseError.biometricDisable)
                }
            }

            return Disposables.create {
                context.invalidate()
            }
        }
    }

    private func savePasscodeInKeychain(wallet: Wallet, passcode: String, localizedFallbackTitle: String?) -> Observable<Bool> {
        return biometricAccess(localizedFallbackTitle: localizedFallbackTitle)
            .flatMap { [weak self] (_) -> Observable<Bool> in
                guard let self = self else { return Observable<Bool>.never() }
                return self.savePasscodeInKeychain(wallet: wallet, passcode: passcode)
            }
    }

    private func savePasscodeInKeychain(wallet: Wallet, passcode: String) -> Observable<Bool> {
        return Observable<Bool>.create { [weak self] observer -> Disposable in

            guard let self = self else {
                observer.onError(AuthorizationUseCaseError.fail)
                return Disposables.create()
            }

            let keychain = Keychain(service: Constants.service)
                .authenticationPrompt(self.localizable.saveInkeychain)
                .accessibility(.whenUnlocked, authenticationPolicy: AuthenticationPolicy.touchIDCurrentSet)

            do {
                try keychain.remove(wallet.publicKey)
                try keychain.set(passcode, key: wallet.publicKey)
                observer.onNext(true)

            } catch {
                if error is AuthorizationUseCaseError {
                    observer.onError(error)
                } else {
                    observer.onError(AuthorizationUseCaseError.biometricDisable)
                }
            }

            return Disposables.create {}
        }
    }

    private func passcodeFromKeychain(wallet: Wallet) -> Observable<String> {
        return biometricAccess()
            .flatMap { [weak self] (context) -> Observable<String> in
                guard let self = self else { return Observable<String>.never() }
                return self.passcodeFromKeychain(wallet: wallet, context: context)
            }
    }

    private func passcodeFromKeychain(wallet: Wallet, context: LAContext) -> Observable<String> {
        return Observable<String>.create { [weak self] observer -> Disposable in

            guard let self = self else {
                observer.onError(AuthorizationUseCaseError.fail)
                return Disposables.create()
            }

            let keychain = Keychain(service: Constants.service)
                .authenticationContext(context)
                .authenticationPrompt(self.localizable.readFromkeychain)
                .accessibility(.whenUnlocked, authenticationPolicy: AuthenticationPolicy.touchIDCurrentSet)

            do {
                guard let passcode = try keychain.get(wallet.publicKey) else {
                    throw AuthorizationUseCaseError.biometricDisable
                }

                observer.onNext(passcode)
                observer.onCompleted()
            } catch {
                if error is AuthorizationUseCaseError {
                    observer.onError(error)
                } else {
                    observer.onError(AuthorizationUseCaseError.permissionDenied)
                }
            }

            return Disposables.create {}
        }
    }
}

// MARK: - Auth methods

private extension AuthorizationUseCase {
    private func verifyAccessWallet(type: AuthorizationType, wallet: Wallet) -> Observable<AuthorizationVerifyAccessStatus> {
        switch type {
        case let .passcode(passcode):

            let remote = verifyAccessWalletUsingPasscode(passcode, wallet: wallet)
                .map { AuthorizationVerifyAccessStatus.completed($0) }

            return Observable.merge(Observable.just(AuthorizationVerifyAccessStatus.waiting), remote)

        case let .password(password):

            let remote = verifyAccessWalletUsingPassword(password, wallet: wallet)
                .map { AuthorizationVerifyAccessStatus.completed($0) }

            return Observable.merge(Observable.just(AuthorizationVerifyAccessStatus.waiting), remote)

        case .biometric:
            return verifyAccessWalletUsingBiometric(wallet: wallet)
        }
    }

    private func verifyAccessWalletUsingBiometric(wallet: Wallet) -> Observable<AuthorizationVerifyAccessStatus> {
        let auth = passcodeFromKeychain(wallet: wallet)
            .flatMap { [weak self] passcode -> Observable<AuthorizationVerifyAccessStatus> in
                guard let self = self else { return Observable.never() }
                let verify = self
                    .verifyAccessWalletUsingPasscode(passcode, wallet: wallet)
                    .map { AuthorizationVerifyAccessStatus.completed($0) }

                return Observable.merge(Observable.just(AuthorizationVerifyAccessStatus.waiting), verify)
            }
            .catchError { [weak self] error -> Observable<AuthorizationVerifyAccessStatus> in
                guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }

                if let authError = error as? AuthorizationUseCaseError,
                    authError == AuthorizationUseCaseError.biometricDisable {
                    var newWallet = wallet
                    newWallet.hasBiometricEntrance = false
                    return self
                        .localWalletRepository
                        .saveWallet(newWallet)
                        .flatMap { [weak self] _ -> Observable<AuthorizationVerifyAccessStatus> in
                            guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }
                            return Observable.error(self.handlerError(error))
                        }
                }
                return Observable.error(self.handlerError(error))
            }

        return Observable.merge(Observable.just(AuthorizationVerifyAccessStatus.detectBiometric), auth)
    }

    private func verifyAccessWalletUsingPasscode(_ passcode: String, wallet: Wallet) -> Observable<SignedWallet> {
        return getPasswordByPasscode(passcode, wallet: wallet)
            .flatMap { [weak self] password -> Observable<SignedWallet> in
                guard let self = self else { return Observable.empty() }
                return self.verifyAccessWalletUsingPassword(password, wallet: wallet)
            }
            .catchError { [weak self] error -> Observable<SignedWallet> in
                guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }
                return Observable.error(self.handlerError(error))
            }
            .catchError { [weak self] (error) -> Observable<SignedWallet> in
                guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }

                if let authError = error as? AuthorizationUseCaseError, authError == .attemptsEnded {
                    return self
                        .localWalletRepository
                        .walletEncryption(by: wallet.publicKey)
                        .flatMap { [weak self] (walletEnc) -> Observable<SignedWallet> in

                            guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }

                            var newWalletEnc = walletEnc
                            newWalletEnc.kind = .none

                            return self.localWalletRepository.saveWalletEncryption(newWalletEnc)
                                .flatMap { _ -> Observable<SignedWallet> in
                                    Observable.error(error)
                                }
                        }
                } else {
                    return Observable.error(error)
                }
            }
    }

    private func verifyAccessWalletUsingPassword(_ password: String, wallet: Wallet) -> Observable<SignedWallet> {
        return localWalletRepository
            .walletEncryption(by: wallet.publicKey)
            .flatMap { [weak self] walletEncryption -> Observable<WalletSeed> in
                guard let self = self else { return Observable.empty() }
                return self
                    .localWalletSeedRepository
                    .seed(for: wallet.address,
                          publicKey: wallet.publicKey,
                          seedId: walletEncryption.seedId,
                          password: password)
            }
            .flatMap { [weak self] seed -> Observable<SignedWallet> in
                guard let self = self else { return Observable.empty() }
                return self.signedWallet(wallet: wallet, seed: seed)
            }
            .catchError { [weak self] error -> Observable<SignedWallet> in
                guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }
                return Observable.error(self.handlerError(error))
            }
    }
}

// MARK: - Assistants methods

fileprivate extension AuthorizationUseCase {
    func signedWallet(wallet: Wallet, seed: WalletSeed) -> Observable<SignedWallet> {
        return Observable.create { observer -> Disposable in
            let signedWallet = SignedWallet(wallet: wallet, seed: seed)
            observer.onNext(signedWallet)
            return Disposables.create()
        }
    }

    private func getPasswordByPasscode(_ passcode: String, wallet: Wallet) -> Observable<String> {
        return remoteAuthenticationRepository
            .auth(with: wallet.id, passcode: passcode)
            .flatMap { [weak self] keyForPassword -> Observable<(String, DomainWalletEncryption)> in
                guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }
                return self.localWalletRepository.walletEncryption(by: wallet.publicKey).map { (keyForPassword, $0) }
            }
            .flatMap { data -> Observable<String> in

                let keyForPassword = data.0
                let walletEncryption = data.1

                guard let secret = walletEncryption.kind.secret
                else { return Observable.error(AuthorizationUseCaseError.passcodeNotCreated) }

                guard let password: String = secret.aesDecrypt(withKey: keyForPassword)
                else { return Observable.error(AuthorizationUseCaseError.fail) }
                return Observable.just(password)
            }
            .catchError { [weak self] error -> Observable<String> in
                guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }
                return Observable.error(self.handlerError(error))
            }
    }

    private func setIsLoggedIn(wallet: Wallet, isLoggedIn: Bool = true) -> Observable<Wallet> {
        return localWalletRepository
            .wallets(specifications: .init(isLoggedIn: true))
            .flatMap { [weak self] wallets -> Observable<Wallet> in
                guard let self = self else { return Observable.empty() }

                var newWallets = wallets.mutate(transform: { wallet in
                    wallet.isLoggedIn = false
                })
                let currentWallet = wallet.mutate(transform: { wallet in
                    wallet.isLoggedIn = isLoggedIn
                })

                newWallets.append(currentWallet)

                return self
                    .localWalletRepository
                    .saveWallets(newWallets)
                    .map { _ in currentWallet }
            }
            .catchError { [weak self] error -> Observable<Wallet> in
                guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }
                return Observable.error(self.handlerError(error))
            }
    }

    private func setHasBiometricEntrance(wallet: Wallet, hasBiometricEntrance: Bool = true) -> Observable<Wallet> {
        let newWallet = wallet.mutate(transform: { $0.hasBiometricEntrance = hasBiometricEntrance })

        return localWalletRepository
            .saveWallet(newWallet)
            .map { _ in newWallet }
    }

    private func logout(_ wallets: [Wallet]) -> Observable<Wallet> {
        return Observable.merge(wallets.map { logout(wallet: $0.publicKey) })
    }

    private func handlerError(_ error: Error) -> Error {
        logEvent(error)
        switch error {
        case let error as AuthenticationRepositoryError:
            switch error {
            case .attemptsEnded:
                return AuthorizationUseCaseError.attemptsEnded

            case .fail:
                return AuthorizationUseCaseError.fail

            case .passcodeIncorrect:
                return AuthorizationUseCaseError.passcodeIncorrect

            case .permissionDenied:
                return AuthorizationUseCaseError.permissionDenied
            }

        case let error as WalletSeedRepositoryError:
            switch error {
            case .permissionDenied:
                return AuthorizationUseCaseError.passwordIncorrect

            default:
                return AuthorizationUseCaseError.fail
            }

        case let error as AuthorizationUseCaseError:
            return error

        default:
            break
        }

        return error
    }

    // We have problem with to auth by passcode
    private func logEvent(_ error: Error) {
        switch error {
        case let error as AuthenticationRepositoryError:
            switch error {
            case .attemptsEnded:
                SweetLogger.error("AuthorizationUseCaseError.attemptsEnded")
            case .fail:
                SweetLogger.error("AuthorizationUseCaseError.fail")

            case .passcodeIncorrect:
                SweetLogger.error("AuthorizationUseCaseError.passcodeIncorrect")

            case .permissionDenied:
                SweetLogger.error("AuthorizationUseCaseError.permissionDenied")
            }

        case let error as WalletSeedRepositoryError:
            switch error {
            case .permissionDenied:
                SweetLogger.error("AuthorizationUseCaseError.passwordIncorrect")
            default:
                SweetLogger.error("AuthorizationUseCaseError.fail")
            }

        case let error as AuthorizationUseCaseError:
            switch error {
            case .fail:
                SweetLogger.error("AuthorizationUseCaseError.fail")
            case .walletAlreadyExist:
                SweetLogger.error("AuthorizationUseCaseError.walletAlreadyExist")
            case .walletNotFound:
                SweetLogger.error("AuthorizationUseCaseError.walletNotFound")
            case .passcodeNotCreated:
                SweetLogger.error("AuthorizationUseCaseError.passcodeNotCreated")
            case .passcodeIncorrect:
                SweetLogger.error("AuthorizationUseCaseError.passcodeIncorrect")
            case .passwordIncorrect:
                SweetLogger.error("AuthorizationUseCaseError.passwordIncorrect")
            case .permissionDenied:
                SweetLogger.error("AuthorizationUseCaseError.permissionDenied")
            case .attemptsEnded:
                SweetLogger.error("AuthorizationUseCaseError.attemptsEnded")
            case .biometricDisable:
                SweetLogger.error("AuthorizationUseCaseError.biometricDisable")
            case .biometricUserCancel:
                SweetLogger.error("AuthorizationUseCaseError.biometricUserCancel")
            case .biometricLockout:
                SweetLogger.error("AuthorizationUseCaseError.biometricLockout")
            case .biometricUserFallback:
                SweetLogger.error("AuthorizationUseCaseError.biometricUserFallback")
            }
        default:
            break
        }
    }
}

extension LAError {
    var authorizationUseCaseError: AuthorizationUseCaseError {
        switch self {
        case LAError.userCancel,
             LAError.systemCancel,
             LAError.appCancel,
             LAError.authenticationFailed:
            return AuthorizationUseCaseError.biometricUserCancel

        case LAError.biometryLockout:
            return AuthorizationUseCaseError.biometricLockout

        case LAError.userFallback:
            return AuthorizationUseCaseError.biometricUserFallback

        case LAError.passcodeNotSet:
            return AuthorizationUseCaseError.biometricDisable

        default:
            return AuthorizationUseCaseError.biometricDisable
        }
    }
}

private extension AuthorizationUseCase {
    func updateUserUID(signedWallet: SignedWallet) -> Observable<String> {
        return userRepository.createNewUserId(wallet: signedWallet)
            .flatMap { [weak self] uid -> Observable<String> in
                guard let self = self else { return Observable.never() }
                return self.userRepository.associateUserIdWithUser(wallet: signedWallet, uid: uid)
            }
    }
}
