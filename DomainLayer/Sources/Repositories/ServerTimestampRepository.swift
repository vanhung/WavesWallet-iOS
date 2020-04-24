//
//  ServerTimestampDiff.swift
//  DomainLayer
//
//  Created by rprokofev on 24.04.2020.
//  Copyright © 2020 Waves Platform. All rights reserved.
//

import Foundation
import RxSwift

public protocol ServerTimestampRepository {
    
    func timestampServerDiff(serverEnvironment: ServerEnvironment) -> Observable<Int64>
}

