//
//  AddAddressBookModuleBuilder.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 9/25/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import UIKit
import Extensions

struct AddAddressBookModuleBuilder: ModuleBuilderOutput {
    
    weak var output: AddAddressBookModuleOutput?
    
    func build(input: AddAddressBook.DTO.Input) -> UIViewController {
        
        let vc = StoryboardScene.AddressBook.addAddressBookViewController.instantiate()
        vc.input = input
        vc.delegate = output
        return vc
    }
}
