//
//  AddressBookModuleOutput.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 9/23/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import DomainLayer

protocol AddressBookModuleOutput: AnyObject {
    func addressBookDidSelectContact(_ contact: DomainLayer.DTO.Contact)
}
