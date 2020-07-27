//
//  DexMarketPresenter.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 8/9/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import RxSwift
import RxFeedback
import RxCocoa
import DomainLayer

final class DexMarketPresenter: DexMarketPresenterProtocol {
 
    var interactor: DexMarketInteractorProtocol!

    private let disposeBag = DisposeBag()

    private let selectedAsset: Asset?
    
    init(selectedAsset: Asset?) {
        self.selectedAsset = selectedAsset
    }
    
    func system(feedbacks: [DexMarketPresenterProtocol.Feedback]) {
        var newFeedbacks = feedbacks
        newFeedbacks.append(modelsQuery())
        newFeedbacks.append(searchModelsQuery())

        Driver.system(initialState: DexMarket.State.initialState,
                      reduce: { [weak self] state, event -> DexMarket.State in
                        guard let self = self else { return state }
                        return self.reduce(state: state, event: event) },
                      feedback: newFeedbacks)
            .drive()
            .disposed(by: disposeBag)
    }
    
    private func modelsQuery() -> Feedback {
        return react(request: { state -> DexMarket.State? in
            return state.isNeedLoadDefaultPairs ? state : nil
        }, effects: { [weak self] _ -> Signal<DexMarket.Event> in
            
            guard let self = self else { return Signal.empty() }
            return self.interactor.pairs().map { .setPairs($0) }.asSignal(onErrorSignalWith: Signal.empty())
        })
    }
    
    private func searchModelsQuery() -> Feedback {
        return react(request: { state -> DexMarket.State? in
            return state.isNeedSearching ? state : nil
        }, effects: { [weak self] state -> Signal<DexMarket.Event> in
            
            guard let self = self else { return Signal.empty() }
            return self.interactor.searchPairs(searchWord: state.searchKey)
                .map { .setPairs($0) }.asSignal(onErrorSignalWith: Signal.empty())
        })
    }
    
    private func reduce(state: DexMarket.State, event: DexMarket.Event) -> DexMarket.State {
        
        switch event {
        case .readyView:
            return state.changeAction(.none)
            
        case .setPairs(let pairs):
            
            return state.mutate { state in
                
                let items: [DexMarket.ViewModel.Row]
                    
                if let asset = selectedAsset {
                    items = pairs.filter {$0.amountAsset.id == asset.id || $0.priceAsset.id == asset.id}
                        .map { DexMarket.ViewModel.Row.pair(.init(smartPair: $0, selectedAsset: selectedAsset)) }
                }
                else {
                    items = pairs.map { DexMarket.ViewModel.Row.pair(.init(smartPair: $0, selectedAsset: selectedAsset)) }
                }
                let section = DexMarket.ViewModel.Section(items: items)
                state.section = section
                state.isNeedSearching = false
                state.isNeedLoadDefaultPairs = false
            }.changeAction(.update)
        
        case .tapCheckMark(let index):
            
            if let pair = state.section.items[index].pair {
                interactor.checkMark(pair: pair)
            }
            
            return state.mutate { state in
                if let pair = state.section.items[index].pair {
                    state.section.items[index] = DexMarket.ViewModel.Row.pair(.init(smartPair: pair.mutate {$0.isChecked = !$0.isChecked}, selectedAsset: selectedAsset))
                }
            }.changeAction(.update)
            
        case .searchTextChange(let text):
            return state.mutate {
                $0.isNeedSearching = text.count > 0
                $0.isNeedLoadDefaultPairs = text.count == 0
                $0.searchKey = text
            }.changeAction(.none)
        }
    }
}

fileprivate extension DexMarket.ViewModel.Row {
    
    var pair: DomainLayer.DTO.Dex.SmartPair? {
        switch self {
        case .pair(let pair):
            return pair.smartPair
        }
    }
}

fileprivate extension DexMarket.State {
    static var initialState: DexMarket.State {
        let section = DexMarket.ViewModel.Section(items: [])
        return DexMarket.State(action: .none,
                               section: section,
                               searchKey: "",
                               isNeedSearching: false,
                               isNeedLoadDefaultPairs: true)
    }
    
    func changeAction(_ action: DexMarket.State.Action) -> DexMarket.State {
        
        return mutate { state in
            state.action = action
        }
    }
}
