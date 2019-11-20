//
//  WalletsRepositoryProtocol.swift
//  WavesWallet-iOS
//
//  Created by mefilt on 21.09.2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import RxSwift

//TODO: Remove
public enum WalletsRepositoryError: Error {
    case fail
    case notFound
}

public struct WalletsRepositorySpecifications {
    public let isLoggedIn: Bool
}


public protocol WalletsRepositoryProtocol {
    
    func wallet(by publicKey: String) -> Observable<DomainLayer.DTO.Wallet>
    func wallets() -> Observable<[DomainLayer.DTO.Wallet]>
    func wallets(specifications: WalletsRepositorySpecifications) -> Observable<[DomainLayer.DTO.Wallet]>

    func saveWallet(_ wallet: DomainLayer.DTO.Wallet) -> Observable<DomainLayer.DTO.Wallet>
    func saveWallets(_ wallets: [DomainLayer.DTO.Wallet]) -> Observable<[DomainLayer.DTO.Wallet]>

    func removeWallet(_ wallet: DomainLayer.DTO.Wallet) -> Observable<Bool>

    func listenerWallet(by publicKey: String) -> Observable<DomainLayer.DTO.Wallet>


    func walletEncryption(by publicKey: String) -> Observable<DomainLayer.DTO.WalletEncryption>

    func saveWalletEncryption(_ walletEncryption: DomainLayer.DTO.WalletEncryption) -> Observable<DomainLayer.DTO.WalletEncryption>

    func removeWalletEncryption(by publicKey: String) -> Observable<Bool>;
}
