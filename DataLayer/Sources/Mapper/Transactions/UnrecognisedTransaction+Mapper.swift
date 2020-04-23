//
//  UnrecognisedTransaction+Mapper.swift
//  WavesWallet-iOS
//
//  Created by mefilt on 31.08.2018.1
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import DomainLayer
import Foundation
import WavesSDK

extension UnrecognisedTransaction {
    convenience init(transaction: DomainLayer.DTO.UnrecognisedTransaction) {
        self.init()
        type = transaction.type
        id = transaction.id
        sender = transaction.sender
        senderPublicKey = transaction.sender
        fee = transaction.fee
        timestamp = transaction.timestamp
        version = 1
        height = transaction.height
        modified = transaction.modified
        status = transaction.status.rawValue
    }
}

extension DomainLayer.DTO.UnrecognisedTransaction {
    init(transaction: NodeService.DTO.UnrecognisedTransaction,
         status: DomainLayer.DTO.TransactionStatus,
         aliasScheme: String) {
        self.init(type: transaction.type,
                  id: transaction.id,
                  sender: transaction.sender.normalizeAddress(aliasScheme: aliasScheme),
                  senderPublicKey: transaction.senderPublicKey,
                  fee: transaction.fee,
                  timestamp: transaction.timestamp,
                  height: transaction.height,
                  modified: Date(),
                  status: status)
    }

    init(transaction: UnrecognisedTransaction) {
        self.init(type: transaction.type,
                  id: transaction.id,
                  sender: transaction.sender,
                  senderPublicKey: transaction.senderPublicKey,
                  fee: transaction.fee,
                  timestamp: transaction.timestamp,
                  height: transaction.height,
                  modified: transaction.modified,
                  status: DomainLayer.DTO.TransactionStatus(rawValue: transaction.status) ?? .completed)
    }
}
