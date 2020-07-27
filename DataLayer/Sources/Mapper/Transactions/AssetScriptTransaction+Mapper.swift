//
//  AssetScriptTransaction+Mapper.swift
//  WavesWallet-iOS
//
//  Created by mefilt on 22/01/2019.
//  Copyright © 2019 Waves Exchange. All rights reserved.
//

import DomainLayer
import Extensions
import Foundation
import WavesSDK
import WavesSDKExtensions

extension AssetScriptTransactionRealm {
    convenience init(transaction: AssetScriptTransaction) {
        self.init()
        type = transaction.type
        id = transaction.id
        sender = transaction.sender
        senderPublicKey = transaction.sender
        fee = transaction.fee
        timestamp = transaction.timestamp
        height = transaction.height
        signature = transaction.signature
        version = transaction.version
        script = transaction.script
        assetId = transaction.assetId

        if let proofs = transaction.proofs {
            self.proofs.append(objectsIn: proofs)
        }
        modified = transaction.modified
        status = transaction.status.rawValue
    }
}

extension AssetScriptTransaction {
    init(transaction: NodeService.DTO.SetAssetScriptTransaction,
         status: TransactionStatus?,
         aliasScheme: String) {
        self.init(type: transaction.type,
                  id: transaction.id,
                  sender: transaction.sender.normalizeAddress(aliasScheme: aliasScheme),
                  senderPublicKey: transaction.senderPublicKey,
                  fee: transaction.fee,
                  timestamp: transaction.timestamp,
                  height: transaction.height ?? -1,
                  signature: transaction.signature,
                  proofs: transaction.proofs,
                  chainId: transaction.chainId,
                  version: transaction.version,
                  script: transaction.script,
                  assetId: transaction.assetId,
                  modified: Date(),
                  status: status ?? transaction.applicationStatus?.transactionStatus ?? .completed)
    }

    init(transaction: AssetScriptTransactionRealm) {
        self.init(type: transaction.type,
                  id: transaction.id,
                  sender: transaction.sender,
                  senderPublicKey: transaction.senderPublicKey,
                  fee: transaction.fee,
                  timestamp: transaction.timestamp,
                  height: transaction.height,
                  signature: transaction.signature,
                  proofs: transaction.proofs.toArray(),
                  chainId: UInt8(transaction.chainId.value ?? 0),
                  version: transaction.version,
                  script: transaction.script,
                  assetId: transaction.assetId,
                  modified: transaction.modified,
                  status: TransactionStatus(rawValue: transaction.status) ?? .completed)
    }
}
