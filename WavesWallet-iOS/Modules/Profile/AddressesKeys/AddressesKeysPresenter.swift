//
//  AddressesKeysPresenter.swift
//  WavesWallet-iOS
//
//  Created by mefilt on 26/10/2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import DomainLayer
import Foundation
import RxCocoa
import RxFeedback
import RxSwift

protocol AddressesKeysModuleOutput: AnyObject {
    func addressesKeysNeedPrivateKey(wallet: Wallet,
                                     callback: @escaping ((SignedWallet?) -> Void))
    func addressesKeysShowAliases(_ aliases: [DomainLayer.DTO.Alias])
}

protocol AddressesKeysModuleInput {
    var wallet: Wallet { get }
}

protocol AddressesKeysPresenterProtocol {
    typealias Feedback = (Driver<AddressesKeysTypes.State>) -> Signal<AddressesKeysTypes.Event>

    var moduleOutput: AddressesKeysModuleOutput? { get set }
    var moduleInput: AddressesKeysModuleInput! { get set }
    func system(feedbacks: [Feedback])
}

final class AddressesKeysPresenter: AddressesKeysPresenterProtocol {
    fileprivate typealias Types = AddressesKeysTypes

    private let disposeBag = DisposeBag()
    private let authorizationUseCase: AuthorizationUseCaseProtocol
    private let aliasesRepository: AliasesRepositoryProtocol
    private let serverEnvironmentUseCase: ServerEnvironmentRepository

    var moduleInput: AddressesKeysModuleInput!
    weak var moduleOutput: AddressesKeysModuleOutput?
    
    init(authorizationUseCase: AuthorizationUseCaseProtocol,
         aliasesRepository: AliasesRepositoryProtocol,
         serverEnvironmentRepository: ServerEnvironmentRepository) {
        self.authorizationUseCase = authorizationUseCase
        self.aliasesRepository = aliasesRepository
        self.serverEnvironmentUseCase = serverEnvironmentRepository
    }

    func system(feedbacks: [Feedback]) {
        var newFeedbacks = feedbacks
        newFeedbacks.append(getAliasesQuery())
        newFeedbacks.append(getPrivateKeyQuery())
        newFeedbacks.append(externalQuery())

        let initialState = self.initialState(moduleInput: moduleInput)

        let system = Driver.system(initialState: initialState,
                                   reduce: AddressesKeysPresenter.reduce,
                                   feedback: newFeedbacks)
        system
            .drive()
            .disposed(by: disposeBag)
    }
}

// MARK: - Feedbacks

fileprivate extension AddressesKeysPresenter {
    func getAliasesQuery() -> Feedback {
        return react(request: { state -> String? in

            if state.displayState.isAppeared == true {
                return state.wallet.address
            } else {
                return nil
            }

        }, effects: { [weak self] accountAddress -> Signal<Types.Event> in

            guard let self = self else { return Signal.empty() }

            let serverEnvironment = self
                .serverEnvironmentUseCase
                .serverEnvironment()

            return serverEnvironment
                .flatMap { [weak self] serverEnvironment -> Observable<[DomainLayer.DTO.Alias]> in

                    guard let self = self else { return Observable.never() }

                    return self
                        .aliasesRepository
                        .aliases(serverEnvironment: serverEnvironment,
                                 accountAddress: accountAddress)
                }
                .map { Types.Event.setAliases($0) }
                .asSignal(onErrorRecover: { _ in
                    Signal.empty()
                })
        })
    }

    func getPrivateKeyQuery() -> Feedback {
        return react(request: { state -> Wallet? in

            if case .getPrivateKey? = state.query {
                return state.wallet
            } else {
                return nil
            }

        }, effects: { [weak self] wallet -> Signal<Types.Event> in

            Observable.create { [weak self] (observer) -> Disposable in

                guard let self = self else { return Disposables.create() }

                self
                    .moduleOutput?
                    .addressesKeysNeedPrivateKey(wallet: wallet, callback: { signedWallet in

                        if let signedWallet = signedWallet {
                            observer.onNext(.setPrivateKey(signedWallet))
                            observer.onCompleted()
                        } else {
                            observer.onNext(.completedQuery)
                            observer.onCompleted()
                        }
                    })
                return Disposables.create()
            }
            .asSignal(onErrorRecover: { _ in
                Signal.empty()
            })
        })
    }

    func externalQuery() -> Feedback {
        return react(request: { state -> Types.Query? in

            if case .showInfo? = state.query {
                return state.query
            } else {
                return nil
            }

        }, effects: { [weak self] query -> Signal<Types.Event> in

            if case let .showInfo(aliases) = query {
                self?.moduleOutput?.addressesKeysShowAliases(aliases)
            }

            return Signal.just(.completedQuery)
        })
    }
}

// MARK: Core State

private extension AddressesKeysPresenter {
    static func reduce(state: Types.State, event: Types.Event) -> Types.State {
        var newState = state
        reduce(state: &newState, event: event)
        return newState
    }

    static func reduce(state: inout Types.State, event: Types.Event) {
        switch event {
        case .viewWillAppear:
            state.displayState.isAppeared = true

        case .viewDidDisappear:
            state.displayState.isAppeared = false

        case let .setAliases(aliaces):
            state.aliases = aliaces

            var sections = state.displayState.sections
            guard var section = sections.first else { return }
            var rows = section.rows

            guard rows.first != nil else { return }

            rows[0] = .aliases(aliaces.count)
            section.rows = rows
            sections[0] = section

            state.displayState.action = .update
            state.displayState.sections = sections

        case .tapShowPrivateKey:
            state.query = .getPrivateKey

        case .tapShowInfo:
            state.query = .showInfo(aliases: state.aliases)

        case let .setPrivateKey(signedWallet):

            var sections = state.displayState.sections
            guard var section = sections.first else { return }
            var rows = section.rows

            guard rows.first != nil else { return }

            rows[3] = .privateKey(signedWallet.privateKey.privateKeyStr)

            section.rows = rows
            sections[0] = section

            state.displayState.action = .update
            state.displayState.sections = sections

        case .completedQuery:
            state.query = nil
        }
    }
}

// MARK: UI State

private extension AddressesKeysPresenter {
    func initialState(moduleInput: AddressesKeysModuleInput) -> Types.State {
        return Types.State(wallet: moduleInput.wallet,
                           aliases: [],
                           query: nil,
                           displayState: initialDisplayState(moduleInput: moduleInput))
    }

    func initialDisplayState(moduleInput: AddressesKeysModuleInput) -> Types.DisplayState {
        let section = Types.ViewModel.Section(rows: [.skeleton,
                                                     .address(moduleInput.wallet.address),
                                                     .publicKey(moduleInput.wallet.publicKey),
                                                     .hiddenPrivateKey])

        return Types.DisplayState(sections: [section],
                                  isAppeared: false,
                                  action: .update)
    }
}
