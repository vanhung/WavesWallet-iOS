//
//  WalletModuleOutput.swift
//  WavesWallet-iOS
//
//  Created by mefilt on 25.07.2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import UIKit
import DomainLayer
import Extensions

protocol WalletModuleOutput: AnyObject {
    func showWalletSort(balances: [DomainLayer.DTO.SmartAssetBalance])
    func showMyAddress()
    func showHistoryForLeasing()
    func showAsset(with currentAsset: DomainLayer.DTO.SmartAssetBalance, assets: [DomainLayer.DTO.SmartAssetBalance])
    func showStartLease(availableMoney: Money)
    func showLeasingTransaction(transactions: [DomainLayer.DTO.SmartTransaction], index: Int)
    func presentSearchScreen(from startPoint: CGFloat, assets: [DomainLayer.DTO.SmartAssetBalance])
    func openAppStore()
}
