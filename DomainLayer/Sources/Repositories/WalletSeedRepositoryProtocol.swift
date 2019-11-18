//
//  SeedRepository.swift
//  WavesWallet-iOS
//
//  Created by mefilt on 21.09.2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import RxSwift

typealias StringSHA512 = String

public enum WalletSeedRepositoryError: Error {
    case fail
    case permissionDenied
    case notFound
}

public struct WalletSeedRepositoryChangePasswordQuery {
    let oldSeedId: String
    let newSeedId: String
    let oldPassword: String
    let newPassword: String
}

public protocol WalletSeedRepositoryProtocol {
    func seed(for address: String, publicKey: String, seedId: String, password: String) -> Observable<DomainLayer.DTO.WalletSeed>
    func saveSeed(for walletSeed: DomainLayer.DTO.WalletSeed, seedId: String, password: String) -> Observable<DomainLayer.DTO.WalletSeed>
    func deleteSeed(for address: String, seedId: String) -> Observable<Bool>
}
