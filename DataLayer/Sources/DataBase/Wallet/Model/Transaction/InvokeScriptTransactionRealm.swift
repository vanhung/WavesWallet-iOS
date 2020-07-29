//
//  InvokeScriptTransaction.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 4/11/19.
//  Copyright © 2019 Waves Exchange. All rights reserved.
//

import Foundation
import RealmSwift

final class InvokeScriptTransactionPaymentRealm: Object {
    @objc dynamic var amount: Int64 = 0
    @objc dynamic var assetId: String? = nil
}

final class InvokeScriptTransactionRealm: TransactionRealm {
    
    @objc dynamic var dappAddress: String = ""
    @objc dynamic var feeAssetId: String? = nil
    
    let payments: List<InvokeScriptTransactionPaymentRealm> = .init()    
}
