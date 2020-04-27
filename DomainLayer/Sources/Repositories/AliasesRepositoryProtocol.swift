//
//  AliasRepositoryProtocol.swift
//  WavesWallet-iOS
//
//  Created by Prokofev Ruslan on 27/10/2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import RxSwift

public enum AliasesRepositoryError: Error {
    case invalid
    case dontExist
}

public protocol AliasesRepositoryProtocol {
    func aliases(serverEnvironment: ServerEnvironment,
                 accountAddress: String) -> Observable<[DomainLayer.DTO.Alias]>
    
    func alias(serverEnvironment: ServerEnvironment,
               name: String,
               accountAddress: String) -> Observable<String>
    
    func saveAliases(accountAddress: String,
                     aliases: [DomainLayer.DTO.Alias]) -> Observable<Bool>
}
