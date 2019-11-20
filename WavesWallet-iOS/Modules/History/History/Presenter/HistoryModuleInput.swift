//
//  HistoryModuleInput.swift
//  WavesWallet-iOS
//
//  Created by Mac on 08/08/2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation

protocol HistoryModuleInput {
    var type: HistoryType { get }
}

enum HistoryType {
    case all
    case asset(String)
    case leasing
}

