//
//  ModuleBuilderOutput.swift
//  WavesWallet-iOS
//
//  Created by mefilt on 02.08.2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import UIKit

public protocol ModuleBuilderOutput: ModuleBuilder {
    associatedtype Output
    var output: Output { get }
}
