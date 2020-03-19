//
//  AccountPasswordInteractor.swift
//  WavesWallet-iOS
//
//  Created by mefilt on 26/09/2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import RxFeedback
import DomainLayer

enum AccountPasswordInteractorError: Error {
    case fail
    case passcodeIncorrect
    case permissionDenied
}

protocol AccountPasswordInteractorProtocol {
    func logIn(wallet: DomainLayer.DTO.Wallet, password: String) -> Observable<DomainLayer.DTO.Wallet>
    func verifyAccess(wallet: DomainLayer.DTO.Wallet, password: String) -> Observable<DomainLayer.DTO.SignedWallet>
}

final class AccountPasswordInteractor: AccountPasswordInteractorProtocol {

    private let authorizationInteractor: AuthorizationUseCaseProtocol = UseCasesFactory.instance.authorization

    func logIn(wallet: DomainLayer.DTO.Wallet, password: String) -> Observable<DomainLayer.DTO.Wallet> {

        return authorizationInteractor
            .auth(type: .password(password), wallet: wallet)
            .flatMap({ status -> Observable<DomainLayer.DTO.Wallet> in
                if case .completed(let wallet) = status {
                    return Observable.just(wallet)
                }
                return Observable.never()
            })
            .catchError(weak: self, handler: { (owner, error) -> Observable<DomainLayer.DTO.Wallet> in
                return Observable.error(owner.handlerError(error))
            })
            .share()
            .subscribeOn(ConcurrentDispatchQueueScheduler(queue: DispatchQueue.global()))
    }

    func verifyAccess(wallet: DomainLayer.DTO.Wallet, password: String) -> Observable<DomainLayer.DTO.SignedWallet> {
        return authorizationInteractor
            .verifyAccess(type: .password(password), wallet: wallet)
            .flatMap({ status -> Observable<DomainLayer.DTO.SignedWallet> in
                if case .completed(let signedWallet) = status {
                    return Observable.just(signedWallet)
                }
                return Observable.never()
            })
            .catchError(weak: self, handler: { (owner, error) -> Observable<DomainLayer.DTO.SignedWallet> in
                return Observable.error(owner.handlerError(error))
            })
            .share()
            .subscribeOn(ConcurrentDispatchQueueScheduler(queue: DispatchQueue.global()))
    }

    private func handlerError(_ error: Error) -> Error {

       return error
    }
}

