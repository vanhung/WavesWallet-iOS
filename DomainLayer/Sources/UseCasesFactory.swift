//
//  UseCasesFactory.swift
//  WavesWallet-iOS
//
//  Created by mefilt on 06.08.2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation

public final class UseCasesFactory: UseCasesFactoryProtocol {
    public let repositories: RepositoriesFactoryProtocol
    
    public let storages: StoragesFactoryProtocol
    
    public let authorizationInteractorLocalizable: AuthorizationInteractorLocalizableProtocol
    
    public static var instance: UseCasesFactory!
    
    init(repositories: RepositoriesFactoryProtocol,
         authorizationInteractorLocalizable: AuthorizationInteractorLocalizableProtocol,
         storages: StoragesFactoryProtocol) {
        self.repositories = repositories
        self.storages = storages
        self.authorizationInteractorLocalizable = authorizationInteractorLocalizable
    }
    
    public class func initialization(repositories: RepositoriesFactoryProtocol,
                                     authorizationInteractorLocalizable: AuthorizationInteractorLocalizableProtocol,
                                     storages: StoragesFactoryProtocol) {
        self.instance = UseCasesFactory(repositories: repositories,
                                        authorizationInteractorLocalizable: authorizationInteractorLocalizable,
                                        storages: storages)
    }
    
    public private(set) lazy var analyticManager: AnalyticManagerProtocol = {
        repositories.analyticManager
    }()
    
    public private(set) lazy var accountBalance: AccountBalanceUseCaseProtocol = {
        let interactor = AccountBalanceUseCase(authorizationInteractor: self.authorization,
                                               balanceRepositoryRemote: repositories.accountBalanceRepositoryRemote,
                                               environmentRepository: repositories.environmentRepository,
                                               assetsInteractor: self.assets,
                                               assetsBalanceSettings: self.assetsBalanceSettings,
                                               transactionsInteractor: self.transactions,
                                               assetsBalanceSettingsRepository: repositories.assetsBalanceSettingsRepositoryLocal)
        return interactor
    }()
    
    public private(set) lazy var transactions: TransactionsUseCaseProtocol = {
        let interactor = TransactionsUseCase(transactionsRepositoryLocal: repositories.transactionsRepositoryLocal,
                                             transactionsRepositoryRemote: repositories.transactionsRepositoryRemote,
                                             assetsInteractors: self.assets,
                                             addressInteractors: self.address,
                                             addressRepository: repositories.addressRepository,
                                             assetsRepositoryRemote: repositories.assetsRepositoryRemote,
                                             blockRepositoryRemote: repositories.blockRemote,
                                             accountSettingsRepository: repositories.accountSettingsRepository,
                                             orderBookRepository: repositories.dexOrderBookRepository)
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
                                              analyticManager: self.analyticManager)
        
        return interactor
    }()
    
    public private(set) lazy var aliases: AliasesUseCaseProtocol = {
        let interactor = AliasesUseCase(aliasesRepositoryRemote: repositories.aliasesRepositoryRemote,
                                        aliasesRepositoryLocal: repositories.aliasesRepositoryLocal)
        
        return interactor
    }()
    
    public private(set) lazy var assetsBalanceSettings: AssetsBalanceSettingsUseCaseProtocol = {
        let interactor = AssetsBalanceSettingsUseCase(assetsBalanceSettingsRepositoryLocal: repositories.assetsBalanceSettingsRepositoryLocal,
                                                      environmentRepository: repositories.environmentRepository,
                                                      authorizationInteractor: authorization)
        
        return interactor
    }()
    
    public private(set) lazy var migration: MigrationUseCaseProtocol = {
        MigrationUseCase(walletsRepository: repositories.walletsRepositoryLocal)
    }()
    
    public private(set) lazy var applicationVersionUseCase: ApplicationVersionUseCase = ApplicationVersionUseCase(applicationVersionRepository: repositories.applicationVersionRepository)
    
    public private(set) lazy var assets: AssetsUseCaseProtocol = {
        let interactor = AssetsUseCase(assetsRepositoryLocal: repositories.assetsRepositoryLocal,
                                       assetsRepositoryRemote: repositories.assetsRepositoryRemote)
        
        return interactor
    }()
    
    public private(set) lazy var oderbook: OrderBookUseCaseProtocol = {
        let interactor = OrderBookUseCase(orderBookRepository: repositories.dexOrderBookRepository,
                                          assetsInteractor: assets,
                                          authorizationInteractor: authorization)
        return interactor
    }()
    
    public private(set) lazy var widgetSettings: WidgetSettingsUseCaseProtocol = {
        let useCase = WidgetSettingsUseCase(repositories: repositories, useCases: self)
        return useCase
    }()
    
    public private(set) lazy var widgetSettingsInizialization: WidgetSettingsInizializationUseCaseProtocol = {
        let useCase = WidgetSettingsInizializationUseCase(repositories: repositories,
                                                          useCases: self)
        return useCase
    }()
    
    public private(set) lazy var correctionPairsUseCase: CorrectionPairsUseCaseProtocol = {
        let useCase = CorrectionPairsUseCase(repositories: repositories, useCases: self)
        return useCase
    }()
    
    public private(set) lazy var weGatewayUseCase: WEGatewayUseCaseProtocol = {

        let useCase = WEGatewayUseCase(gatewayRepository: repositories.weGatewayRepositoryProtocol,
                                       oAuthRepository: repositories.weOAuthRepositoryProtocol,
                                       authorizationUseCase: self.authorization)
        return useCase
    }()
        
    public private(set) lazy var adCashDepositsUseCase: AdCashDepositsUseCaseProtocol = {

        let useCase = ACashDepositsUseCase(gatewayRepository: repositories.weGatewayRepositoryProtocol,
                                           oAuthRepository: repositories.weOAuthRepositoryProtocol,
                                           authorizationUseCase: self.authorization,
                                           assetsUseCase: self.assets)
        return useCase
    }()
}
