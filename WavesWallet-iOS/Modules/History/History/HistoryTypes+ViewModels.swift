//
//  HistoryTypes+ViewModels.swift
//  WavesWallet-iOS
//
//  Created by Mac on 06/08/2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import DomainLayer

extension HistoryTypes.ViewModel {
    struct Section {
        var items: [Row]
        var date: Date?
        
        init(items: [Row], date: Date? = nil) {
            self.items = items
            self.date = date
        }
    }
    
    enum Row {
        case transaction(SmartTransaction)
        case transactionSkeleton
    }
}


extension HistoryTypes.ViewModel.Section {
    static func map(from transactions: [SmartTransaction]) -> [HistoryTypes.ViewModel.Section] {
        return sections(from: transactions)
    }
    
    static private func sections(from transactions: [SmartTransaction]) -> [HistoryTypes.ViewModel.Section] {

        let calendar = NSCalendar.current
        let sections = transactions.reduce(into: [Date: [SmartTransaction]]()) { result, tx in
            let components = calendar.dateComponents([.day, .month, .year], from: tx.timestamp)
            let date = calendar.date(from: components) ?? Date()
            var list = result[date] ?? []
            list.append(tx)
            result[date] = list
        }

        let sortedKeys = Array(sections.keys).sorted(by: { $0 > $1 })

        return sortedKeys.map { key -> HistoryTypes.ViewModel.Section? in
            guard let section = sections[key] else { return nil }
            let rows = section.map { HistoryTypes.ViewModel.Row.transaction($0) }
            return HistoryTypes.ViewModel.Section(items: rows, date: key)
        }
        .compactMap { $0 }
    }
}
