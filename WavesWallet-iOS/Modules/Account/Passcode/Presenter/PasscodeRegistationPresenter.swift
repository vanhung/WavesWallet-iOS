//
//  PasscodePresenterRegistration.swift
//  WavesWallet-iOS
//
//  Created by mefilt on 06/11/2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import DomainLayer
import Foundation
import RxCocoa
import RxFeedback
import RxSwift

private struct RegistationQuery: Hashable {
    let account: PasscodeTypes.DTO.Account
    let passcode: String
}

final class PasscodeRegistationPresenter: PasscodePresenterProtocol {
    fileprivate typealias Types = PasscodeTypes

    private let disposeBag: DisposeBag = DisposeBag()

    var interactor: PasscodeInteractorProtocol!
    var input: PasscodeModuleInput!
    weak var moduleOutput: PasscodeModuleOutput?

    func system(feedbacks: [Feedback]) {
        var newFeedbacks = feedbacks
        newFeedbacks.append(registration())
        newFeedbacks.append(logout())

        let initialState = makeInitialState(input: input)

        let system = Driver.system(initialState: initialState,
                                   reduce: { [weak self] state, event -> Types.State in
                                       guard let self = self else { return state }
                                       return self.reduce(state: state, event: event)
                                   },
                                   feedback: newFeedbacks)

        system.drive().disposed(by: disposeBag)
    }
}

// MARK: Feedbacks

extension PasscodeRegistationPresenter {
    private func registration() -> Feedback {
        react(request: { state -> RegistationQuery? in
            if case let .registration(account) = state.kind, case .registration = state.action {
                return RegistationQuery(account: account, passcode: state.passcode)
            } else {
                return nil
            }
        },
              effects: { [weak self] query -> Signal<Types.Event> in

            guard let self = self else { return .empty() }

            return self
                .interactor
                .registrationAccount(query.account, passcode: query.passcode)
                .map { .completedRegistration($0) }
                .asSignal { error -> Signal<Types.Event> in .just(.handlerError(error)) }
        })
    }

    private func logout() -> Feedback {
        return react(request: { state -> Wallet? in
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

private extension PasscodeRegistationPresenter {
    func reduce(state: Types.State, event: Types.Event) -> Types.State {
        var newState = state
        reduce(state: &newState, event: event)
        return newState
    }

    func reduce(state: inout Types.State, event: Types.Event) {
        switch event {
        case let .completedRegistration(status):

            switch status {
            case let .completed(wallet):
                moduleOutput?.passcodeLogInCompleted(passcode: state.passcode, wallet: wallet, isNewWallet: true)
                state.action = nil

            case .detectBiometric:
                state.displayState.isLoading = false

            case .waiting:
                state.displayState.isLoading = true
            }

        case let .handlerError(error):

            state.displayState.isLoading = false
            state.displayState.numbers = []
            state.action = nil
            state.displayState.error = .incorrectPasscode
            state.displayState.isHiddenBackButton = !state.hasBackButton
            state.displayState.error = Types.displayError(by: error, kind: state.kind)

        case .tapLogoutButton:
            state.displayState.isLoading = true
            state.displayState.error = nil
            state.action = .logout

        case .completedLogout:
            state.displayState.isLoading = false
            state.displayState.error = nil
            state.action = nil
            moduleOutput?.passcodeUserLogouted()

        case .viewWillAppear:
            break

        case .viewDidAppear:
            break

        case let .completedInputNumbers(numbers):
            handlerInputNumbersForRegistration(numbers, state: &state)

        case .tapBack:

            if state.displayState.kind == .newPasscode {
                moduleOutput?.passcodeTapBackButton()
            } else {
                state.displayState.kind = .newPasscode
                state.displayState.numbers = []
                state.displayState.isHiddenBackButton = !state.hasBackButton
                state.displayState.error = nil
                state.displayState.titleLabel = state.displayState.kind.title()
            }

        default:
            break
        }
    }

    // MARK: - Input Numbers For Registration

    private func handlerInputNumbersForRegistration(_ numbers: [Int], state: inout Types.State) {
        defer {
            state.displayState.titleLabel = state.displayState.kind.title()
        }

        let kind = state.displayState.kind
        state.numbers[kind] = numbers

        switch kind {
        case .newPasscode:
            state.displayState.kind = .repeatPasscode
            state.displayState.numbers = []
            state.displayState.isHiddenBackButton = false
            state.displayState.error = nil
            state.passcode = ""

        case .repeatPasscode:
            state.displayState.numbers = numbers
            let newPassword = state.numbers[.newPasscode]
            if let newPassword = newPassword, newPassword == numbers {
                state.displayState.isLoading = true
                state.displayState.isHiddenBackButton = true
                state.action = .registration
                state.passcode = newPassword.reduce(into: "") { $0 += "\($1)" }
            } else {
                state.displayState.error = .incorrectPasscode
                state.displayState.isHiddenBackButton = false
                state.displayState.numbers = []
                state.passcode = ""
            }
        default:
            break
        }
    }
}

// MARK: UI State

extension PasscodeRegistationPresenter {
    private func makeInitialState(input: PasscodeModuleInput) -> Types.State {
        .init(displayState: initialDisplayState(input: input),
              hasBackButton: input.hasBackButton,
              kind: input.kind,
              action: nil,
              numbers: .init(),
              passcode: "")
    }

    private func initialDisplayState(input: PasscodeModuleInput) -> Types.DisplayState {
        .init(kind: .newPasscode,
              numbers: .init(),
              isLoading: false,
              isHiddenBackButton: !input.hasBackButton,
              isHiddenLogInByPassword: true,
              isHiddenLogoutButton: true,
              isHiddenBiometricButton: true,
              error: nil,
              titleLabel: Types.PasscodeKind.newPasscode.title(),
              detailLabel: nil)
    }
}
