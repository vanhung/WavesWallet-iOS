//
//  ReissueTransaction.swift
//  WavesWallet-iOS
//
//  Created by mefilt on 30.08.2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import RealmSwift
import Realm

final class ReissueTransaction: Transaction {

    @objc dynamic var assetId: String = ""
    @objc dynamic var quantity: Int64 = 0
    @objc dynamic var reissuable: Bool = false
}
