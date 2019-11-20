//
//  DexTraderContainerModuleOutput.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 8/18/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation

protocol DexTraderContainerModuleOutput: AnyObject {
    func showInfo(pair: DexInfoPair.DTO.Pair)
}
