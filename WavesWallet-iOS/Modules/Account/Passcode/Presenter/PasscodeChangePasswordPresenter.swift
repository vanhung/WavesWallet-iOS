//
//  NewAccountPasscodePresenter.swift
//  WavesWallet-iOS
//
//  Created by Prokofev Ruslan on 19/09/2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//
import Foundation
import RxCocoa
import RxFeedback
import RxSwift
import DomainLayer

private struct ChangePasswordQuery: Hashable {
    let wallet: DomainLayer.DTO.Wallet
    let passcode: String
    let oldPassword: String
    let newPassword: String
}

final class PasscodeChangePasswordPresenter: PasscodePresenterProtocol {

    fileprivate typealias Types = PasscodeTypes

    private let disposeBag: DisposeBag = DisposeBag()

    var interactor: PasscodeInteractorProtocol!
    var input: PasscodeModuleInput!
    weak var moduleOutput: PasscodeModuleOutput?

    func system(feedbacks: [Feedback]) {

        var newFeedbacks = feedbacks
        newFeedbacks.append(changePassword())
        newFeedbacks.append(logout())

        let initialState = self.initialState(input: input)

        let system = Driver.system(initialState: initialState,
                                   reduce: { [weak self] state, event -> Types.State in
                                        guard let self = self else { return state }
                                        return self.reduce(state: state, event: event)
                                    },
                                   feedback: newFeedbacks)

        system
            .drive()
            .disposed(by: disposeBag)
    }
}

// MARK: Feedbacks

extension PasscodeChangePasswordPresenter {

    private func changePassword() -> Feedback {
        return react(request: { state -> ChangePasswordQuery? in

            if case .changePassword(let wallet, let newPassword, let oldPassword) = state.kind,
                let action = state.action,
                case .changePassword = action {
                return ChangePasswordQuery(wallet: wallet, passcode: state.passcode, oldPassword: oldPassword, newPassword: newPassword)
            }

            return nil

        }, effects: { [weak self] query -> Signal<Types.Event> in

            guard let self = self else { return Signal.empty() }

            return self
                .interactor
                .changePassword(wallet: query.wallet, passcode: query.passcode, oldPassword: query.oldPassword, newPassword: query.newPassword)
                .map { .completedChangePassword($0) }
                .asSignal { (error) -> Signal<Types.Event> in                    
                    return Signal.just(.handlerError(error))
            }
        })
    }

    private struct LogoutQuery: Hashable {
        let wallet: DomainLayer.DTO.Wallet
    }

    private func logout() -> Feedback {
        return react(request: { state -> LogoutQuery? in

            if case .changePassword(let wallet, _, _) = state.kind,
                let action = state.action, case .logout = action {
                return LogoutQuery(wallet: wallet)
            }

            return nil

        }, effects: { [weak self] query -> Signal<Types.Event> in

            guard let self = self else { return Signal.empty() }

            return self
                .interactor.logout(wallet: query.wallet)
                .map { _ in .completedLogout }
                .asSignal { (error) -> Signal<Types.Event> in
                    return Signal.just(.handlerError(error))
            }
        })
    }
}

// MARK: Core State

private extension PasscodeChangePasswordPresenter {

    func reduce(state: Types.State, event: Types.Event) -> Types.State {

        var newState = state
        reduce(state: &newState, event: event)
        return newState
    }

    func reduce(state: inout Types.State, event: Types.Event) {

        switch event {

        case .completedChangePassword(let wallet):
            state.action = nil
            state.displayState.isLoading = false
            moduleOutput?.passcodeLogInCompleted(passcode: state.passcode, wallet: wallet, isNewWallet: false)

        case .handlerError(let error):

            state.displayState.isLoading = false
            state.displayState.numbers = []
            state.action = nil
            state.displayState.isHiddenBackButton = !state.hasBackButton
            state.displayState.error = Types.displayError(by: error, kind: state.kind)
            if  case .biometricLockout? = state.displayState.error {
                state.displayState.isHiddenBiometricButton = true
            }

        case .viewWillAppear:
            break
            
        case .viewDidAppear:
            break

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

        case .completedInputNumbers(let numbers):
            handlerInputNumbersForChangePassword(numbers, state: &state)

        case .tapBack:
            moduleOutput?.passcodeTapBackButton()

        default:
            break
        }
    }

    // MARK: - Input Numbers For Change Password

    private func handlerInputNumbersForChangePassword(_ numbers: [Int], state: inout Types.State) {

        let kind = state.displayState.kind
        state.numbers[kind] = numbers

        switch kind {
        case .enterPasscode:
            state.displayState.isLoading = true
            state.displayState.numbers = numbers
            state.displayState.isHiddenBackButton = !state.hasBackButton
            state.displayState.error = nil
            state.passcode = numbers.reduce(into: "") { $0 += "\($1)" }
            state.action = .changePassword
        default:
            break
        }
    }
}

// MARK: UI State

private extension PasscodeChangePasswordPresenter {

    func initialState(input: PasscodeModuleInput) -> Types.State {
        return Types.State(displayState: initialDisplayState(input: input),
                           hasBackButton: input.hasBackButton,
                           kind: input.kind,
                           action: nil,
                           numbers: .init(),
                           passcode: "")
    }

    func initialDisplayState(input: PasscodeModuleInput) -> Types.DisplayState {

        return .init(kind: .enterPasscode,
                     numbers: .init(),
                     isLoading: false,
                     isHiddenBackButton: !input.hasBackButton,
                     isHiddenLogInByPassword: true,
                     isHiddenLogoutButton: true,
                     isHiddenBiometricButton: true,
                     error: nil,
                     titleLabel: Types.PasscodeKind.enterPasscode.title(),
                     detailLabel: nil)
    }
}
