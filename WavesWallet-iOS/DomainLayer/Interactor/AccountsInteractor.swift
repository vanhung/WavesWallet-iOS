//
//  AccountsInteractorProtocol.swift
//  WavesWallet-iOS
//
//  Created by mefilt on 10.09.2018.
//  Copyright © 2018 Waves Platform. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

protocol AccountsInteractorProtocol {

    func accounts(by ids: [String], accountAddress: String) -> Observable<[DomainLayer.DTO.Account]>

}

final class AccountsInteractorMock: AccountsInteractorProtocol {

    private let addressBookRepository: AddressBookRepositoryProtocol = FactoryRepositories.instance.addressBookRepository
    private let environmentRepository: EnvironmentRepositoryProtocol = FactoryRepositories.instance.environmentRepository
    private let aliasesRepository: AliasesRepositoryProtocol = FactoryRepositories.instance.aliasesRepository

    func accounts(by ids: [String], accountAddress: String) -> Observable<[DomainLayer.DTO.Account]> {

        return Observable.zip(environmentRepository.accountEnvironment(accountAddress: accountAddress),
                              aliasesRepository.aliases(accountAddress: accountAddress))
            .flatMap({ [weak self] (args) -> Observable<([DomainLayer.DTO.Contact], Environment, [DomainLayer.DTO.Alias])> in

                guard let owner = self else { return Observable.never() }

                return Observable.merge(owner.addressBookRepository.listListener(by: accountAddress),
                                        owner.addressBookRepository.list(by: accountAddress)).map { ($0, args.0, args.1) }
            })
            .flatMap { (contacts, environment, aliases) -> Observable<[DomainLayer.DTO.Account]> in

                let maps = contacts.reduce(into: [String : DomainLayer.DTO.Contact](), { (result, contact) in
                    result[contact.address] = contact
                })

                let accounts = ids.map({ address -> DomainLayer.DTO.Account in

                    let isMyAccount = accountAddress == address || aliases.map { $0.name }.contains(address)
                    return DomainLayer.DTO.Account(address: address, contact: maps[address], isMyAccount: isMyAccount)
                })

                return Observable.just(accounts)
            }
    }
}
