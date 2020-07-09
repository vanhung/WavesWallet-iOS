//
//  NewAccountPasscodePresenter.swift
//  WavesWallet-iOS
//
//  Created by Prokofev Ruslan on 19/09/2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import DomainLayer
import Foundation
import RxCocoa
import RxFeedback
import RxSwift

private struct LogInQuery: Hashable {
    let wallet: Wallet
    let passcode: String
}

final class PasscodeLogInPresenter: PasscodePresenterProtocol {
    fileprivate typealias Types = PasscodeTypes

    private let disposeBag = DisposeBag()

    var interactor: PasscodeInteractorProtocol!
    var input: PasscodeModuleInput!
    weak var moduleOutput: PasscodeModuleOutput?

    func system(feedbacks: [Feedback]) {
        var newFeedbacks = feedbacks
        newFeedbacks.append(logIn())
        newFeedbacks.append(logout())
        newFeedbacks.append(logInBiometric())

        let initialState = makeInitialState(input: input)

        let system = Driver.system(initialState: initialState,
                                   reduce: { [weak self] state, event -> Types.State in
                                       self?.reduce(state: state, event: event) ?? state
                                   },
                                   feedback: newFeedbacks)

        system.drive().disposed(by: disposeBag)
    }
}

// MARK: Feedbacks

extension PasscodeLogInPresenter {
    private func logInBiometric() -> Feedback {
        react(request: { state -> Wallet? in
            if case let .logIn(wallet) = state.kind, case .logInBiometric = state.action {
                return wallet
            } else {
                return nil
            }
        },
              effects: { [weak self] wallet -> Signal<Types.Event> in

            guard let self = self else { return .empty() }

            return self
                .interactor
                .logInBiometric(wallet: wallet)
                .map { Types.Event.completedLogIn($0) }
                .asSignal { (error) -> Signal<Types.Event> in .just(.handlerError(error)) }
        })
    }

    private func logIn() -> Feedback {
        react(request: { state -> LogInQuery? in
            if case .logIn = state.action, case let .logIn(wallet) = state.kind {
                return LogInQuery(wallet: wallet, passcode: state.passcode)
            } else {
                return nil
            }
        },
              effects: { [weak self] query -> Signal<Types.Event> in

            guard let self = self else { return .empty() }

            return self
                .interactor
                .logIn(wallet: query.wallet, passcode: query.passcode)
                .map { Types.Event.completedLogIn($0) }
                .asSignal { (error) -> Signal<Types.Event> in .just(.handlerError(error)) }
        })
    }

    private func logout() -> Feedback {
        react(request: { state -> Wallet? in
            if case let .logIn(wallet) = state.kind, case .logout = state.action {
                return wallet
            } else {
                return nil
            }
        },
              effects: { [weak self] wallet -> Signal<Types.Event> in

            guard let self = self else { return .empty() }

            return self
                .interactor.logout(wallet: wallet)
                .map { _ in .completedLogout }
                .asSignal { (error) -> Signal<Types.Event> in .just(.handlerError(error)) }
        })
    }
}

// MARK: Core State

private extension PasscodeLogInPresenter {
    func reduce(state: Types.State, event: Types.Event) -> Types.State {
        var newState = state
        reduce(state: &newState, event: event)
        return newState
    }

    func reduce(state: inout Types.State, event: Types.Event) {
        switch event {
        case let .completedLogIn(status):
            reduceCompletedLogIn(status: status, state: &state)

        case let .handlerError(error):

            state.displayState.isLoading = false
            state.displayState.numbers = []
            state.action = nil

            state.displayState.isHiddenBackButton = !state.hasBackButton
            state.displayState.error = Types.displayError(by: error, kind: state.kind)
            if case .biometricLockout? = state.displayState.error {
                state.displayState.isHiddenBiometricButton = true
            }

        case .viewWillAppear:
            break

        case .viewDidAppear:

            state.displayState.error = nil

            switch state.kind {
            case let .logIn(wallet) where wallet.hasBiometricEntrance == true:
                if BiometricType.enabledBiometric != .none {
                    state.action = .logInBiometric
                    state.displayState.isHiddenBiometricButton = false
                } else {
                    state.action = nil
                    state.displayState.isHiddenBiometricButton = true
                }
            default:
                state.action = nil
                state.displayState.isHiddenBiometricButton = true
            }

        case .tapBiometricButton:

            state.displayState.isLoading = true
            state.action = .logInBiometric
            state.displayState.error = nil

        case .tapLogInByPassword:
            moduleOutput?.passcodeLogInByPassword()
            state.displayState.isLoading = false
            state.action = nil
            state.displayState.error = nil

        case .tapLogoutButton:
            state.displayState.isLoading = true
            state.displayState.error = nil
            state.action = .logout

        case .completedLogout:
            state.displayState.isLoading = false
            state.displayState.error = nil
            state.action = nil
            moduleOutput?.passcodeUserLogouted()

        case let .completedInputNumbers(numbers):
            handlerInputNumbersForLogIn(numbers, state: &state)

        case .tapBack:
            moduleOutput?.passcodeTapBackButton()

        default:
            break
        }
    }

    // MARK: - Reduce Completed LogIn

    private func reduceCompletedLogIn(status: AuthorizationAuthStatus, state: inout Types.State) {
        switch status {
        case let .completed(wallet):
            state.action = nil
            state.displayState.isLoading = false
            moduleOutput?.passcodeLogInCompleted(passcode: state.passcode, wallet: wallet, isNewWallet: false)

        case .detectBiometric:
            state.displayState.isLoading = false

        case .waiting:
            state.displayState.isLoading = true
        }
    }

    // MARK: - Input Numbers For Log In

    private func handlerInputNumbersForLogIn(_ numbers: [Int], state: inout Types.State) {
        let kind = state.displayState.kind
        state.numbers[kind] = numbers

        switch kind {
        case .enterPasscode:
            state.displayState.isLoading = true
            state.displayState.numbers = numbers
            state.displayState.isHiddenBackButton = !state.hasBackButton
            state.displayState.error = nil
            state.passcode = numbers.reduce(into: "") { $0 += "\($1)" }
            state.action = .logIn
        default:
            break
        }
    }
}

// MARK: UI State

private extension PasscodeLogInPresenter {
    func makeInitialState(input: PasscodeModuleInput) -> Types.State {
        return Types.State(displayState: initialDisplayState(input: input),
                           hasBackButton: input.hasBackButton,
                           kind: input.kind,
                           action: nil,
                           numbers: .init(),
                           passcode: "")
    }

    func initialDisplayState(input: PasscodeModuleInput) -> Types.DisplayState {
        switch input.kind {
        case let .logIn(wallet):
            return .init(kind: .enterPasscode,
                         numbers: .init(),
                         isLoading: false,
                         isHiddenBackButton: !input.hasBackButton,
                         isHiddenLogInByPassword: false,
                         isHiddenLogoutButton: input.hasBackButton,
                         isHiddenBiometricButton: !wallet.hasBiometricEntrance,
                         error: nil,
                         titleLabel: wallet.name,
                         detailLabel: wallet.address)

        default:
            return .init(kind: .enterPasscode,
                         numbers: .init(),
                         isLoading: false,
                         isHiddenBackButton: false,
                         isHiddenLogInByPassword: false,
                         isHiddenLogoutButton: false,
                         isHiddenBiometricButton: false,
                         error: nil,
                         titleLabel: "",
                         detailLabel: "")
        }
    }
}
