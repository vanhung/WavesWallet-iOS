//
//  HistoryTypes+State.swift
//  WavesWallet-iOS
//
//  Created by Mac on 02/08/2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import DomainLayer
// MARK: Set Methods

extension HistoryTypes.State {
    
    func setIsAppeared(_ isAppeared: Bool) -> HistoryTypes.State {
        var newState = self
        newState.isAppeared = isAppeared
        return newState
    }
    
    func setIsRefreshing(_ isRefreshing: Bool) -> HistoryTypes.State {
        var newState = self
        newState.isRefreshing = isRefreshing
        return newState
    }
    
    func setSections(sections: [HistoryTypes.ViewModel.Section]) -> HistoryTypes.State {
        var newState = self
        newState.sections = sections
        return newState
    }
    
    func setTransactions(transactions: [DomainLayer.DTO.SmartTransaction]) -> HistoryTypes.State {
        var newState = self
        newState.transactions = transactions
        return newState
    }
    
    func setFilter(filter: HistoryTypes.Filter) -> HistoryTypes.State {
        var newState = self
        newState.currentFilter = filter
        return newState
    }

}

extension HistoryTypes.State {
    static func initialState(historyType: HistoryType) -> HistoryTypes.State {

        return HistoryTypes.State(currentFilter: .all,
                                  filters: historyType.filters,
                                  transactions: [],
                                  sections: self.skeletonSections(),
                                  isRefreshing: false,
                                  isAppeared: false,
                                  refreshData: .refresh,
                                  errorState: .none)
    }

    static func skeletonSections() -> [HistoryTypes.ViewModel.Section] {
        return  [HistoryTypes.ViewModel.Section(items: [.transactionSkeleton,
                                                        .transactionSkeleton,
                                                        .transactionSkeleton,
                                                        .transactionSkeleton,
                                                        .transactionSkeleton,
                                                        .transactionSkeleton,
                                                        .transactionSkeleton])]
    }
}
