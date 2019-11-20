//
//  Sync.swift
//  WavesWallet-iOS
//
//  Created by Prokofev Ruslan on 25/11/2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import RxSwift

public enum Sync<Result> {
    case remote(Result)
    case local(Result, error: Error)
    case error(Error)

    public var remote: Result?  {
        switch self {
        case .remote(let model):
            return model

        default:
            return nil
        }
    }

    public var local: (result: Result, error: Error)? {
        switch self {
        case .local(let model, let error):
            return (result: model, error: error)

        default:
            return nil
        }
    }

    public var resultIngoreError: Result?  {
        switch self {
        case .remote(let model):
            return model

        case .local(let model, _):
            return model
        default:
            return nil
        }
    }

    public var error: Error? {
        switch self {
        case .error(let error):
            return error

        default:
            return nil
        }
    }

    public var anyError: Error? {
        switch self {
        case .error(let error):
            return error

        case .local(_, let error):
            return error
        default:
            return nil
        }
    }
}

public typealias SyncObservable<R> = Observable<Sync<R>>
