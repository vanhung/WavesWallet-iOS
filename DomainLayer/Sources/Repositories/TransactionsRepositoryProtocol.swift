//
//  Transactions.swift
//  WavesWallet-iOS
//
//  Created by mefilt on 29.08.2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import RxSwift
import WavesSDK

public enum TransactionsRepositoryError: Error {
    case fail
}


public enum TransactionStatus: Int, Decodable {
    case activeNow
    case completed
    case unconfirmed
}

public extension TransactionType {

    static var all: [TransactionType] {
        return [.issue,
                .transfer,
                .reissue,
                .burn,
                .exchange,
                .createLease,
                .cancelLease,
                .createAlias,
                .massTransfer,
                .data,
                .script,
                .sponsorship,
                .assetScript,
                .invokeScript]
    }
}

public struct TransactionsSpecifications {
    
    public struct Page {
        public let offset: Int
        public let limit: Int

        public init(offset: Int, limit: Int) {
            self.offset = offset
            self.limit = limit
        }
    }

    public let page: Page?
    public let assets: [String]
    public let senders: [String]
    public let types: [TransactionType]

    public init(page: Page?, assets: [String], senders: [String], types: [TransactionType]) {
        self.page = page
        self.assets = assets
        self.senders = senders
        self.types = types
    }
}


public struct AliasTransactionSender {
    public let alias: String
    public let fee: Int64

    public init(alias: String, fee: Int64) {
        self.alias = alias
        self.fee = fee
    }
}

public struct LeaseTransactionSender {
    public let recipient: String
    public let amount: Int64
    public let fee: Int64

    public init(recipient: String, amount: Int64, fee: Int64) {
        self.recipient = recipient
        self.amount = amount
        self.fee = fee
    }
}

public struct BurnTransactionSender {
    public let assetID: String
    public let quantity: Int64
    public let fee: Int64

    public init(assetID: String, quantity: Int64, fee: Int64) {
        self.assetID = assetID
        self.quantity = quantity
        self.fee = fee
    }
}

public struct CancelLeaseTransactionSender {
    public let leaseId: String
    public let fee: Int64
    
    public init(leaseId: String, fee: Int64) {
        self.leaseId = leaseId
        self.fee = fee
    }
}

public struct SendTransactionSender {
    public let recipient: String
    public let assetId: String
    public let amount: Int64
    public let fee: Int64
    public let attachment: String
    public let feeAssetID: String
    public let chainId: String?
    public let timestamp: Date?

    public init(recipient: String,
                assetId: String,
                amount: Int64,
                fee: Int64,
                attachment: String,
                feeAssetID: String,
                chainId: String? = nil,
                timestamp: Date? = nil) {
        self.recipient = recipient
        self.assetId = assetId
        self.chainId = chainId
        self.amount = amount
        self.timestamp = timestamp
        self.fee = fee
        self.attachment = attachment
        self.feeAssetID = feeAssetID
    }
}

public struct DataTransactionSender {
    public struct Value {
        public enum Kind {
            case integer(Int64)
            case boolean(Bool)
            case string(String)
            case binary(String)
        }
        
        public let key: String
        public let value: Kind
        
        public init(key: String, value: Kind) {
            self.key = key
            self.value = value
        }
    }
    
    public let fee: Int64
    public let data: [Value]
    public let chainId: String?
    public let timestamp: Date?
    
    public init(fee: Int64, data: [Value], chainId: String? = nil, timestamp: Date? = nil) {
        self.fee = fee
        self.data = data
        self.timestamp = timestamp
        self.chainId = chainId
    }
}

public struct InvokeScriptTransactionSender {
    
    public struct Arg {
        public enum Value {
            case bool(Bool) //boolean
            case integer(Int64) // integer
            case string(String) // string
            case binary(String) // binary
        }
        
        public let value: Value
        
        public init(value: Value) {
            self.value = value
        }
    }
    
    public struct Call {
        public let function: String
        public let args: [Arg]
        
        public init(function: String, args: [Arg]) {
            self.function = function
            self.args = args
        }
    }
    
    public struct Payment {
        public let amount: Int64
        public let assetId: String
        
        public init(amount: Int64, assetId: String) {
            self.amount = amount
            self.assetId = assetId
        }
    }
    
    public let fee: Int64
    public let feeAssetId: String
    public let dApp: String
    public let call: Call?
    public let payment: [Payment]
    public let chainId: String?
    public let timestamp: Date?
    
    public init(fee: Int64,
                feeAssetId: String,
                dApp: String,
                call: Call?,
                payment: [Payment],
                chainId: String? = nil,
                timestamp: Date? = nil) {
        self.fee = fee
        self.feeAssetId = feeAssetId
        self.dApp = dApp
        self.call = call
        self.payment = payment
        self.timestamp = timestamp
        self.chainId = chainId
    }
}

//TOOD: Rename to Query
public enum TransactionSenderSpecifications {
    case createAlias(AliasTransactionSender)
    case lease(LeaseTransactionSender)
    case burn(BurnTransactionSender)
    case cancelLease(CancelLeaseTransactionSender)
    case data(DataTransactionSender)
    case send(SendTransactionSender)
    case invokeScript(InvokeScriptTransactionSender)
    
    
    public var timestamp: Date? {
        switch self {
        case .data(let model):
            return model.timestamp
            
        case .send(let model):
            return model.timestamp
            
        case .invokeScript(let model):
            return model.timestamp
            
        default:
            return nil
        }
    }
    
    public var chainId: String? {
        switch self {
        case .data(let model):
            return model.chainId
            
        case .send(let model):
            return model.chainId
            
        case .invokeScript(let model):
            return model.chainId
            
        default:
            return nil
        }
    }

}

public protocol TransactionsRepositoryProtocol {

    func transactions(serverEnvironment: ServerEnvironment,
                      address: Address,
                      offset: Int,
                      limit: Int) -> Observable<[AnyTransaction]>
            
    func activeLeasingTransactions(serverEnvironment: ServerEnvironment,
                                   accountAddress: String) -> Observable<[LeaseTransaction]>
        
    func send(serverEnvironment: ServerEnvironment,
              specifications: TransactionSenderSpecifications,
              wallet: DomainLayer.DTO.SignedWallet) -> Observable<AnyTransaction>

    func feeRules() -> Observable<DomainLayer.DTO.TransactionFeeRules>
}

extension DomainLayer.DTO {

    public struct TransactionFeeRules {
        public struct Rule  {
            public let addSmartAssetFee: Bool
            public let addSmartAccountFee: Bool
            public let minPriceStep: Int64
            public let fee: Int64
            public let pricePerTransfer: Int64
            public let pricePerKb: Int64
        

            public init(addSmartAssetFee: Bool, addSmartAccountFee: Bool, minPriceStep: Int64, fee: Int64, pricePerTransfer: Int64, pricePerKb: Int64) {
                self.addSmartAssetFee = addSmartAssetFee
                self.addSmartAccountFee = addSmartAccountFee
                self.minPriceStep = minPriceStep
                self.fee = fee
                self.pricePerTransfer = pricePerTransfer
                self.pricePerKb = pricePerKb
            }
        }
        
        public let smartAssetExtraFee: Int64
        public let smartAccountExtraFee: Int64

        public let defaultRule: TransactionFeeRules.Rule
        public let rules: [TransactionType: TransactionFeeRules.Rule]

        public init(smartAssetExtraFee: Int64, smartAccountExtraFee: Int64, defaultRule: TransactionFeeRules.Rule, rules: [TransactionType: TransactionFeeRules.Rule]) {
            self.smartAssetExtraFee = smartAssetExtraFee
            self.smartAccountExtraFee = smartAccountExtraFee
            self.defaultRule = defaultRule
            self.rules = rules
        }
    }
}

