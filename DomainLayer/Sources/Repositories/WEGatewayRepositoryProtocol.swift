//
//  WavesExchangeGatewayRepositoryProtocol.swift
//  DomainLayer
//
//  Created by rprokofev on 12.03.2020.
//  Copyright © 2020 Waves Platform. All rights reserved.
//

import Foundation
import Extensions
import RxSwift

extension DomainLayer.Query {
    public enum WEGateway {}
}

extension DomainLayer.DTO {
    public enum WEGateway {}
}

extension DomainLayer.Query.WEGateway {
    
    public struct TransferBinding {
        public var senderAsset: String
        public var recipientAsset: String
        public var recipientAddress: String
        public var token: DomainLayer.DTO.WEOAuth.Token

        public init(senderAsset: String, recipientAsset: String, recipientAddress: String, token: DomainLayer.DTO.WEOAuth.Token) {
            self.senderAsset = senderAsset
            self.recipientAsset = recipientAsset
            self.recipientAddress = recipientAddress
            self.token = token
        }
    }
}

extension DomainLayer.DTO.WEGateway {
    
    public struct TransferBinding {
        public var addresses: [String]
        public var amountMin: Decimal
        public var amountMax: Decimal
        public var taxRate: Decimal
        public var taxFlat: Decimal

        public init(addresses: [String],
                    amountMin: Decimal,
                    amountMax: Decimal,
                    taxRate: Decimal,
                    taxFlat: Decimal) {
            
            self.addresses = addresses
            self.amountMin = amountMin
            self.amountMax = amountMax
            self.taxRate = taxRate
            self.taxFlat = taxFlat
        }
    }
    
    public struct SmartTransferBinding {
        public var addresses: [String]
        public var amountMin: Money
        public var amountMax: Money
        public var fee: Money

        public init(addresses: [String],
                    amountMin: Money,
                    amountMax: Money,
                    fee: Money) {
            self.addresses = addresses
            self.amountMin = amountMin
            self.amountMax = amountMax
            self.fee = fee
        }
    }
}

public protocol WEGatewayRepositoryProtocol {
    func transferBinding(request: DomainLayer.Query.WEGateway.TransferBinding) -> Observable<DomainLayer.DTO.WEGateway.TransferBinding>
}
