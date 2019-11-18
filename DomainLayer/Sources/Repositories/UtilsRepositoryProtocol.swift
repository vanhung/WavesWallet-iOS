//
//  UtilsRepositoryProtocol.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 3/12/19.
//  Copyright © 2019 Waves Exchange. All rights reserved.
//

import Foundation
import RxSwift

public protocol UtilsRepositoryProtocol {
    func timestampServerDiff(accountAddress: String) -> Observable<Int64>
}
