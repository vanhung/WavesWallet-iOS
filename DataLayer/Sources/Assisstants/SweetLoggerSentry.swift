//
//  SweetLoggerSentry.swift
//  WavesWallet-iOS
//
//  Created by rprokofev on 27/02/2019.
//  Copyright © 2019 Waves Exchange. All rights reserved.
//

import Foundation
import Sentry
import WavesSDKExtensions

public final class SweetLoggerSentry: SweetLoggerProtocol {

    public private(set) var visibleLevels: [SweetLoggerLevel] = []

    public init(visibleLevels: [SweetLoggerLevel]) {

        self.visibleLevels = visibleLevels
    }

    public func send(message: @escaping @autoclosure () -> Any,
              level: SweetLoggerLevel,
              file: String,
              function: String,
              line: Int,
              context: Any?,
              type: Any.Type? = nil)
    {
        guard visibleLevels.contains(level) == true else { return }

        let event = Sentry.Event(level: level.sentrySeverity)
        event.message = "\(message())"
        
        SentryManager.send(event: event)
    }
}

private extension SweetLoggerLevel {

    var sentrySeverity: SentrySeverity {
        switch self {
        case .debug:
            return SentrySeverity.debug

        case .error:
            return SentrySeverity.error

        case .warning:
            return SentrySeverity.info

        case .network:
            return SentrySeverity.info

        case .info:
            return SentrySeverity.info

        case .verbose:
            return SentrySeverity.info

        }
    }
}
