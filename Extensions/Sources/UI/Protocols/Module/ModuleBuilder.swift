//
//  ModuleBuilder.swift
//  WavesWallet-iOS
//
//  Created by mefilt on 02.08.2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import UIKit

public protocol ModuleBuilder {
    associatedtype Input
    func build(input: Input) -> UIViewController
}

public extension ModuleBuilder where Input == Void {
    func build() -> UIViewController {
        return build(input: ())
    }
}
