//
//  ScriptTransaction.swift
//  WavesWallet-iOS
//
//  Created by mefilt on 22/01/2019.
//  Copyright © 2019 Waves Exchange. All rights reserved.
//

import Foundation
import RealmSwift

final class ScriptTransaction: Transaction {
    @objc dynamic var script: String? = nil    
}

