//
//  MarketPulseWidgetPresenter.swift
//  MarketPulseWidget
//
//  Created by Pavel Gubin on 24.07.2019.
//  Copyright © 2019 Waves Exchange. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import RxFeedback
import WavesSDK

protocol MarketPulseWidgetPresenterProtocol {
    typealias Feedback = (Driver<MarketPulse.State>) -> Signal<MarketPulse.Event>
    var interactor: MarketPulseWidgetInteractorProtocol! { get set }
    
    func system(feedbacks: [MarketPulseWidgetPresenter.Feedback])
}

final class MarketPulseWidgetPresenter: MarketPulseWidgetPresenterProtocol {
    
    var interactor: MarketPulseWidgetInteractorProtocol!
    private let disposeBag = DisposeBag()
        
    func system(feedbacks: [MarketPulseWidgetPresenter.Feedback]) {
        var newFeedbacks = feedbacks
        newFeedbacks.append(queryAssets())
        newFeedbacks.append(querySettings())
        newFeedbacks.append(queryChachedAsset())

        Driver.system(initialState: MarketPulse.State.initialState,
                      reduce: MarketPulseWidgetPresenter.reduce,
                      feedback: newFeedbacks)
        .drive()
        .disposed(by: disposeBag)
    }
    
    private func queryAssets() -> Feedback {
        return react(request: { state -> MarketPulse.State? in
            return state.isNeedRefreshing ? state : nil
        }, effects: { [weak self] _ -> Signal<MarketPulse.Event> in
            guard let self = self else { return Signal.empty() }
            return self.interactor.assets().map {.setAssets($0)}.asSignal(onErrorSignalWith: Signal.empty())
        })
    }
    
    private func querySettings() -> Feedback {
        return react(request: { state -> MarketPulse.State? in
            return state.hasLoadSettings == false ? state : nil
        }, effects: { [weak self] _ -> Signal<MarketPulse.Event> in
            guard let self = self else { return Signal.empty() }
            return self.interactor.settings().map {.setSettings($0)}.asSignal(onErrorSignalWith: Signal.empty())
        })
    }
    
    private func queryChachedAsset() -> Feedback {
        return react(request: { state -> MarketPulse.State? in
            return state.hasLoadChachedAsset == false ? state : nil
        }, effects: { [weak self] _ -> Signal<MarketPulse.Event> in
            guard let self = self else { return Signal.empty() }
            return self.interactor.chachedAssets().map {.setChachedAssets($0)}.asSignal(onErrorSignalWith: Signal.empty())
        })
    }
    
    private static func reduce(state: MarketPulse.State, event: MarketPulse.Event) -> MarketPulse.State {
        
        var newState = state
        reduce(state: &newState, event: event)
        return newState
    }
    
    private static func reduce(state: inout MarketPulse.State, event: MarketPulse.Event) {
        switch event {
        case .readyView:
            state.isNeedRefreshing = true
            
        case .refresh:
            state.isNeedRefreshing = true
            state.action = .none
            
        case .changeCurrency(let currency):
            WidgetSettings.setCurrency(currency: currency)
            
            state.currency = currency
            state.models = mapAssetModels(assets: state.assets, settings: .init(currency: currency,
                                                                                isDarkMode: state.isDarkMode,
                                                                                inverval: state.updateInterval))
            state.action = .update
            
        case .setAssets(let assets):
            state.isNeedRefreshing = false
            
            state.assets = assets
            state.models = mapAssetModels(assets: assets, settings: .init(currency: state.currency,
                                                                                    isDarkMode: state.isDarkMode,
                                                                                    inverval: state.updateInterval))
            state.action = .update
            
        case .setSettings(let settings):
            state.currency = .usd
            state.isDarkMode = settings.isDarkMode
            state.hasLoadSettings = true
            state.action = .update
            
        case .setChachedAssets(let chachedAssets):
            state.assets = chachedAssets
            state.hasLoadChachedAsset = true
            state.models = mapAssetModels(assets: chachedAssets, settings: .init(currency: state.currency,
                                                                          isDarkMode: state.isDarkMode,
                                                                          inverval: state.updateInterval))
            state.action = .update
        }
    }
}

private extension MarketPulseWidgetPresenter {
    
    static func mapAssetModels(assets: [MarketPulse.DTO.Asset], settings: MarketPulse.DTO.Settings) -> [MarketPulse.ViewModel.Row] {

        let wavesCurrency = settings.currency == .usd ? MarketPulse.usdAssetId : MarketPulse.eurAssetId

        return assets.map { asset in
            
            let firstPrice = asset.firstPrice[wavesCurrency] ?? 0
            let lastPrice = asset.lastPrice[wavesCurrency] ?? 0
            
            let deltaPercent = (lastPrice - firstPrice) * 100
            let percent = firstPrice != 0 ? deltaPercent / firstPrice : 0

            return MarketPulse.ViewModel.Row.model(MarketPulse.DTO.UIAsset(icon: asset.icon,
                                                                           name: asset.name,
                                                                           price: asset.rates[wavesCurrency] ?? 0,
                                                                           percent: percent,
                                                                           currency: settings.currency,
                                                                           isDarkMode: settings.isDarkMode))
        }
    }
}

fileprivate extension MarketPulse.State {
    static var initialState: MarketPulse.State {
        return MarketPulse.State(hasLoadSettings: false,
                                 hasLoadChachedAsset: false,
                                 isNeedRefreshing: false,
                                 action: .none,
                                 models: [],
                                 assets: [],
                                 currency: .usd,
                                 isDarkMode: false,
                                 updateInterval: .m1)
    }
}
