//
//  ApplicationNewsRepositoryProtocol.swift
//  WavesWallet-iOS
//
//  Created by mefilt on 15/02/2019.
//  Copyright © 2019 Waves Exchange. All rights reserved.
//

import Foundation
import RxSwift

public protocol NotificationNewsRepositoryProtocol  {

    func notificationNews() -> Observable<[DomainLayer.DTO.NotificationNews]>
}
