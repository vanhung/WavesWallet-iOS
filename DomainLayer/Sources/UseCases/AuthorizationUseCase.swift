//
//  AuthorizationInteractor.swift
//  WavesWallet-iOS
//
//  Created by Prokofev Ruslan on 24/09/2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import RxSwift
import KeychainAccess
import LocalAuthentication
import WavesSDKExtensions
import WavesSDKCrypto
import Extensions

private enum Constants {
    static let service = "com.wavesplatform.wallets"
}

private extension DomainLayer.DTO.Wallet {

    init(id: String, query: DomainLayer.DTO.WalletRegistation) {

        self.name = query.name
        self.address = query.privateKey.address
        self.publicKey = query.privateKey.getPublicKeyStr()
        self.isLoggedIn = false
        self.isBackedUp = query.isBackedUp
        self.hasBiometricEntrance = false
        self.id = id
        self.isNeedShowWalletCleanBanner = false
    }
}

private extension AuthorizationUseCase {

    func registerData(_ wallet: DomainLayer.DTO.WalletRegistation) -> Observable<RegisterData> {

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

    func changePasscodeByPasswordData(_ wallet: DomainLayer.DTO.Wallet, password: String, walletEncryption: DomainLayer.DTO.WalletEncryption) -> Observable<ChangePasscodeByPasswordData> {

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


    func changePasswordData(_ wallet: DomainLayer.DTO.Wallet, password: String, walletEncryption: DomainLayer.DTO.WalletEncryption) -> Observable<ChangePasswordData> {

        return Observable.create { observer -> Disposable in

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
    var wallet: DomainLayer.DTO.Wallet
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

    private static var map: [String: DomainLayer.DTO.WalletSeed] = .init()
    
    private let serialQueue = DispatchQueue(label: "authorization.mutex")

    func append(_ seed: DomainLayer.DTO.WalletSeed) {
        serialQueue.sync {
            SeedRepositoryMemory.map[seed.publicKey] = seed
        }
    }

    func remove(_ publicKey: String) {
        _ = serialQueue.sync {
            SeedRepositoryMemory.map.removeValue(forKey: publicKey)
        }
    }

    func seed(_ publicKey: String) -> DomainLayer.DTO.WalletSeed? {
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

    private let analyticManager: AnalyticManagerProtocol
    private let localizable: AuthorizationInteractorLocalizableProtocol

    init(localWalletRepository: WalletsRepositoryProtocol,
         localWalletSeedRepository: WalletSeedRepositoryProtocol,
         remoteAuthenticationRepository: AuthenticationRepositoryProtocol,
         accountSettingsRepository: AccountSettingsRepositoryProtocol,
         localizable: AuthorizationInteractorLocalizableProtocol,
         analyticManager: AnalyticManagerProtocol) {

        self.localWalletRepository = localWalletRepository
        self.localWalletSeedRepository = localWalletSeedRepository
        self.remoteAuthenticationRepository = remoteAuthenticationRepository
        self.accountSettingsRepository = accountSettingsRepository
        self.localizable = localizable
        self.analyticManager = analyticManager
    }
    
    private let seedRepositoryMemory: SeedRepositoryMemory = SeedRepositoryMemory()

    func auth(type: AuthorizationType, wallet: DomainLayer.DTO.Wallet) -> Observable<AuthorizationAuthStatus> {
        return verifyAccessWallet(type: type, wallet: wallet)
            .flatMap({ [weak self] status -> Observable<AuthorizationVerifyAccessStatus> in

                guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }
                guard case .completed(let signedWallet) = status else { return Observable.just(status) }
                let wallet = signedWallet.wallet
                let seed = signedWallet.seed

                self.seedRepositoryMemory.append(seed)
                
                let auuidBytes = WavesCrypto.shared.blake2b256(input: wallet.address.toBytes)
                let auuid = WavesCrypto.shared.base64encode(input: auuidBytes)
                
                self.analyticManager.setAUUID(auuid)
                
                return self
                    .setIsLoggedIn(wallet: wallet)
                    .flatMap { wallet -> Observable<AuthorizationVerifyAccessStatus> in
                        
                        return Observable.just(AuthorizationVerifyAccessStatus.completed(.init(wallet: wallet, seed: seed)))
                    }
            })
            .map({ (status) -> AuthorizationAuthStatus in
                switch status {
                    case .detectBiometric:
                        return AuthorizationAuthStatus.detectBiometric

                    case .waiting:
                        return AuthorizationAuthStatus.waiting

                    case .completed(let signedWallet):
                        return AuthorizationAuthStatus.completed(signedWallet.wallet)
                    }
            }).sweetDebug("auth")
    }


    func verifyAccess(type: AuthorizationType, wallet: DomainLayer.DTO.Wallet) -> Observable<AuthorizationVerifyAccessStatus> {
        return verifyAccessWallet(type: type, wallet: wallet)
    }

    func lastWalletLoggedIn() -> Observable<DomainLayer.DTO.Wallet?> {
        return walletsLoggedIn()
            .flatMap({ wallets -> Observable<DomainLayer.DTO.Wallet?> in
                return Observable.just(wallets.first)
            })
    }

    func walletsLoggedIn() -> Observable<[DomainLayer.DTO.Wallet]> {
        return localWalletRepository
            .wallets(specifications: .init(isLoggedIn: true))
            .catchError({ [weak self] error -> Observable<[DomainLayer.DTO.Wallet]> in
                guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }
                return Observable.error(self.handlerError(error))
            })
    }

    func hasPermissionToLoggedIn(_ wallet: DomainLayer.DTO.Wallet) -> Observable<Bool> {
        return self.localWalletRepository.walletEncryption(by: wallet.publicKey)
            .flatMap { walletEncrypted -> Observable<Bool> in
                if walletEncrypted.kind.secret == nil {
                    return Observable.error(AuthorizationUseCaseError.passcodeNotCreated)
                }

                return Observable.just(true)
            }
            .catchError({ [weak self] error -> Observable<Bool> in
                guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }
                return Observable.error(self.handlerError(error))
            })
    }

    func isAuthorizedWallet(_ wallet: DomainLayer.DTO.Wallet) -> Observable<Bool> {
        return Observable.just(seedRepositoryMemory.hasSeed(wallet.publicKey))
    }

    func authorizedWallet() -> Observable<DomainLayer.DTO.SignedWallet> {
        return lastWalletLoggedIn()
            .flatMap({ [weak self] wallet -> Observable<DomainLayer.DTO.SignedWallet> in

                guard let self = self else { return Observable.never() }
                guard let wallet = wallet else { return Observable.error(AuthorizationUseCaseError.permissionDenied) }
                guard let seed = self.seedRepositoryMemory.seed(wallet.publicKey) else { return Observable.error(AuthorizationUseCaseError.permissionDenied) }
                return self.signedWallet(wallet: wallet, seed: seed)
            })
    }

    func changePasscode(wallet: DomainLayer.DTO.Wallet, oldPasscode: String, passcode: String) -> Observable<DomainLayer.DTO.Wallet> {
        return remoteAuthenticationRepository
            .changePasscode(with: wallet.id, oldPasscode: oldPasscode, passcode: passcode)
            .map { _ in wallet }
            .flatMap({ [weak self] wallet -> Observable<DomainLayer.DTO.Wallet> in
                guard let self = self else { return Observable.never() }
                return self.reRegisterBiometric(wallet: wallet, passcode: passcode)
            })
            .catchError({ [weak self] error -> Observable<DomainLayer.DTO.Wallet> in
                guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }
                return Observable.error(self.handlerError(error))
            })
    }

    func changePasscodeByPassword(wallet: DomainLayer.DTO.Wallet, passcode: String, password: String) -> Observable<DomainLayer.DTO.Wallet> {

        return self.localWalletRepository
            .walletEncryption(by: wallet.publicKey)
            .flatMap({ [weak self] walletEncryption -> Observable<ChangePasscodeByPasswordData> in
                guard let self = self else { return Observable.never() }
                return self.changePasscodeByPasswordData(wallet, password: password, walletEncryption: walletEncryption)
            })
            .flatMap({ [weak self] data -> Observable<ChangePasscodeByPasswordData> in

                guard let self = self else { return Observable.never() }
                return self.localWalletRepository.saveWalletEncryption(.init(publicKey: wallet.publicKey,
                                                                              kind: .passcode(secret: data.secret),
                                                                              seedId: data.seedId))
                    .map { _ in data }
            })
            .flatMap({ [weak self] data -> Observable<DomainLayer.DTO.Wallet> in

                guard let self = self else { return Observable.never() }

                return self
                    .remoteAuthenticationRepository
                    .registration(with: wallet.id,
                                  keyForPassword: data.keyForPassword,
                                  passcode: passcode)
                    .map { _ in wallet }
            })
            .flatMap({ [weak self] wallet -> Observable<DomainLayer.DTO.Wallet> in
                guard let self = self else { return Observable.never() }
                return self.reRegisterBiometric(wallet: wallet, passcode: passcode)
            })
            .catchError({ [weak self] error -> Observable<DomainLayer.DTO.Wallet> in
                guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }
                return Observable.error(self.handlerError(error))
            })
    }

    func changePassword(wallet: DomainLayer.DTO.Wallet,
                        passcode: String,
                        oldPassword: String,
                        newPassword: String) -> Observable<DomainLayer.DTO.Wallet> {

        return self.verifyAccessWalletUsingPasscode(passcode, wallet: wallet)
            .sweetDebug("Verify acccess")

            .flatMap({ [weak self] _ -> Observable<DomainLayer.DTO.WalletEncryption> in
                guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }
                return self.localWalletRepository.walletEncryption(by: wallet.publicKey)
            })
            .flatMap({ [weak self] walletEncryption -> Observable<(DomainLayer.DTO.WalletSeed, ChangePasswordData)> in

                guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }
                let currentSeed = self.localWalletSeedRepository.seed(for: wallet.address,
                                                                       publicKey: wallet.publicKey,
                                                                       seedId: walletEncryption.seedId,
                                                                       password: oldPassword)

                let changeData = self.changePasswordData(wallet, password: newPassword, walletEncryption: walletEncryption)

                return Observable.zip(currentSeed, changeData)
            })
            .sweetDebug("Create ChangePasswordData")

            .flatMap { [weak self] (seed, passwordData) -> Observable<ChangePasswordData> in
                //I dont use model seed. After migration first version, seed dont have address :(
                guard let self = self else { return Observable.never() }
                return self.localWalletSeedRepository
                    .saveSeed(for: DomainLayer.DTO.WalletSeed(publicKey: passwordData.wallet.publicKey,
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
                    .saveWalletEncryption(DomainLayer.DTO.WalletEncryption(publicKey: passwordData.wallet.publicKey,
                                                                           kind: .passcode(secret: passwordData.secret),
                                                                           seedId: passwordData.seedId))
                    .map { _ in passwordData }
            }
            .sweetDebug("Save secret and seedId")

            .flatMap({ [weak self] passwordData -> Observable<ChangePasswordData> in
                guard let self = self else { return Observable.never() }
                return self
                    .localWalletRepository
                    .saveWallet(passwordData.wallet)
                    .map({ wallet -> ChangePasswordData in
                        var newPasswordData = passwordData
                        newPasswordData.wallet = wallet
                        return newPasswordData
                    })
            })
            .sweetDebug("Save Wallet")

            .flatMap({ [weak self] passwordData -> Observable<ChangePasswordData> in
                guard let self = self else { return Observable.never() }
                return self
                    .localWalletSeedRepository
                    .deleteSeed(for: passwordData.wallet.address,
                                seedId: passwordData.oldSeedId)
                    .map { _ in passwordData }
            })
            .sweetDebug("Delete old seed")

            .flatMap({ [weak self] data -> Observable<DomainLayer.DTO.Wallet> in
                guard let self = self else { return Observable.never() }
                return self
                    .remoteAuthenticationRepository
                    .registration(with: data.wallet.id,
                                  keyForPassword: data.keyForPassword,
                                  passcode: passcode)
                    .map { _ in data.wallet }
            })
            .sweetDebug("Firebase register")
            .flatMap({ [weak self] wallet -> Observable<DomainLayer.DTO.Wallet> in
                guard let self = self else { return Observable.never() }
                return self.reRegisterBiometric(wallet: wallet, passcode: passcode)
            })
            .sweetDebug("Biometric")
    }
}


// MARK: - Wallets methods
extension AuthorizationUseCase {

    func existWallet(by publicKey: String) -> Observable<DomainLayer.DTO.Wallet> {
        return self.localWalletRepository
            .wallet(by: publicKey)
            .catchError({ (error) -> Observable<DomainLayer.DTO.Wallet> in
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
            })
    }

    func wallets() -> Observable<[DomainLayer.DTO.Wallet]> {
        return self
            .localWalletRepository
            .wallets()
            .catchError({ [weak self] error -> Observable<[DomainLayer.DTO.Wallet]> in
                guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }
                return Observable.error(self.handlerError(error))
            })
    }

    func registerWallet(_ registration: DomainLayer.DTO.WalletRegistation) -> Observable<DomainLayer.DTO.Wallet> {

        return existWallet(by: registration.privateKey.getPublicKeyStr())
            .flatMap({ (wallet) -> Observable<RegisterData> in
                return Observable.error(AuthorizationUseCaseError.walletAlreadyExist)
            })
            .catchError({ [weak self] error -> Observable<RegisterData> in
                guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }

                if let authError = error as? AuthorizationUseCaseError, case AuthorizationUseCaseError.walletAlreadyExist = authError {
                    return Observable.error(error)
                }

                 return self.registerData(registration)
            })
            .flatMap({ [weak self] registerData -> Observable<(RegisterData, DomainLayer.DTO.WalletSeed, DomainLayer.DTO.Wallet)> in

                guard let self = self else { return Observable.never() }
                let model = DomainLayer.DTO.Wallet(id: registerData.id,
                                                   query: registration)

                let seedId = registerData.seedId

                let saveSeed = self
                    .localWalletSeedRepository
                    .saveSeed(for: .init(publicKey: registration.privateKey.getPublicKeyStr(),
                                         seed: registration.privateKey.wordsStr,
                                         address: registration.privateKey.address),
                              seedId: seedId,
                              password: registerData.password)

                return saveSeed.map { (registerData, $0, model)}
            })
            .flatMap({ [weak self] data -> Observable<(RegisterData, DomainLayer.DTO.WalletSeed, DomainLayer.DTO.Wallet)> in

                guard let self = self else { return Observable.never() }

                let publicKey = data.1.publicKey
                let secret = data.0.secret
                let seedId = data.0.seedId

                let saveSeed = self
                    .localWalletRepository
                    .saveWalletEncryption(DomainLayer.DTO.WalletEncryption(publicKey: publicKey,
                                                                           kind: .passcode(secret: secret),
                                                                           seedId: seedId))
                return saveSeed.map { _ in data }
            })
            .flatMap({ [weak self] (data) -> Observable<DomainLayer.DTO.Wallet> in

                guard let self = self else { return Observable.never() }

                let id = data.2.id
                let keyForPassword = data.0.keyForPassword

                return self
                    .remoteAuthenticationRepository
                    .registration(with: id,
                                  keyForPassword: keyForPassword,
                                  passcode: registration.passcode)
                    .map { _ in data.2 }
            })
            .flatMap({ [weak self] wallet -> Observable<DomainLayer.DTO.Wallet> in
                guard let self = self else { return Observable.never() }

                // Deffault setting for account
                let settings = DomainLayer.DTO.AccountSettings(isEnabledSpam: true)
                return self.accountSettingsRepository
                    .saveAccountSettings(accountAddress: wallet.address,
                                         settings: settings)
                    .map { _ in wallet }
            })
            .flatMap({ [weak self] wallet -> Observable<DomainLayer.DTO.Wallet> in
                guard let self = self else { return Observable.never() }
                return self.localWalletRepository.saveWallet(wallet)
            })
            .catchError({ [weak self] error -> Observable<DomainLayer.DTO.Wallet> in
                guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }
                return Observable.error(self.handlerError(error))
            })
            .share()
            .subscribeOn(ConcurrentDispatchQueueScheduler(queue: DispatchQueue.global()))
    }

    func deleteWallet(_ wallet: DomainLayer.DTO.Wallet) -> Observable<Bool> {

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
            .catchError({ [weak self] error -> Observable<Bool> in
                guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }
                return Observable.error(self.handlerError(error))
            })
    }

    func changeWallet(_ wallet: DomainLayer.DTO.Wallet) -> Observable<DomainLayer.DTO.Wallet> {
        return self
            .localWalletRepository
            .saveWallet(wallet)
            .catchError({ [weak self] error -> Observable<DomainLayer.DTO.Wallet> in
                guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }
                return Observable.error(self.handlerError(error))
            })
    }
}

// MARK: - Logout methods

extension AuthorizationUseCase {

    func logout() -> Observable<DomainLayer.DTO.Wallet> {
        return walletsLoggedIn().flatMap(weak: self, selector: { $0.logout })
    }

    func revokeAuth() -> Observable<Bool> {

        return Observable.create({ [weak self] observer -> Disposable in

            guard let self = self else {
                observer.onError(AuthorizationUseCaseError.fail)
                return Disposables.create()
            }

            self.seedRepositoryMemory.removeAll()
            observer.onNext(true)
            observer.onCompleted()
            return Disposables.create()
        })
    }

    func logout(wallet publicKey: String) -> Observable<DomainLayer.DTO.Wallet> {
        return Observable.create({ [weak self] observer -> Disposable in

            guard let self = self else { return Disposables.create() }

            let disposable = self
                .localWalletRepository
                .wallet(by: publicKey)
                .flatMap({ [weak self] wallet -> Observable<DomainLayer.DTO.Wallet> in
                    guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }
                    let newWallet = wallet.mutate(transform: { $0.isLoggedIn = false })
                    return self
                        .localWalletRepository
                        .saveWallet(newWallet)
                })
                .flatMap({ [weak self] (wallet) -> Observable<DomainLayer.DTO.Wallet> in
                    guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }
                    return self.revokeAuth().map { _ in wallet }
                })
                .catchError({ [weak self] error -> Observable<DomainLayer.DTO.Wallet> in
                    guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }
                    return Observable.error(self.handlerError(error))
                })
                .subscribe(onNext: { completed in
                    observer.onNext(completed)
                    observer.onCompleted()
                })

            return Disposables.create([disposable])
        })
    }
}

// MARK: - Biometric methods

extension AuthorizationUseCase {

    func registerBiometric(wallet: DomainLayer.DTO.Wallet, passcode: String) -> Observable<AuthorizationAuthStatus> {

        let auth = verifyAccessWalletUsingPasscode(passcode, wallet: wallet)
            .flatMap({ [weak self] signedWallet -> Observable<AuthorizationAuthStatus>  in

                guard let self = self else { return Observable.never() }

                let savePasscode = self
                    .savePasscodeInKeychain(wallet: signedWallet.wallet, passcode: passcode, localizedFallbackTitle: "")
                    .flatMap({ [weak self] _ -> Observable<DomainLayer.DTO.Wallet> in
                        guard let self = self else { return Observable.never() }
                        return self.setHasBiometricEntrance(wallet: signedWallet.wallet, hasBiometricEntrance: true)
                    })
                    .map { AuthorizationAuthStatus.completed($0) }

                return Observable.merge(.just(AuthorizationAuthStatus.detectBiometric), savePasscode)
            })

        return Observable.merge(.just(AuthorizationAuthStatus.waiting), auth)
    }

    func unregisterBiometric(wallet: DomainLayer.DTO.Wallet, passcode: String) -> Observable<AuthorizationAuthStatus> {

        let auth = getPasswordByPasscode(passcode, wallet: wallet)
            .flatMap { [weak self] password -> Observable<DomainLayer.DTO.SignedWallet> in 
                guard let self = self else { return Observable.never() }
                return self.verifyAccessWalletUsingPassword(password, wallet: wallet)
            }
            .flatMap({ [weak self] signedWallet -> Observable<AuthorizationAuthStatus> in
                guard let self = self else { return Observable.never() }
                return self.removePasscodeInKeychainWithoutContext(wallet: signedWallet.wallet)
                    .flatMap({ [weak self] _ -> Observable<AuthorizationAuthStatus> in
                        guard let self = self else { return Observable.never() }

                        let removeBiometric = self
                            .setHasBiometricEntrance(wallet: signedWallet.wallet, hasBiometricEntrance: false)
                            .map { AuthorizationAuthStatus.completed($0) }

                        return Observable.merge(.just(AuthorizationAuthStatus.detectBiometric), removeBiometric)
                    })
            })

        return Observable.merge(.just(AuthorizationAuthStatus.waiting), auth)
    }

    func unregisterBiometricUsingBiometric(wallet: DomainLayer.DTO.Wallet) -> Observable<AuthorizationAuthStatus> {

        let passcode = passcodeFromKeychain(wallet: wallet)
            .flatMap { [weak self] passcode -> Observable<AuthorizationAuthStatus> in
                guard let self = self else { return Observable.never() }
                return self.unregisterBiometric(wallet: wallet, passcode: passcode)
        }

        return Observable.merge(.just(AuthorizationAuthStatus.detectBiometric), passcode)
    }

    private func reRegisterBiometric(wallet: DomainLayer.DTO.Wallet, passcode: String) -> Observable<DomainLayer.DTO.Wallet> {

        if wallet.hasBiometricEntrance {
            return registerBiometric(wallet: wallet, passcode: passcode)
                .filter({ status -> Bool in
                    if case .completed = status {
                        return true
                    } else {
                        return false
                    }
                })
                .flatMap({ status -> Observable<DomainLayer.DTO.Wallet> in
                    if case .completed(let wallet) = status {
                        return Observable.just(wallet)
                    }
                    return Observable.empty()
                })
                .catchError({ [weak self] error -> Observable<DomainLayer.DTO.Wallet> in
                    guard let self = self else { return Observable.never() }
                    var newWallet = wallet
                    newWallet.hasBiometricEntrance = false
                    return self.localWalletRepository.saveWallet(newWallet)
                })
        } else {
            return Observable.just(wallet)
        }
    }
}

// MARK: - Keychain methods

private extension AuthorizationUseCase {

    private func removePasscodeInKeychain(wallet: DomainLayer.DTO.Wallet) -> Observable<Bool> {
        return biometricAccess()
            .flatMap({ [weak self] (context) -> Observable<Bool> in
                guard let self = self else { return Observable<Bool>.never() }
                return self.removePasscodeInKeychain(wallet: wallet, context: context)
            })
    }

    private func removePasscodeInKeychain(wallet: DomainLayer.DTO.Wallet, context: LAContext) -> Observable<Bool> {
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

    private func removePasscodeInKeychainWithoutContext(wallet: DomainLayer.DTO.Wallet) -> Observable<Bool> {
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
                    { (result, error) in

                        if  let error = error {
                            context.invalidate()
                            if let error = error as? LAError {
                                SweetLogger.error("biometricDisable \(error.code) \(error.localizedDescription)")
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

    private func savePasscodeInKeychain(wallet: DomainLayer.DTO.Wallet, passcode: String, localizedFallbackTitle: String?) -> Observable<Bool> {
        return biometricAccess(localizedFallbackTitle: localizedFallbackTitle)
            .flatMap({ [weak self] (context) -> Observable<Bool> in
                guard let self = self else { return Observable<Bool>.never() }
                return self.savePasscodeInKeychain(wallet: wallet, passcode: passcode, context: context)
            })
    }

    private func savePasscodeInKeychain(wallet: DomainLayer.DTO.Wallet, passcode: String, context: LAContext) -> Observable<Bool> {
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

            } catch let error {

                if error is AuthorizationUseCaseError {
                    observer.onError(error)
                } else {
                    observer.onError(AuthorizationUseCaseError.biometricDisable)
                }
            }


            return Disposables.create {}
        }
    }

    private func passcodeFromKeychain(wallet: DomainLayer.DTO.Wallet) -> Observable<String> {
        return biometricAccess()
            .flatMap({ [weak self] (context) -> Observable<String> in
                guard let self = self else { return Observable<String>.never() }
                return self.passcodeFromKeychain(wallet: wallet, context: context)
            })
    }

    private func passcodeFromKeychain(wallet: DomainLayer.DTO.Wallet, context: LAContext) -> Observable<String> {

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
                guard let passcode = try keychain.get(wallet.publicKey) else
                {
                    throw AuthorizationUseCaseError.biometricDisable
                }

                observer.onNext(passcode)
                observer.onCompleted()
            } catch let error {
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

    private func verifyAccessWallet(type: AuthorizationType, wallet: DomainLayer.DTO.Wallet) -> Observable<AuthorizationVerifyAccessStatus> {

        switch type {
        case .passcode(let passcode):

            let remote = verifyAccessWalletUsingPasscode(passcode, wallet: wallet)
                .map { AuthorizationVerifyAccessStatus.completed($0) }

            return Observable.merge(Observable.just(AuthorizationVerifyAccessStatus.waiting), remote)

        case .password(let password):

            let remote = verifyAccessWalletUsingPassword(password, wallet: wallet)
                .map { AuthorizationVerifyAccessStatus.completed($0) }

            return Observable.merge(Observable.just(AuthorizationVerifyAccessStatus.waiting), remote)

        case .biometric:
            return verifyAccessWalletUsingBiometric(wallet: wallet)
        }
    }

    private func verifyAccessWalletUsingBiometric(wallet: DomainLayer.DTO.Wallet) -> Observable<AuthorizationVerifyAccessStatus> {

        let auth = passcodeFromKeychain(wallet: wallet)
            .flatMap({ [weak self] passcode -> Observable<AuthorizationVerifyAccessStatus> in
                guard let self = self else { return Observable.never() }
                let verify = self
                    .verifyAccessWalletUsingPasscode(passcode, wallet: wallet)
                    .map { AuthorizationVerifyAccessStatus.completed($0) }

                return Observable.merge(Observable.just(AuthorizationVerifyAccessStatus.waiting), verify)
            })
            .catchError({ [weak self] error -> Observable<AuthorizationVerifyAccessStatus> in
                guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }

                if let authError = error as? AuthorizationUseCaseError,
                    authError == AuthorizationUseCaseError.biometricDisable
                {
                    var newWallet = wallet
                    newWallet.hasBiometricEntrance = false
                    return self
                        .localWalletRepository
                        .saveWallet(newWallet)
                        .flatMap({ [weak self] _ -> Observable<AuthorizationVerifyAccessStatus> in
                            guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }
                            return Observable.error(self.handlerError(error))
                        })
                }
                return Observable.error(self.handlerError(error))
            })

        return Observable.merge(Observable.just(AuthorizationVerifyAccessStatus.detectBiometric), auth)
    }

    private func verifyAccessWalletUsingPasscode(_ passcode: String, wallet: DomainLayer.DTO.Wallet) -> Observable<DomainLayer.DTO.SignedWallet> {

        return getPasswordByPasscode(passcode, wallet: wallet)
            .flatMap { [weak self] password -> Observable<DomainLayer.DTO.SignedWallet> in
                guard let self = self else { return Observable.empty() }
                return self.verifyAccessWalletUsingPassword(password, wallet: wallet)
            }
            .catchError({ [weak self] error -> Observable<DomainLayer.DTO.SignedWallet> in
                guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }
                return Observable.error(self.handlerError(error))
            })
            .catchError({ [weak self] (error) -> Observable<DomainLayer.DTO.SignedWallet> in
                guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }

                if let authError = error as? AuthorizationUseCaseError, authError == .attemptsEnded {
                    return self
                        .localWalletRepository
                        .walletEncryption(by: wallet.publicKey)
                        .flatMap({ [weak self] (walletEnc) -> Observable<DomainLayer.DTO.SignedWallet> in

                            guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }

                            var newWalletEnc = walletEnc
                            newWalletEnc.kind = .none

                            return self.localWalletRepository.saveWalletEncryption(newWalletEnc)
                                .flatMap({ _ ->  Observable<DomainLayer.DTO.SignedWallet> in
                                    return Observable.error(error)
                                })
                        })
                } else {
                    return Observable.error(error)
                }
            })
    }

    private func verifyAccessWalletUsingPassword(_ password: String, wallet: DomainLayer.DTO.Wallet) -> Observable<DomainLayer.DTO.SignedWallet> {

        return localWalletRepository
            .walletEncryption(by: wallet.publicKey)
            .flatMap({ [weak self] walletEncryption -> Observable<DomainLayer.DTO.WalletSeed> in
                guard let self = self else { return Observable.empty() }
                return self
                    .localWalletSeedRepository
                    .seed(for: wallet.address,
                          publicKey: wallet.publicKey,
                          seedId: walletEncryption.seedId,
                          password: password)
            })
            .flatMap({ [weak self] seed -> Observable<DomainLayer.DTO.SignedWallet> in
                guard let self = self else { return Observable.empty() }
                return self.signedWallet(wallet: wallet, seed: seed)
            })            
            .catchError({ [weak self] error -> Observable<DomainLayer.DTO.SignedWallet> in
                guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }
                return Observable.error(self.handlerError(error))
            })
    }
}

// MARK: - Assistants methods
fileprivate extension AuthorizationUseCase {

    func signedWallet(wallet: DomainLayer.DTO.Wallet, seed: DomainLayer.DTO.WalletSeed) -> Observable<DomainLayer.DTO.SignedWallet> {

        return Observable.create({ (observer) -> Disposable in

            let signedWallet = DomainLayer.DTO.SignedWallet(wallet: wallet,
                                                            seed: seed)
            observer.onNext(signedWallet)
            return Disposables.create()
        })
    }

    private func getPasswordByPasscode(_ passcode: String, wallet: DomainLayer.DTO.Wallet) -> Observable<String> {
        
        return remoteAuthenticationRepository
            .auth(with: wallet.id, passcode: passcode)
            .flatMap({ [weak self] keyForPassword -> Observable<(String, DomainLayer.DTO.WalletEncryption)> in
                guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }
                return self.localWalletRepository.walletEncryption(by: wallet.publicKey).map { (keyForPassword, $0) }
            })
            .flatMap { data -> Observable<String> in

                let keyForPassword = data.0
                let walletEncryption = data.1

                guard let secret = walletEncryption.kind.secret else { return Observable.error(AuthorizationUseCaseError.passcodeNotCreated)}

                guard let password: String = secret.aesDecrypt(withKey: keyForPassword) else { return Observable.error(AuthorizationUseCaseError.fail) }
                return Observable.just(password)
            }
            .catchError({ [weak self] error -> Observable<String> in
                guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }
                return Observable.error(self.handlerError(error))
            })
    }

    private func setIsLoggedIn(wallet: DomainLayer.DTO.Wallet,
                               isLoggedIn: Bool = true) -> Observable<DomainLayer.DTO.Wallet> {
        return localWalletRepository
            .wallets(specifications: .init(isLoggedIn: true))
            .flatMap({ [weak self] wallets -> Observable<DomainLayer.DTO.Wallet> in
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
            })
            .catchError({ [weak self] error -> Observable<DomainLayer.DTO.Wallet> in
                guard let self = self else { return Observable.error(AuthorizationUseCaseError.fail) }
                return Observable.error(self.handlerError(error))
            })
    }

    private func setHasBiometricEntrance(wallet: DomainLayer.DTO.Wallet, hasBiometricEntrance: Bool = true) -> Observable<DomainLayer.DTO.Wallet> {

        let newWallet = wallet.mutate(transform: { $0.hasBiometricEntrance = hasBiometricEntrance })

        return self
            .localWalletRepository
            .saveWallet(newWallet)
            .map { _ in newWallet }
    }

    private func logout(_ wallets: [DomainLayer.DTO.Wallet]) -> Observable<DomainLayer.DTO.Wallet> {
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
                return  AuthorizationUseCaseError.passwordIncorrect

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
