//
//  WalletSeedRepositoryProtocol.swift
//  WavesWallet-iOS
//
//  Created by mefilt on 21.09.2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import RxSwift
import RealmSwift
import WavesSDKExtensions
import DomainLayer
import Extensions

fileprivate enum Constants {
    static let schemaVersion: UInt64 = 4
}

final class WalletSeedRepositoryLocal: WalletSeedRepositoryProtocol {

    func seed(for address: String, publicKey: String, seedId: String, password: String) -> Observable<DomainLayer.DTO.WalletSeed> {

        return Observable.create({ [weak self] (observer) -> Disposable in

            guard let self = self else {
                observer.onError(RepositoryError.fail)
                return Disposables.create()
            }

            do {
                guard let realm = try self.realm(address: address, seedId: seedId, password: password) else {
                    observer.onError(WalletSeedRepositoryError.fail)
                    return Disposables.create()
                }

                
                if let object = realm.object(ofType: SeedItem.self, forPrimaryKey: publicKey) {
                    observer.onNext(DomainLayer.DTO.WalletSeed(seed: object))
                    observer.onCompleted()
                } else {
                    observer.onError(WalletSeedRepositoryError.notFound)
                }

            } catch let error {
                SweetLogger.error(error)
                observer.onError(error)
            }

            return Disposables.create()
        })
    }

    func saveSeed(for walletSeed: DomainLayer.DTO.WalletSeed, seedId: String, password: String) -> Observable<DomainLayer.DTO.WalletSeed> {

        return Observable.create({ [weak self] (observer) -> Disposable in

            guard let self = self else {
                observer.onError(RepositoryError.fail)
                return Disposables.create()
            }

            do {
                guard let realm = try self.realm(address: walletSeed.address, seedId: seedId, password: password) else {
                    observer.onError(WalletSeedRepositoryError.fail)
                    return Disposables.create()
                }

                do {
                    try realm.write {
                        realm.add(SeedItem.init(seed: walletSeed), update: .all)
                    }
                    observer.onNext(walletSeed)
                    observer.onCompleted()
                } catch _ {
                    observer.onError(WalletSeedRepositoryError.fail)
                }

            } catch let error {
                SweetLogger.error(error)
                observer.onError(error)
            }

            return Disposables.create()
        })
    }

    func deleteSeed(for address: String, seedId: String) -> Observable<Bool> {
        return Observable.create({ [weak self] (observer) -> Disposable in

            guard let self = self else {
                observer.onError(RepositoryError.fail)
                return Disposables.create()
            }

            if self.removeDB(address: address, seedId: seedId) {
                observer.onNext(true)
                observer.onCompleted()
            } else {
                observer.onError(WalletSeedRepositoryError.fail)
            }

            return Disposables.create()
        })
    }
}

// MARK: Realm
private extension WalletSeedRepositoryLocal {

    func removeDB(address: String, seedId: String) -> Bool {

        guard let fileURL = Realm.Configuration.defaultConfiguration.fileURL else {
            SweetLogger.error("File Realm is nil")
            return false
        }

        let path = fileURL
            .deletingLastPathComponent()
            .appendingPathComponent("\(address)_seed_\(seedId).realm")

        do {
            try FileManager.default.removeItem(at: path)
            return true
        } catch _ {
            return false
        }
    }

    func realmConfig(address: String,
                     password: String,
                     seedId: String) -> Realm.Configuration? {

        var config = Realm.Configuration(encryptionKey: Data(bytes: Hash.sha512(Array(password.utf8))))
        config.objectTypes = [SeedItem.self]
        config.schemaVersion = UInt64(Constants.schemaVersion)

        guard let fileURL = config.fileURL else {
            SweetLogger.error("File Realm is nil")
            return nil
        }

        config.fileURL = fileURL
            .deletingLastPathComponent()
            .appendingPathComponent("\(address)_seed_\(seedId).realm")

        config.migrationBlock = { _, oldSchemaVersion in
            SweetLogger.debug("Migration!!! \(oldSchemaVersion)")
        }
        return config
    }

    func realm(address: String,
               seedId: String,
               password: String) throws -> Realm? {

        guard let config = realmConfig(address: address,
                                       password: password,
                                       seedId: seedId) else { return nil }

        do {
            let realm = try Realm(configuration: config)
            return realm
        } catch let error as Realm.Error {

            switch error {
            case Realm.Error.fileAccess, Realm.Error.filePermissionDenied:
                throw WalletSeedRepositoryError.permissionDenied

            default:
                throw WalletSeedRepositoryError.fail
            }

        } catch let e {
            SweetLogger.error(e)
            throw WalletSeedRepositoryError.fail
        }
    }
}
