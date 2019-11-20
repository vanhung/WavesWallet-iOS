//
//  AddAddressBookModuleOutput.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 9/26/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import DomainLayer

protocol AddAddressBookModuleOutput: AnyObject {
    
    func addAddressBookDidEdit(contact: DomainLayer.DTO.Contact, newContact: DomainLayer.DTO.Contact)
    func addAddressBookDidCreate(contact: DomainLayer.DTO.Contact)
    func addAddressBookDidDelete(contact: DomainLayer.DTO.Contact)

}

extension AddAddressBookModuleOutput {
    
    func addAddressBookDidEdit(contact: DomainLayer.DTO.Contact, newContact: DomainLayer.DTO.Contact) {
        
    }
    
    func addAddressBookDidCreate(contact: DomainLayer.DTO.Contact) {
        
    }
    
    func addAddressBookDidDelete(contact: DomainLayer.DTO.Contact) {
        
    }
}
