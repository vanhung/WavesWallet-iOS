//
//  WalletTypes.swift
//  WavesWallet-iOS
//
//  Created by mefilt on 05.07.2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import UIKit
import RxCocoa
import WavesSDKExtensions
import Extensions
import DomainLayer

enum WalletTypes {}

extension WalletTypes {
    enum ViewModel {}
    enum DTO {}
}

extension WalletTypes {

    struct DisplayState: Mutating {

        enum RefreshData: Equatable {
            case none
            case update
            case refresh
        }

        enum Kind: Int {
            case assets
            case leasing
            case staking
        }

        enum ContentAction  {
            case refresh(animated: Bool)
            case refreshOnlyError
            case collapsed(Int)
            case expanded(Int)
            case none
        }

        struct Display: Mutating {
            var sections: [ViewModel.Section]
            var collapsedSections: [Int: Bool]
            var isRefreshing: Bool
            var animateType: ContentAction = .refresh(animated: false)
            var errorState: DisplayErrorState
        }

        var kind: Kind
        var assets: DisplayState.Display
        var leasing: DisplayState.Display
        var staking: DisplayState.Display
        var isAppeared: Bool
        var listenerRefreshData: RefreshData
        var refreshData: RefreshData
        var listnerSignal: Signal<WalletTypes.Event>?
    }

    struct State: Mutating {

        enum Action {
            case none
            case update
        }
        
        var assets: [DomainLayer.DTO.SmartAssetBalance]
        var leasing: DTO.Leasing?
        var staking: DTO.Staking?
        var displayState: DisplayState
        var isShowCleanWalletBanner: Bool
        var isNeedCleanWalletBanner: Bool
        var isHasAppUpdate: Bool
        var action: Action
        var hasSkipLanding: Bool
    }

    enum Event {
        case setAssets([DomainLayer.DTO.SmartAssetBalance])
        case setLeasing(DTO.Leasing)
        case setStaking(DTO.Staking)
        case handlerError(Error)
        case refresh
        case viewWillAppear
        case viewDidDisappear
        case tapRow(IndexPath)
        case tapSection(Int)
        case tapSortButton
        case tapHistory
        case tapAddressButton
        case changeDisplay(DisplayState.Kind)
        case showStartLease(Money)
        case presentSearch(startPoint: CGFloat)
        case updateApp
        case setCleanWalletBanner
        case isShowCleanWalletBanner(Bool)
        case completeCleanWalletBanner(Bool)
        case isHasAppUpdate(Bool)
        case openStakingFaq(fromLanding: Bool)
        case openWithdraw
        case openBuy
        case openDeposit
        case openTrade
        case openFb(String)
        case openVk(String)
        case openTw(String)
        case startStaking
    }
}

