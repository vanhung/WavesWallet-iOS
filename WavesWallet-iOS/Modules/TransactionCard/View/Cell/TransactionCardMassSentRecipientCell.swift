//
//  TransactionCardMassSentRecipientCell.swift
//  WavesWallet-iOS
//
//  Created by rprokofev on 07/03/2019.
//  Copyright © 2019 Waves Exchange. All rights reserved.
//

import DomainLayer
import Extensions
import Foundation
import UIKit
import UITools

final class TransactionCardMassSentRecipientCell: UITableViewCell, Reusable {
    struct Model {
        let contact: DomainLayer.DTO.Contact?
        let contactDetail: ContactDetailView.Model
        let balance: BalanceLabel.Model
        let isEditName: Bool
    }

    @IBOutlet private var contactDetailView: ContactDetailView!
    @IBOutlet private var balanceLabel: BalanceLabel!
    @IBOutlet private var copyButton: PasteboardButton!
    @IBOutlet private var addressBookButton: AddressBookButton!

    private var address: String?

    private var isEditName: Bool?

    var tapAddressBookButton: ((_ isAddAddress: Bool) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        copyButton.copiedText = { [weak self] in
            guard let self = self else { return nil }
            return self.address
        }
    }

    @IBAction private func actionAddressBookButton(_: Any) {
        tapAddressBookButton?(!(isEditName ?? false))
    }
}

// MARK: ViewConfiguration

extension TransactionCardMassSentRecipientCell: ViewConfiguration {
    func update(with model: Model) {
        isEditName = model.isEditName
        address = model.contactDetail.address
        balanceLabel.update(with: model.balance)
        contactDetailView.update(with: model.contactDetail)

        if model.isEditName {
            addressBookButton.update(with: .edit)
        } else {
            addressBookButton.update(with: .add)
        }
    }
}
