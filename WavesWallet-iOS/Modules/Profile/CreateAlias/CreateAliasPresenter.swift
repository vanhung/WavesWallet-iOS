//
//  CreateAliasPresenter.swift
//  WavesWallet-iOS
//
//  Created by mefilt on 29/10/2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import RxFeedback
import RxSwift
import RxCocoa
import WavesSDKExtensions
import WavesSDK
import Extensions
import DomainLayer

protocol CreateAliasModuleOutput: AnyObject {
    func createAliasCompletedCreateAlias(_ alias: String)
}

protocol CreateAliasModuleInput {}

protocol CreateAliasPresenterProtocol {

    typealias Feedback = (Driver<CreateAliasTypes.State>) -> Signal<CreateAliasTypes.Event>

    var moduleOutput: CreateAliasModuleOutput? { get set }
    func system(feedbacks: [Feedback])
}

final class CreateAliasPresenter: CreateAliasPresenterProtocol {

    fileprivate typealias Types = CreateAliasTypes

    private let disposeBag: DisposeBag = DisposeBag()
    private let aliasesRepository: AliasesRepositoryProtocol = UseCasesFactory.instance.repositories.aliasesRepositoryRemote
    private let authorizationInteractor: AuthorizationUseCaseProtocol = UseCasesFactory.instance.authorization
    private let transactionsInteractor: TransactionsUseCaseProtocol = UseCasesFactory.instance.transactions
    private let accountBalanceInteractor: AccountBalanceUseCaseProtocol = UseCasesFactory.instance.accountBalance

    weak var moduleOutput: CreateAliasModuleOutput?

    func system(feedbacks: [Feedback]) {

        var newFeedbacks = feedbacks
        newFeedbacks.append(checkExistAliasQuery())
        newFeedbacks.append(getAliasesQuery())
        newFeedbacks.append(externalQueries())
        newFeedbacks.append(enoughtWavesFeeBalanceQuery())
         
        let initialState = self.initialState()

        let system = Driver.system(initialState: initialState,
                                   reduce: CreateAliasPresenter.reduce,
                                   feedback: newFeedbacks)
        system
            .drive()
            .disposed(by: disposeBag)
    }
}

// MARK: - Feedbacks

fileprivate extension CreateAliasPresenter {

    func enoughtWavesFeeBalanceQuery() -> Feedback {
        return react(request: { state -> Bool? in

            return state.displayState.isAppeared ? true : nil

        }, effects: { [weak self] _ -> Signal<Types.Event> in

            guard let self = self else { return Signal.empty() }
            return self
                .authorizationInteractor.authorizedWallet()
                .flatMap{ [weak self] wallet ->  Observable<Bool> in
                    guard let self = self else { return Observable.empty() }

                    return self.transactionsInteractor.calculateFee(by: .createAlias, accountAddress: wallet.address)
                        .flatMap { [weak self] fee ->  Observable<Bool> in
                            guard let self = self else { return Observable.empty() }

                            return self.accountBalanceInteractor
                                .balances()
                                .flatMap { (balances) -> Observable<Bool> in
                                    if let assetBalance = balances.first(where: {$0.assetId == WavesSDKConstants.wavesAssetId}) {
                                        return Observable.just(assetBalance.availableBalance >= fee.amount)
                                    }
                                    return Observable.just(false)
                            }
                    }
                }
                .map {.didFinishValidateFeeBalance($0)}
                .asSignal(onErrorRecover: { e in
                    SweetLogger.error(e)
                    return Signal.just(Types.Event.didFinishValidateFeeBalance(false))
                })
        })
    }
    
    func externalQueries() -> Feedback {

        return react(request: { state -> Types.Query? in

            switch state.query {
            case .completedCreateAlias?:
                return state.query
            default:
                return nil
            }

        }, effects: { [weak self] query -> Signal<Types.Event> in

            guard let self = self else { return Signal.empty() }

            if case .completedCreateAlias(let name) = query {
                self.moduleOutput?.createAliasCompletedCreateAlias(name)
            }

            return Signal.just(.completedQuery)
        })
    }

    func getAliasesQuery() -> Feedback {

        return react(request: { state -> String? in

            if case .createAlias(let name)? = state.query {
                return name
            } else {
                return nil
            }

        }, effects: { [weak self] name -> Signal<Types.Event> in

            guard let self = self else { return Signal.empty() }

            return self
                .authorizationInteractor
                .authorizedWallet()
                .flatMap({ [weak self] wallet -> Observable<(Money, DomainLayer.DTO.SignedWallet)> in
                    guard let self = self else { return Observable.empty() }

                    return self
                        .transactionsInteractor
                        .calculateFee(by: .createAlias, accountAddress: wallet.address)
                        .map { ($0, wallet) }
                })
                .flatMap({ [weak self] data -> Observable<Bool> in
                    guard let self = self else { return Observable.empty() }

                    return self
                        .transactionsInteractor
                        .send(by: .createAlias(.init(alias: name, fee: data.0.amount)), wallet: data.1)
                        .map { _ in true }
                })
                .map { _ in .aliasCreated }
                .asSignal(onErrorRecover: { e in
                    SweetLogger.error(e)
                    return Signal.just(Types.Event.handlerError(e))
                })
        })
    }


    func checkExistAliasQuery() -> Feedback {

        return react(request: { state -> String? in

            if case .checkExist(let name)? = state.query {
                return name
            } else {
                return nil
            }

        }, effects: { [weak self] name -> Signal<Types.Event> in
            guard let self = self else { return Signal.empty() }

            return self
                .authorizationInteractor
                .authorizedWallet()
                .flatMap({ wallet -> Observable<String> in
                    return self.aliasesRepository.alias(by: name, accountAddress: wallet.address)
                })
                .map { _ in .errorAliasExist }
                .asSignal(onErrorRecover: { e in
                    
                    if let error = e as? AliasesRepositoryError, error == .dontExist {
                        return Signal.just(Types.Event.aliasNameFree)
                    }
                    return Signal.just(Types.Event.errorAliasExist)
                })
        })
    }
}

// MARK: Core State

private extension CreateAliasPresenter {

    static func reduce(state: Types.State, event: Types.Event) -> Types.State {
        var newState = state
        reduce(state: &newState, event: event)
        return newState
    }

    static func reduce(state: inout Types.State, event: Types.Event) {

        switch event {
        case .viewWillAppear:
            state.displayState.isAppeared = true
            let section = Types.ViewModel.Section(rows: [.input(state.displayState.input, error: nil)])
            state.displayState.sections = [section]
            state.displayState.action = .reload

        case .viewDidDisappear:
            state.displayState.isAppeared = false

        case .input(let text):
            state.displayState.input = text
            state.displayState.action = .none
            state.query = nil
            state.displayState.errorState = .none

            var inputError: String? = nil
            if let text = text {
                if RegEx.alias(text) {
                    if text.count < WavesSDKConstants.aliasNameMinLimitSymbols {
                        state.displayState.isEnabledSaveButton = false
                        inputError = Localizable.Waves.Createalias.Error.minimumcharacters
                    } else if text.count > WavesSDKConstants.aliasNameMaxLimitSymbols {
                        state.displayState.isEnabledSaveButton = false
                        inputError = Localizable.Waves.Createalias.Error.charactersmaximum
                    } else {
                        state.displayState.isLoading = true
                        state.displayState.isEnabledSaveButton = false
                        inputError = nil
                        state.query = .checkExist(text)
                    }
                } else {
                    inputError = Localizable.Waves.Createalias.Error.invalidcharacter
                    state.displayState.isEnabledSaveButton = false
                }
            } else {
                inputError = nil
                state.displayState.isEnabledSaveButton = false
            }

            state.displayState.action = .update
            let section = Types.ViewModel.Section(rows: [.input(state.displayState.input, error: inputError)])
            state.displayState.sections = [section]

        case .aliasNameFree:
            state.query = nil
            state.displayState.action = .update
            state.displayState.isLoading = false
            state.displayState.isEnabledSaveButton = state.displayState.isValidEnoughtFee
            let section = Types.ViewModel.Section(rows: [.input(state.displayState.input, error: nil)])
            state.displayState.sections = [section]

        case .errorAliasExist:
            state.query = nil
            state.displayState.action = .update
            state.displayState.isLoading = false
            state.displayState.isEnabledSaveButton = false
            let section = Types.ViewModel.Section(rows: [.input(state.displayState.input, error: Localizable.Waves.Createalias.Error.alreadyinuse)])
            state.displayState.sections = [section]

        case .handlerError(let error):
            state.query = nil
            state.displayState.isLoading = false
            state.displayState.isEnabledSaveButton = state.displayState.isValidEnoughtFee
            state.displayState.errorState = DisplayErrorState.error(DisplayError(error: error))

        case .aliasCreated:
            guard let text = state.displayState.input else { return }
            state.displayState.isLoading = false
            state.displayState.isEnabledSaveButton = true
            state.query = .completedCreateAlias(text)
            state.displayState.errorState = .none

        case .createAlias:
            guard let text = state.displayState.input else { return }
            state.query = .createAlias(text)
            state.displayState.isLoading = true
            state.displayState.isEnabledSaveButton = false
            state.displayState.errorState = .none

        case .completedQuery:
            state.query = nil
            
        case .didFinishValidateFeeBalance(let isValidEnoughtFee):
            state.displayState.isEnabledSaveButton = isValidEnoughtFee
            state.displayState.isValidEnoughtFee = isValidEnoughtFee
            state.displayState.action = .updateValidationFeeBalance(isValidEnoughtFee)
        }
    }
}

// MARK: UI State

private extension CreateAliasPresenter {

    func initialState() -> Types.State {
        return Types.State(query: nil,
                           displayState: initialDisplayState())
    }

    func initialDisplayState() -> Types.DisplayState {

        return Types.DisplayState(sections: [],
                                  input: nil,
                                  errorState: .none,
                                  isEnabledSaveButton: false,
                                  isLoading: false,
                                  isAppeared: false,
                                  action: .none,
                                  isValidEnoughtFee: true)
    }
}

