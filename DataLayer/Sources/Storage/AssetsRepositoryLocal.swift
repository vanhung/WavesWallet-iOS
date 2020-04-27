//
//  AssetsRepositoryLocal.swift
//  WavesWallet-iOS
//
//  Created by Prokofev Ruslan on 04/08/2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import DomainLayer
import Foundation
import RealmSwift
import RxRealm
import RxSwift
import WavesSDKExtensions

final class AssetsRepositoryLocal: AssetsRepositoryProtocol {
    func searchAssets(serverEnvironment: ServerEnvironment,
                      search: String,
                      accountAddress: String) -> Observable<[DomainLayer.DTO.Asset]> {
        assertMethodDontSupported()
        return Observable.never()
    }

    func assets(serverEnvironment: ServerEnvironment, ids: [String], accountAddress: String) -> Observable<[DomainLayer.DTO.Asset]> {
        Observable.create { observer -> Disposable in
            guard let realm = try? WalletRealmFactory.realm(accountAddress: accountAddress) else {
                observer.onError(AssetsRepositoryError.fail)
                return Disposables.create()
            }

            let objects = realm.objects(Asset.self).filter("id in %@", ids).toArray()

            let newIds = objects.map { $0.id }

            if !ids.contains(where: { newIds.contains($0) }) {
                observer.onError(AssetsRepositoryError.notFound)
            } else {
                let assets = objects.map { DomainLayer.DTO.Asset($0) }

                observer.onNext(assets)
                observer.onCompleted()
            }

            return Disposables.create()
        }
    }

    func saveAssets(_ assets: [DomainLayer.DTO.Asset], by accountAddress: String) -> Observable<Bool> {
        Observable.create { observer -> Disposable in
            guard let realm = try? WalletRealmFactory.realm(accountAddress: accountAddress) else {
                observer.onNext(false)
                observer.onError(AssetsRepositoryError.fail)
                return Disposables.create()
            }

            do {
                try realm.write {
                    let objects = assets.map { Asset(asset: $0) }
                    realm.add(objects, update: .all)
                }
                observer.onNext(true)
                observer.onCompleted()
            } catch _ {
                observer.onNext(false)
                observer.onError(AssetsRepositoryError.fail)
                return Disposables.create()
            }

            return Disposables.create()
        }
    }

    func saveAsset(_ asset: DomainLayer.DTO.Asset, by accountAddress: String) -> Observable<Bool> {
        saveAssets([asset], by: accountAddress)
    }

    func isSmartAsset(serverEnvironment: ServerEnvironment, assetId: String, accountAddress: String) -> Observable<Bool> {
        assertMethodDontSupported()
        return Observable.never()
    }
}