//
//  ReceiveTypes.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 10/3/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation

enum Receive {
    enum ViewModel {}
    enum DTO {}
}

extension Receive.ViewModel {
    
    enum State: Int {
        case cryptoCurrency
        case invoice
        case card
    }
 
}
