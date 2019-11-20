//
//  CreateAliasTypes.swift
//  WavesWallet-iOS
//
//  Created by mefilt on 29/10/2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import Extensions
import DomainLayer

enum CreateAliasTypes {
    enum ViewModel { }
}

extension CreateAliasTypes {

    enum Query: Equatable {
        case checkExist(String)
        case createAlias(String)
        case completedCreateAlias(String)
    }

    struct State: Mutating {        
        var query: Query?
        var displayState: DisplayState
    }

    enum Event {
        case viewWillAppear
        case viewDidDisappear
        case input(String?)
        case createAlias
        case errorAliasExist
        case aliasNameFree
        case aliasCreated
        case handlerError(Error)
        case completedQuery
        case didFinishValidateFeeBalance(Bool)
    }

    struct DisplayState: Mutating, DataSourceProtocol {

        enum Action {
            case none
            case reload
            case update
            case updateValidationFeeBalance(Bool)
        }

        var sections: [ViewModel.Section]
        var input: String?
        var errorState: DisplayErrorState
        var isEnabledSaveButton: Bool
        var isLoading: Bool
        var isAppeared: Bool
        var action: Action?
        var isValidEnoughtFee: Bool
    }
}

extension CreateAliasTypes.ViewModel {

    enum Row {
        case input(String?, error: String?)
    }

    struct Section: SectionProtocol, Mutating {
        var rows: [Row]
    }
}
