//
//  ChangePasswordPresenter.swift
//  WavesWallet-iOS
//
//  Created by mefilt on 16/10/2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import RxCocoa
import RxFeedback
import RxSwift
import DomainLayer

protocol ChangePasswordModuleOutput: AnyObject {
    func changePasswordCompleted(wallet: Wallet, newPassword: String, oldPassword: String)
}

protocol ChangePasswordModuleInput {
    var wallet: Wallet { get }
}

protocol ChangePasswordPresenterProtocol {

    typealias Feedback = (Driver<ChangePasswordTypes.State>) -> Signal<ChangePasswordTypes.Event>
    var moduleOutput: ChangePasswordModuleOutput? { get set }
    var input: ChangePasswordModuleInput! { get set }
    func system(feedbacks: [Feedback])
}

private struct CheckPasswordQuery: Hashable {
    let wallet: Wallet
    let password: String
}

final class ChangePasswordPresenter: ChangePasswordPresenterProtocol {

    fileprivate typealias Types = ChangePasswordTypes
    weak var moduleOutput: ChangePasswordModuleOutput?
    var input: ChangePasswordModuleInput!

    private let authorizationInteractor: AuthorizationUseCaseProtocol = UseCasesFactory.instance.authorization
    private let disposeBag: DisposeBag = DisposeBag()

    init(input: ChangePasswordModuleInput) {
        self.input = input
    }

    func system(feedbacks: [Feedback]) {

        var newFeedbacks = feedbacks
        newFeedbacks.append(checkOldFeedback())
        newFeedbacks.append(handlerQuery())

        let initialState = self.initialState(wallet: input.wallet)
        let system = Driver.system(initialState: initialState,
                                   reduce: ChangePasswordPresenter.reduce,
                                   feedback: newFeedbacks)
        
        system
            .drive()
            .disposed(by: disposeBag)
    }

    private func checkOldFeedback() -> Feedback {
        return react(request: { state -> CheckPasswordQuery? in

            if state.isAppeared == false {
                return nil
            }

            let password = state.textFields[.oldPassword]

            if let password = password, password.count > 0 {
                return CheckPasswordQuery(wallet: state.wallet, password: password)
            }

            return nil
        }, effects: { [weak self] query -> Signal<Types.Event> in

            guard let self = self else { return Signal.empty() }
            return self
                .authorizationInteractor
                .verifyAccess(type: .password(query.password), wallet: query.wallet)
                .filter({ status -> Bool in
                    if case .completed = status {
                        return true
                    } else {
                        return false
                    }
                })
                .map { _ in Types.Event.successOldPassword }
                .asSignal(onErrorRecover: { error -> Signal<Types.Event> in
                    guard let error = error as? AuthorizationUseCaseError else {
                        return Signal.empty()
                    }

                    return Signal.just(.handlerError(error))
                })
        })
    }

    private func handlerQuery() -> Feedback {
        return react(request: { state -> Types.Query? in

            if let query = state.query,
                case .confirmPassword = query,
                state.isValidConfirmPassword {
                return query
            }

            return nil
        }, effects: { [weak self] query -> Signal<Types.Event> in

            guard let self = self else { return Signal.never() }

            if case .confirmPassword(let wallet, let old, let new) = query {
                self.moduleOutput?.changePasswordCompleted(wallet: wallet, newPassword: new, oldPassword: old)
            }

            return Signal.just(.completedQuery)
        })
    }
}

// MARK: Core State

private extension ChangePasswordPresenter {

    static func isInValidPassword(_ password: String?) -> Bool {
        return (password?.count ?? 0) < UIGlobalConstants.minLengthPassword
    }

    static func reduce(state: Types.State, event: Types.Event) -> Types.State {

        var newState = state
        reduce(state: &newState, event: event)
        return newState
    }

    static func reduce(state: inout Types.State, event: Types.Event) {

        switch event {
        case .readyView:
            state.isAppeared = true

        case .input(let kind, let value):
            
            var textfield = state.displayState.textFields[kind]

            switch kind {
            case .oldPassword:
                textfield?.error = nil
                state.isValidOldPassword = false

            case .newPassword:

                var confirmPasswordTextField = state.displayState.textFields[.confirmPassword]

                if isInValidPassword(value) {
                    textfield?.error = Localizable.Waves.Changepassword.Textfield.Error.atleastcharacters(UIGlobalConstants.minLengthPassword)
                    state.isValidConfirmPassword = false
                } else {
                    textfield?.error = nil
                    state.isValidConfirmPassword = true
                    confirmPasswordTextField?.error = nil
                }

                if let confirmPassword = state.textFields[.confirmPassword],
                    let newPassword = value, confirmPassword != newPassword {
                    confirmPasswordTextField?.error = Localizable.Waves.Changepassword.Textfield.Error.passwordnotmatch
                    state.isValidConfirmPassword = false
                }

                state.displayState.textFields[.confirmPassword] = confirmPasswordTextField

            case .confirmPassword:

                if isInValidPassword(value) {
                    textfield?.error = Localizable.Waves.Changepassword.Textfield.Error.atleastcharacters(UIGlobalConstants.minLengthPassword)
                    state.isValidConfirmPassword = false
                } else if let newPassword = state.textFields[.newPassword],
                    let confirmPassword = value, confirmPassword != newPassword {
                    textfield?.error = Localizable.Waves.Changepassword.Textfield.Error.passwordnotmatch
                    state.isValidConfirmPassword = false
                } else {
                    textfield?.error = nil
                    state.isValidConfirmPassword = true
                }
            }

            state.displayState.isEnabledConfirmButton = state.isValidOldPassword && state.isValidConfirmPassword

            state.displayState.textFields[kind] = textfield
            state.textFields[kind] = value

        case .successOldPassword:
            var textField = state.displayState.textFields[.oldPassword]
            textField?.error = nil
            state.isValidOldPassword = true
            state.displayState.textFields[.oldPassword] = textField
            state.displayState.isEnabledConfirmButton = state.isValidOldPassword && state.isValidConfirmPassword
            
        case .handlerError:
            state.displayState.textFields[.oldPassword]?.error = Localizable.Waves.Changepassword.Textfield.Error.incorrectpassword

        case .tapContinue:
            guard let oldPassword = state.textFields[.oldPassword] else { return }
            guard let confirmPassword = state.textFields[.confirmPassword] else { return }
            state.query = .confirmPassword(wallet: state.wallet, old: oldPassword, new: confirmPassword)
            
        case .completedQuery:
            state.query = nil
        }
    }
}

// MARK: UI State

private extension ChangePasswordPresenter {

    func initialState(wallet: Wallet) -> Types.State {
        return Types.State(wallet: wallet,
                           displayState: initialDisplayState(),
                           query: nil,
                           isAppeared: false,
                           textFields: [:],
                           isValidOldPassword: false,
                           isValidConfirmPassword: false)
    }

    func initialDisplayState() -> Types.DisplayState {
        return Types.DisplayState(textFields: [.oldPassword: .init(error: nil, isEnabled: true),
                                              .newPassword: .init(error: nil, isEnabled: true),
                                              .confirmPassword: .init(error: nil, isEnabled: true)],
                                  isEnabledConfirmButton: false)
    }
}
