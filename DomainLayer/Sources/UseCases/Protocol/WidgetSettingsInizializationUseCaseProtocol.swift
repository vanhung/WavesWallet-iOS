//
//  MarketPulseWidgetUseCaseProtocol.swift
//  DomainLayer
//
//  Created by rprokofev on 12.08.2019.
//  Copyright © 2019 Waves Exchange. All rights reserved.
//

import Foundation
import RxSwift

public protocol WidgetSettingsInizializationUseCaseProtocol {
    func settings() -> Observable<DomainLayer.DTO.MarketPulseSettings>
}
