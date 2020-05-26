//
//  WalletTypes+State.swift
//  WavesWallet-iOS
//
//  Created by Prokofev Ruslan on 15/07/2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation


extension WalletTypes.State {

    static func initialState(kind: WalletTypes.DisplayState.Kind) -> WalletTypes.State {
        return WalletTypes.State(assets: [],
                                 leasing: nil,
                                 displayState: .initialState(kind: kind),
                                 isShowCleanWalletBanner: false,
                                 isNeedCleanWalletBanner: false,
                                 isHasAppUpdate: false,
                                 action: .none,
                                 hasSkipLanding: false)
    }

    func changeDisplay(state: inout WalletTypes.State, kind: WalletTypes.DisplayState.Kind) {

        var display: WalletTypes.DisplayState.Display!

        switch kind {
        case .assets:
            display = state.displayState.assets
        case .leasing:
            display = state.displayState.leasing
        case .staking:
            display = state.displayState.staking
        }

        display.animateType = .refresh(animated: false)

        state.displayState.kind = kind
        state.displayState = state.displayState.updateCurrentDisplay(display)
    }
    
    var hasData: Bool {
        
        switch displayState.kind {
        case .assets:
            return assets.count > 0
            
        case .leasing:
            return leasing != nil
            
        case .staking:
            return staking != nil
        }
    }
}
