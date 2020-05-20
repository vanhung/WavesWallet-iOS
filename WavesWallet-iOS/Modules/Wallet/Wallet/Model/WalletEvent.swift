//
//  WalletEvent.swift
//  WavesWallet-iOS
//
//  Created by rprokofev on 19.05.2020.
//  Copyright © 2020 Waves Platform. All rights reserved.
//
import DomainLayer
import Extensions
import Foundation
import RxCocoa
import UIKit
import WavesSDKExtensions

enum WalletEvent {
    case setAssets([DomainLayer.DTO.SmartAssetBalance])
    case handlerError(Error)
    case refresh
    case viewWillAppear
    case viewDidDisappear
    case tapRow(IndexPath)
    case tapSection(Int)
    case tapHistory
    case tapSortButton
    case tapAddressButton
    case tapActionMenuButton
    case changeDisplay(WalletDisplayState.Kind)
    case presentSearch(startPoint: CGFloat)
    case updateApp
    case isHasAppUpdate(Bool)
}
