//
//  UseCasesFactory.swift
//  WavesWallet-iOS
//
//  Created by mefilt on 06.08.2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation

public final class UseCasesFactory: UseCasesFactoryProtocol {
    public let services: ServicesFactory

    public let repositories: RepositoriesFactoryProtocol

    public let authorizationInteractorLocalizable: AuthorizationInteractorLocalizableProtocol

    public static var instance: UseCasesFactory!

    init(services: ServicesFactory,
         repositories: RepositoriesFactoryProtocol,
         authorizationInteractorLocalizable: AuthorizationInteractorLocalizableProtocol) {
        self.services = services
        self.repositories = repositories
        self.authorizationInteractorLocalizable = authorizationInteractorLocalizable
    }

    public class func initialization(services: ServicesFactory,
                                     repositories: RepositoriesFactoryProtocol,
                                     authorizationInteractorLocalizable: AuthorizationInteractorLocalizableProtocol) {
        instance = UseCasesFactory(services: services,
                                   repositories: repositories,
                                   authorizationInteractorLocalizable: authorizationInteractorLocalizable)
    }

    public private(set) lazy var analyticManager: AnalyticManagerProtocol = {
        repositories.analyticManager
    }()

    public private(set) lazy var accountBalance: AccountBalanceUseCaseProtocol = {
        let interactor = AccountBalanceUseCase(authorizationInteractor: self.authorization,
                                               balanceRepositoryRemote: repositories.accountBalanceRepositoryRemote,
                                               environmentRepository: repositories.environmentRepository,
                                               assetsRepository: self.repositories.assetsRepositoryRemote,
                                               assetsBalanceSettings: self.assetsBalanceSettings,
                                               transactionsInteractor: self.transactions,
                                               serverEnvironmentUseCase: serverEnvironmentUseCase)
        return interactor
    }()

    public private(set) lazy var transactions: TransactionsUseCaseProtocol = {
        let interactor = TransactionsUseCase(transactionsDAO: repositories.transactionsDAO,
                                             transactionsRepositoryRemote: repositories.transactionsRepository,
                                             addressInteractors: self.address,
                                             addressRepository: repositories.addressRepository,
                                             assetsRepository: self.repositories.assetsRepositoryRemote,
                                             blockRepositoryRemote: repositories.blockRemote,
                                             accountSettingsRepository: repositories.accountSettingsRepository,
                                             orderBookRepository: repositories.dexOrderBookRepository,
                                             serverEnvironmentUseCase: serverEnvironmentUseCase)
        return interactor
    }()

    public private(set) lazy var address: AddressInteractorProtocol = {
        let interactor = AddressUseCase(addressBookRepository: repositories.addressBookRepository,
                                        aliasesInteractor: self.aliases)
        return interactor
    }()

    public private(set) lazy var authorization: AuthorizationUseCaseProtocol = {
        let interactor = AuthorizationUseCase(localWalletRepository: repositories.walletsRepositoryLocal,
                                              localWalletSeedRepository: repositories.walletSeedRepositoryLocal,
                                              remoteAuthenticationRepository: repositories.authenticationRepositoryRemote,
                                              accountSettingsRepository: repositories.accountSettingsRepository,
                                              localizable: self.authorizationInteractorLocalizable,
                                              analyticManager: self.analyticManager,
                                              userRepository: self.repositories.userRepository,
                                              environmentRepository: self.repositories.environmentRepository)

        return interactor
    }()

    public private(set) lazy var aliases: AliasesUseCaseProtocol = {
        let interactor = AliasesUseCase(aliasesRepositoryRemote: repositories.aliasesRepositoryRemote,
                                        aliasesRepositoryLocal: repositories.aliasesRepositoryLocal,
                                        serverEnvironmentUseCase: serverEnvironmentUseCase)

        return interactor
    }()

    public private(set) lazy var assetsBalanceSettings: AssetsBalanceSettingsUseCaseProtocol = {
        let interactor = AssetsBalanceSettingsUseCase(assetsBalanceSettingsRepositoryLocal: repositories
            .assetsBalanceSettingsRepositoryLocal,
                                                      environmentRepository: repositories.environmentRepository,
                                                      authorizationInteractor: authorization)

        return interactor
    }()

    public private(set) lazy var migration: MigrationUseCaseProtocol = {
        MigrationUseCase(walletsRepository: repositories.walletsRepositoryLocal,
                         environmentRepository: repositories.environmentRepository)
    }()

    public private(set) lazy var applicationVersionUseCase: ApplicationVersionUseCase =
        ApplicationVersionUseCase(applicationVersionRepository: repositories.applicationVersionRepository)


    public private(set) lazy var oderbook: OrderBookUseCaseProtocol = {
        let interactor = OrderBookUseCase(orderBookRepository: repositories.dexOrderBookRepository,
                                          assetsRepository: repositories.assetsRepositoryRemote,
                                          authorizationInteractor: authorization,
                                          serverEnvironment: serverEnvironmentUseCase)
        return interactor
    }()

    public private(set) lazy var widgetSettings: WidgetSettingsUseCaseProtocol = {
        let useCase = WidgetSettingsUseCase(repositories: repositories, useCases: self)
        return useCase
    }()

    public private(set) lazy var widgetSettingsInizialization: WidgetSettingsInizializationUseCaseProtocol = {
        let useCase = WidgetSettingsInizializationUseCase(repositories: repositories,
                                                          useCases: self,
                                                          serverEnvironmentUseCase: serverEnvironmentUseCase)
        return useCase
    }()

    public private(set) lazy var correctionPairsUseCase: CorrectionPairsUseCaseProtocol = {
        let useCase = CorrectionPairsUseCase(repositories: repositories, useCases: self)
        return useCase
    }()

    public private(set) lazy var weGatewayUseCase: WEGatewayUseCaseProtocol = {
        let useCase = WEGatewayUseCase(gatewayRepository: repositories.weGatewayRepository,
                                       oAuthRepository: repositories.weOAuthRepository,
                                       authorizationUseCase: self.authorization,
                                       serverEnvironmentUseCase: serverEnvironmentUseCase)
        return useCase
    }()

    public private(set) lazy var adCashDepositsUseCase: AdCashDepositsUseCaseProtocol = {
        let useCase = ACashDepositsUseCase(gatewayRepository: repositories.weGatewayRepository,
                                           oAuthRepository: repositories.weOAuthRepository,
                                           authorizationUseCase: self.authorization,
                                           assetsRepository: self.repositories.assetsRepositoryRemote,
                                           serverEnvironmentUseCase: serverEnvironmentUseCase)
        return useCase
    }()

    public private(set) lazy var serverEnvironmentUseCase: ServerEnvironmentRepository = {
        return repositories.serverEnvironmentRepository
    }()
}
