//
//  TransactionCardSystem+Mapper.swift
//  WavesWallet-iOS
//
//  Created by rprokofev on 15/03/2019.
//  Copyright © 2019 Waves Exchange. All rights reserved.
//

import DomainLayer
import Extensions
import Foundation

private enum Constants {
    static let maxVisibleRecipients: Int = 3
}

private typealias Types = TransactionCard

extension DomainLayer.DTO.SmartTransaction {
    func sections(core: TransactionCard.State.Core) -> [TransactionCard.Section] {
        switch kind {
        case let .sent(transfer):
            return sentSection(transfer: transfer, core: core)

        case let .receive(transfer):
            return receiveSection(transfer: transfer, core: core)

        case let .spamReceive(transfer):
            return spamReceiveSection(transfer: transfer, core: core)

        case let .selfTransfer(transfer):
            return selfTransferSection(transfer: transfer, core: core)

        case let .massSent(transfer):
            return massSentSection(transfer: transfer, core: core)

        case let .massReceived(massReceive):
            return massReceivedSection(transfer: massReceive, core: core)

        case let .spamMassReceived(massReceive):
            return massReceivedSection(transfer: massReceive, core: core)

        case let .startedLeasing(leasing):
            return leasingSection(transfer: leasing,
                                  title: Localizable.Waves.Transactioncard.Title.startedLeasing,
                                  titleContact: Localizable.Waves.Transactioncard.Title.nodeAddress,
                                  needCancelLeasing: true,
                                  core: core)

        case let .canceledLeasing(leasing):
            return leasingSection(transfer: leasing,
                                  title: Localizable.Waves.Transactioncard.Title.canceledLeasing,
                                  titleContact: Localizable.Waves.Transactioncard.Title.nodeAddress,
                                  needCancelLeasing: false,
                                  core: core)

        case let .incomingLeasing(leasing):
            return leasingSection(transfer: leasing,
                                  title: Localizable.Waves.Transactioncard.Title.incomingLeasing,
                                  titleContact: Localizable.Waves.Transactioncard.Title.leasingFrom,
                                  needCancelLeasing: false,
                                  core: core)

        case let .exchange(exchange):
            return exchangeSection(transfer: exchange)

        case let .tokenGeneration(issue):
            return issueSection(transfer: issue,
                                title: Localizable.Waves.Transactioncard.Title.tokenGeneration,
                                balanceSign: .none)

        case let .tokenBurn(issue):
            return issueSection(transfer: issue,
                                title: Localizable.Waves.Transactioncard.Title.tokenBurn,
                                balanceSign: .minus)

        case let .tokenReissue(issue):
            return issueSection(transfer: issue,
                                title: Localizable.Waves.Transactioncard.Title.tokenReissue,
                                balanceSign: .plus)

        case let .createdAlias(alias):
            return deffaultSection(title: Localizable.Waves.Transactioncard.Title.createAlias,
                                   description: alias)

        case .unrecognisedTransaction:
            return deffaultSection(title: Localizable.Waves.Transactioncard.Title.unrecognisedTransaction,
                                   description: "")

        case .data:
            return deffaultSection(title: Localizable.Waves.Transactioncard.Title.entryInBlockchain,
                                   description: Localizable.Waves.Transactioncard.Title.dataTransaction)

        case let .script(isHasScript):

            let description = isHasScript ? Localizable.Waves.Transactioncard.Title.setScriptTransaction :
                Localizable.Waves.Transactioncard.Title.cancelScriptTransaction

            return deffaultSection(title: Localizable.Waves.Transactioncard.Title.entryInBlockchain,
                                   description: description)

        case let .assetScript(asset):
            return setAssetScriptSection(asset: asset)

        case let .sponsorship(isEnabled, asset):
            return sponsorshipSection(asset: asset, isEnabled: isEnabled)

        case let .invokeScript(tx):
            return invokeScriptSection(tx: tx,
                                       title: Localizable.Waves.Transactioncard.Title.entryInBlockchain,
                                       subTitle: Localizable.Waves.Transactioncard.Title.scriptInvocation)
        }
    }
}

private extension DomainLayer.DTO.SmartTransaction {
    // MARK: - Sent Sections

    func sentSection(transfer: DomainLayer.DTO.SmartTransaction.Transfer, core: TransactionCard.State.Core) -> [Types.Section] {
        transferSection(transfer: transfer,
                        generalTitle: Localizable.Waves.Transactioncard.Title.sent,
                        addressTitle: Localizable.Waves.Transactioncard.Title.sentTo,
                        balanceSign: .minus,
                        core: core,
                        needSendAgain: transfer.asset.isGateway == false)
    }

    // MARK: - Receive Sections

    func receiveSection(transfer: DomainLayer.DTO.SmartTransaction.Transfer,
                        core: TransactionCard.State.Core) -> [Types.Section] {
        if transfer.hasSponsorship {
            return receivedSponsorshipSection(transfer: transfer)
        }

        return transferSection(transfer: transfer,
                               generalTitle: Localizable.Waves.Transactioncard.Title.received,
                               addressTitle: Localizable.Waves.Transactioncard.Title.receivedFrom,
                               balanceSign: .plus,
                               core: core)
    }

    // MARK: - SpamReceive Sections

    func spamReceiveSection(transfer: DomainLayer.DTO.SmartTransaction.Transfer,
                            core: TransactionCard.State.Core) -> [Types.Section] {
        transferSection(transfer: transfer,
                        generalTitle: Localizable.Waves.Transactioncard.Title.spamReceived,
                        addressTitle: Localizable.Waves.Transactioncard.Title.receivedFrom,
                        balanceSign: .plus,
                        core: core)
    }

    // MARK: - SelfTransfer Sections

    func selfTransferSection(transfer: DomainLayer.DTO.SmartTransaction.Transfer,
                             core: TransactionCard.State.Core) -> [Types.Section] {
        transferSection(transfer: transfer,
                        generalTitle: Localizable.Waves.Transactioncard.Title.selfTransfer,
                        addressTitle: Localizable.Waves.Transactioncard.Title.receivedFrom,
                        balanceSign: .plus,
                        core: core)
    }

    // MARK: - Sponsorship Sections

    func sponsorshipSection(asset: DomainLayer.DTO.SmartTransaction.Asset,
                            isEnabled: Bool) -> [Types.Section] {
        var rows: [Types.Row] = .init()

        let title = isEnabled ? Localizable.Waves.Transactioncard.Title.setSponsorship :
            Localizable.Waves.Transactioncard.Title.disableSponsorship

        let rowGeneralModel = TransactionCardGeneralCell.Model(image: kind.image,
                                                               title: title,
                                                               info: .descriptionLabel(asset.displayName))

        rows.append(contentsOf: [.general(rowGeneralModel)])

        let rowAssetModel = TransactionCardAssetDetailCell.Model(assetId: asset.id,
                                                                 isReissuable: nil)

        rows.append(.assetDetail(rowAssetModel))

        let balance = DomainLayer.DTO.Balance(currency: .init(title: asset.displayName,
                                                              ticker: asset.ticker),
                                              money: Money(asset.minSponsoredFee,
                                                           asset.precision))

        if isEnabled {
            let rowSponsorshipModel = TransactionCardSponsorshipDetailCell
                .Model(balance: .init(balance: balance,
                                      sign: DomainLayer.DTO.Balance.Sign.none,
                                      style: .small))

            rows.append(.sponsorshipDetail(rowSponsorshipModel))
        }

        var buttonsActions: [TransactionCardActionsCell.Model.Button] = .init()

        buttonsActions.append(contentsOf: [.viewOnExplorer, .copyTxID, .copyAllData])

        let rowActionsModel = TransactionCardActionsCell.Model(buttons: buttonsActions)

        rows.append(contentsOf: [.keyValue(rowBlockModel()),
                                 .keyValue(rowConfirmationsModel),
                                 .keyBalance(rowFeeModel),
                                 .keyValue(rowTimestampModel),
                                 .status(rowStatusModel),
                                 .dashedLine(.topPadding),
                                 .actions(rowActionsModel)])

        let section = Types.Section(rows: rows)

        return [section]
    }

    // MARK: - Set Asset Script Sections

    func setAssetScriptSection(asset: DomainLayer.DTO.SmartTransaction.Asset) -> [Types.Section] {
        var rows: [Types.Row] = .init()

        let rowGeneralModel = TransactionCardGeneralCell.Model(
            image: kind.image,
            title: Localizable.Waves.Transactioncard.Title.entryInBlockchain,
            info: .descriptionLabel(Localizable.Waves.Transactioncard.Title.setAssetScript))

        let rowAssetModel = TransactionCardAssetCell.Model(asset: asset)

        var buttonsActions: [TransactionCardActionsCell.Model.Button] = .init()

        buttonsActions.append(contentsOf: [.viewOnExplorer, .copyTxID, .copyAllData])

        let rowActionsModel = TransactionCardActionsCell.Model(buttons: buttonsActions)

        rows.append(contentsOf: [.general(rowGeneralModel),
                                 .asset(rowAssetModel),
                                 .keyValue(rowBlockModel()),
                                 .keyValue(rowConfirmationsModel),
                                 .keyBalance(rowFeeModel),
                                 .keyValue(rowTimestampModel),
                                 .status(rowStatusModel),
                                 .dashedLine(.topPadding),
                                 .actions(rowActionsModel)])

        let section = Types.Section(rows: rows)

        return [section]
    }

    // MARK: - Received Sponsorship Sections

    func receivedSponsorshipSection(transfer: DomainLayer.DTO.SmartTransaction.Transfer) -> [Types.Section] {
        var rows: [Types.Row] = .init()

        let rowGeneralModel = TransactionCardGeneralCell.Model(image: kind.image,
                                                               title: Localizable.Waves.Transactioncard.Title.receivedSponsorship,
                                                               info: .balance(.init(balance: transfer.balance,
                                                                                    sign: .plus,
                                                                                    style: .large)))

        rows.append(contentsOf: [.general(rowGeneralModel)])

        let rowAssetModel = TransactionCardAssetDetailCell.Model(assetId: transfer.asset.id,
                                                                 isReissuable: nil)

        rows.append(.assetDetail(rowAssetModel))

        if let attachment = transfer.attachment, attachment.isNotEmpty {
            let rowDescriptionModel = TransactionCardDescriptionCell.Model(description: attachment)
            rows.append(.description(rowDescriptionModel))
        }

        var buttonsActions: [TransactionCardActionsCell.Model.Button] = .init()

        buttonsActions.append(contentsOf: [.viewOnExplorer, .copyTxID, .copyAllData])

        let rowActionsModel = TransactionCardActionsCell.Model(buttons: buttonsActions)

        rows.append(contentsOf: [.keyValue(rowBlockModel()),
                                 .keyValue(rowConfirmationsModel),
                                 .keyBalance(rowFeeModel),
                                 .keyValue(rowTimestampModel),
                                 .status(rowStatusModel),
                                 .dashedLine(.topPadding),
                                 .actions(rowActionsModel)])

        let section = Types.Section(rows: rows)

        return [section]
    }

    // MARK: - invokescript

    func invokeScriptSection(tx: DomainLayer.DTO.SmartTransaction.InvokeScript,
                             title: String,
                             subTitle: String) -> [Types.Section] {
        var rows: [Types.Row] = .init()

        let rowGeneralModel = TransactionCardGeneralCell.Model(image: kind.image,
                                                               title: title,
                                                               info: .descriptionLabel(subTitle))

        var buttonsActions: [TransactionCardActionsCell.Model.Button] = .init()

        buttonsActions.append(contentsOf: [.viewOnExplorer, .copyTxID, .copyAllData])

        let rowActionsModel = TransactionCardActionsCell.Model(buttons: buttonsActions)

        rows.append(contentsOf: [.general(rowGeneralModel),
                                 .invokeScript(tx),
                                 .keyValue(rowBlockModel()),
                                 .keyValue(rowConfirmationsModel),
                                 .keyBalance(rowFeeModel),
                                 .keyValue(rowTimestampModel),
                                 .status(rowStatusModel),
                                 .dashedLine(.topPadding),
                                 .actions(rowActionsModel)])

        let section = Types.Section(rows: rows)

        return [section]
    }

    // MARK: - Deffault Sections

    func deffaultSection(title: String,
                         description: String) -> [Types.Section] {
        var rows: [Types.Row] = .init()

        let rowGeneralModel = TransactionCardGeneralCell.Model(image: kind.image,
                                                               title: title,
                                                               info: .descriptionLabel(description))

        var buttonsActions: [TransactionCardActionsCell.Model.Button] = .init()

        buttonsActions.append(contentsOf: [.viewOnExplorer, .copyTxID, .copyAllData])

        let rowActionsModel = TransactionCardActionsCell.Model(buttons: buttonsActions)

        rows.append(contentsOf: [.general(rowGeneralModel),
                                 .dashedLine(.nonePadding),
                                 .keyValue(rowBlockModel()),
                                 .keyValue(rowConfirmationsModel),
                                 .keyBalance(rowFeeModel),
                                 .keyValue(rowTimestampModel),
                                 .status(rowStatusModel),
                                 .dashedLine(.topPadding),
                                 .actions(rowActionsModel)])

        let section = Types.Section(rows: rows)

        return [section]
    }

    // MARK: - Issue Sections

    func issueSection(transfer: DomainLayer.DTO.SmartTransaction.Issue,
                      title: String,
                      balanceSign: DomainLayer.DTO.Balance.Sign) -> [Types.Section] {
        var rows: [Types.Row] = .init()

        let rowGeneralModel = TransactionCardGeneralCell.Model(image: kind.image,
                                                               title: title,
                                                               info: .balance(.init(balance: transfer.balance,
                                                                                    sign: balanceSign,
                                                                                    style: .large)))

        rows.append(contentsOf: [.general(rowGeneralModel)])

        let rowAssetModel = TransactionCardAssetDetailCell.Model(assetId: transfer.asset.id,
                                                                 isReissuable: transfer.asset.isReusable)

        rows.append(.assetDetail(rowAssetModel))

        if let description = transfer.description, description.isNotEmpty {
            let rowDescriptionModel = TransactionCardDescriptionCell.Model(description: description)
            rows.append(.description(rowDescriptionModel))
        }

        var buttonsActions: [TransactionCardActionsCell.Model.Button] = .init()

        buttonsActions.append(contentsOf: [.viewOnExplorer, .copyTxID, .copyAllData])

        let rowActionsModel = TransactionCardActionsCell.Model(buttons: buttonsActions)

        rows.append(contentsOf: [.keyValue(rowBlockModel(isLargePadding: true)),
                                 .keyValue(rowConfirmationsModel),
                                 .keyBalance(rowFeeModel),
                                 .keyValue(rowTimestampModel),
                                 .status(rowStatusModel),
                                 .dashedLine(.topPadding),
                                 .actions(rowActionsModel)])

        let section = Types.Section(rows: rows)

        return [section]
    }

    // MARK: - Exchange Sections

    func exchangeSection(transfer: DomainLayer.DTO.SmartTransaction.Exchange) -> [Types.Section] {
        var rows: [Types.Row] = .init()

        let myOrder = transfer.myOrder
        var sign: DomainLayer.DTO.Balance.Sign = .none
        var title = ""
        var viewModelEchange: TransactionCardExchangeCell.Model.Kind!

        let priceDisplayName = transfer.myOrder.pair.priceAsset.displayName
        let amountDisplayName = transfer.myOrder.pair.amountAsset.displayName

        if myOrder.kind == .sell {
            sign = .minus
            title = Localizable.Waves.Transactioncard.Title.Exchange.sellPair(amountDisplayName, priceDisplayName)
            viewModelEchange = .buy(.init(balance: transfer.total, sign: nil, style: .small))
        } else {
            sign = .plus
            viewModelEchange = .sell(.init(balance: transfer.total, sign: nil, style: .small))
            title = Localizable.Waves.Transactioncard.Title.Exchange.buyPair(amountDisplayName, priceDisplayName)
        }

        let rowGeneralModel = TransactionCardGeneralCell.Model(image: kind.image,
                                                               title: title,
                                                               info: .balance(.init(balance: transfer.amount,
                                                                                    sign: sign,
                                                                                    style: .large)))

        rows.append(contentsOf: [.general(rowGeneralModel)])

        let rowExchangeModel = TransactionCardExchangeCell.Model(amount: viewModelEchange,
                                                                 price: .init(balance: transfer.price,
                                                                              sign: nil,
                                                                              style: .small))

        rows.append(contentsOf: [.exchange(rowExchangeModel)])

        var buttonsActions: [TransactionCardActionsCell.Model.Button] = .init()

        buttonsActions.append(contentsOf: [.viewOnExplorer, .copyTxID, .copyAllData])

        let rowActionsModel = TransactionCardActionsCell.Model(buttons: buttonsActions)

        rows.append(contentsOf: [.keyValue(rowBlockModel(isLargePadding: true)),
                                 .keyValue(rowConfirmationsModel),
                                 .exchangeFee(rowExchangeFeeModel(tx: transfer)),
                                 .keyValue(rowTimestampModel),
                                 .status(rowStatusModel),
                                 .dashedLine(.topPadding),
                                 .actions(rowActionsModel)])

        let section = Types.Section(rows: rows)

        return [section]
    }

    func rowExchangeFeeModel(tx: DomainLayer.DTO.SmartTransaction.Exchange) -> TransactionCardExchangeFeeCell.Model {
        var fee1: BalanceLabel.Model
        var fee2: BalanceLabel.Model?

        if tx.order1.sender == tx.order2.sender {
            fee1 = BalanceLabel.Model(balance: tx.sellMatcherFee, sign: nil, style: .small)
            fee2 = BalanceLabel.Model(balance: tx.buyMatcherFee, sign: nil, style: .small)
        } else {
            if tx.myOrder.kind == .sell {
                fee1 = BalanceLabel.Model(balance: tx.sellMatcherFee, sign: nil, style: .small)
            } else {
                fee1 = BalanceLabel.Model(balance: tx.buyMatcherFee, sign: nil, style: .small)
            }
        }

        return .init(fee1: fee1, fee2: fee2)
    }

    // MARK: - Leasing Sections

    func leasingSection(transfer: DomainLayer.DTO.SmartTransaction.Leasing,
                        title: String,
                        titleContact: String = "",
                        needCancelLeasing: Bool,
                        core: Types.State.Core) -> [Types.Section] {
        var rows: [Types.Row] = .init()

        let rowGeneralModel = TransactionCardGeneralCell.Model(image: kind.image,
                                                               title: title,
                                                               info: .balance(.init(balance: transfer.balance,
                                                                                    sign: nil,
                                                                                    style: .large)))

        rows.append(contentsOf: [.general(rowGeneralModel)])

        let address = transfer.account.address

        let contact = core.normalizedContact(by: address,
                                             externalContact: transfer.account.contact)

        let name = contact?.name

        let isEditName = name != nil

        let rowAddressModel = TransactionCardAddressCell.Model(contact: contact,
                                                               contactDetail: .init(title: titleContact,
                                                                                    address: address,
                                                                                    name: name),
                                                               isSpam: transfer.asset.isSpam,
                                                               isEditName: isEditName)

        rows.append(contentsOf: [.address(rowAddressModel)])

        var buttonsActions: [TransactionCardActionsCell.Model.Button] = .init()

        if needCancelLeasing, status == .activeNow {
            buttonsActions.append(.cancelLeasing)
        }

        buttonsActions.append(contentsOf: [.viewOnExplorer, .copyTxID, .copyAllData])

        let rowActionsModel = TransactionCardActionsCell.Model(buttons: buttonsActions)

        rows.append(contentsOf: [.keyValue(rowBlockModel(isLargePadding: true)),
                                 .keyValue(rowConfirmationsModel),
                                 .keyBalance(rowFeeModel),
                                 .keyValue(rowTimestampModel),
                                 .status(rowStatusModel),
                                 .dashedLine(.topPadding),
                                 .actions(rowActionsModel)])

        let section = Types.Section(rows: rows)

        return [section]
    }

    // MARK: - Mass Received Sections

    func massReceivedSection(transfer: DomainLayer.DTO.SmartTransaction.MassReceive,
                             core: Types.State.Core) -> [Types.Section] {
        var rows: [Types.Row] = .init()

        let rowGeneralModel = TransactionCardGeneralCell.Model(image: kind.image,
                                                               title: Localizable.Waves.Transactioncard.Title.massReceived,
                                                               info: .balance(.init(balance: transfer.myTotal,
                                                                                    sign: .plus,
                                                                                    style: .large)))

        rows.append(contentsOf: [.general(rowGeneralModel)])

        let isSpam = transfer.asset.isSpam

        var visibleRecipients: [DomainLayer.DTO.SmartTransaction.MassReceive.Transfer] = transfer.transfers

        if core.showingAllRecipients == false {
            visibleRecipients = Array(transfer.transfers.prefix(Constants.maxVisibleRecipients))
        }

        for element in visibleRecipients.enumerated() {
            let tx = element.element
            let rowRecipientModel = tx.createTransactionCardAddressCell(isSpam: isSpam, core: core)
            rows.append(.address(rowRecipientModel))
        }

        if core.showingAllRecipients == false, transfer.transfers.count > Constants.maxVisibleRecipients {
            let countOtherTransactions = transfer.transfers.count - Constants.maxVisibleRecipients
            let model = TransactionCardShowAllCell.Model(countOtherTransactions: countOtherTransactions)
            rows.append(.showAll(model))
        }

        if let attachment = transfer.attachment, attachment.isNotEmpty {
            let rowDescriptionModel = TransactionCardDescriptionCell.Model(description: attachment)
            rows.append(.description(rowDescriptionModel))
        }

        var buttonsActions: [TransactionCardActionsCell.Model.Button] = .init()

        buttonsActions.append(contentsOf: [.viewOnExplorer, .copyTxID, .copyAllData])

        let rowActionsModel = TransactionCardActionsCell.Model(buttons: buttonsActions)

        rows.append(contentsOf: [.keyValue(rowBlockModel()),
                                 .keyValue(rowConfirmationsModel),
                                 .keyBalance(rowFeeModel),
                                 .keyValue(rowTimestampModel),
                                 .status(rowStatusModel),
                                 .dashedLine(.topPadding),
                                 .actions(rowActionsModel)])

        let section = Types.Section(rows: rows)

        return [section]
    }

    // MARK: - MassSent Sections

    func massSentSection(transfer: DomainLayer.DTO.SmartTransaction.MassTransfer,
                         core: Types.State.Core) -> [Types.Section] {
        var rows: [Types.Row] = .init()

        let rowGeneralModel = TransactionCardGeneralCell.Model(image: kind.image,
                                                               title: Localizable.Waves.Transactioncard.Title.massSent,
                                                               info: .balance(.init(balance: transfer.total,
                                                                                    sign: .minus,
                                                                                    style: .large)))

        rows.append(contentsOf: [.general(rowGeneralModel)])

        var visibleTransfers: [DomainLayer.DTO.SmartTransaction.MassTransfer.Transfer] = transfer.transfers

        if core.showingAllRecipients == false {
            visibleTransfers = Array(transfer.transfers.prefix(Constants.maxVisibleRecipients))
        }

        for element in visibleTransfers.enumerated() {
            let rowRecipientModel = element
                .element
                .createTransactionCardMassSentRecipientModel(currency: transfer.total.currency,
                                                             number: element.offset + 1,
                                                             core: core)

            rows.append(.massSentRecipient(rowRecipientModel))
        }

        if core.showingAllRecipients == false, transfer.transfers.count > Constants.maxVisibleRecipients {
            let countOtherTransactions = transfer.transfers.count - Constants.maxVisibleRecipients
            let model = TransactionCardShowAllCell.Model(countOtherTransactions: countOtherTransactions)
            rows.append(.showAll(model))
        }

        if let attachment = transfer.attachment, attachment.isNotEmpty {
            let rowDescriptionModel = TransactionCardDescriptionCell.Model(description: attachment)
            rows.append(.description(rowDescriptionModel))
        }

        var buttonsActions: [TransactionCardActionsCell.Model.Button] = .init()

        buttonsActions.append(contentsOf: [.viewOnExplorer, .copyTxID, .copyAllData])

        let rowActionsModel = TransactionCardActionsCell.Model(buttons: buttonsActions)

        rows.append(contentsOf: [.keyValue(rowBlockModel()),
                                 .keyValue(rowConfirmationsModel),
                                 .keyBalance(rowFeeModel),
                                 .keyValue(rowTimestampModel),
                                 .status(rowStatusModel),
                                 .dashedLine(.topPadding),
                                 .actions(rowActionsModel)])

        let section = Types.Section(rows: rows)

        return [section]
    }

    // MARK: - Transfer Sections

    func transferSection(transfer: DomainLayer.DTO.SmartTransaction.Transfer,
                         generalTitle: String,
                         addressTitle: String,
                         balanceSign: DomainLayer.DTO.Balance.Sign,
                         core: TransactionCard.State.Core,
                         needSendAgain: Bool = false) -> [Types.Section] {
        var rows: [Types.Row] = .init()

        let isSpam = transfer.asset.isSpam

        let rowGeneralModel = TransactionCardGeneralCell.Model(image: kind.image,
                                                               title: generalTitle,
                                                               info: .balance(.init(balance: transfer.balance,
                                                                                    sign: balanceSign,
                                                                                    style: .large)))

        rows.append(.general(rowGeneralModel))

        if isSelfTransfer == false {
            let address = transfer.recipient.address

            let contact = core.normalizedContact(by: address,
                                                 externalContact: transfer.recipient.contact)

            let name = contact?.name
            let isEditName = name != nil

            let rowAddressModel = TransactionCardAddressCell.Model(contact: contact,
                                                                   contactDetail: .init(title: addressTitle,
                                                                                        address: address,
                                                                                        name: name),
                                                                   isSpam: isSpam,
                                                                   isEditName: isEditName)
            rows.append(.address(rowAddressModel))
        }

        var isLargePadding: Bool = true

        if let attachment = transfer.attachment, attachment.isNotEmpty {
            let rowDescriptionModel = TransactionCardDescriptionCell.Model(description: attachment)
            rows.append(.description(rowDescriptionModel))
            isLargePadding = false
        }

        var buttonsActions: [TransactionCardActionsCell.Model.Button] = .init()

        if needSendAgain, status == .completed {
            buttonsActions.append(.sendAgain)
        }

        buttonsActions.append(contentsOf: [.viewOnExplorer, .copyTxID, .copyAllData])

        let rowActionsModel = TransactionCardActionsCell.Model(buttons: buttonsActions)

        rows.append(contentsOf: [.keyValue(rowBlockModel(isLargePadding: isLargePadding)),
                                 .keyValue(rowConfirmationsModel),
                                 .keyBalance(rowFeeModel),
                                 .keyValue(rowTimestampModel),
                                 .status(rowStatusModel),
                                 .dashedLine(.topPadding),
                                 .actions(rowActionsModel)])

        let section = Types.Section(rows: rows)

        return [section]
    }

    func rowBlockModel(isLargePadding: Bool = false) -> TransactionCardKeyValueCell.Model {
        let height = self.height ?? 0

        let padding: TransactionCardKeyValueCell.Model.Style.Padding = isLargePadding == true ? .largePadding : .normalPadding

        return TransactionCardKeyValueCell.Model(key: Localizable.Waves.Transactioncard.Title.block,
                                                 value: "\(height)",
                                                 style: .init(padding: padding, textColor: .black))
    }

    var rowConfirmationsModel: TransactionCardKeyValueCell.Model {
        TransactionCardKeyValueCell.Model(key: Localizable.Waves.Transactioncard.Title.confirmations,
                                          value: "\(String(describing: confirmationHeight))",
                                          style: .init(padding: .normalPadding, textColor: .black))
    }

    var rowFeeModel: TransactionCardKeyBalanceCell.Model {
        TransactionCardKeyBalanceCell.Model(key: Localizable.Waves.Transactioncard.Title.fee,
                                            value: BalanceLabel.Model(balance: totalFee,
                                                                      sign: nil,
                                                                      style: .small),
                                            style: .normalPadding)
    }

    var rowTimestampModel: TransactionCardKeyValueCell.Model {
        let formatter = DateFormatter.uiSharedFormatter(key: TransactionCard.Constants.transactionCardDateFormatterKey)
        formatter.dateFormat = Localizable.Waves.Transactioncard.Timestamp.format
        let timestampValue = formatter.string(from: timestamp)

        return TransactionCardKeyValueCell.Model(key: Localizable.Waves.Transactioncard.Title.timestamp,
                                                 value: timestampValue,
                                                 style: .init(padding: .normalPadding, textColor: .black))
    }

    var rowStatusModel: TransactionCardStatusCell.Model {
        switch status {
        case .activeNow:
            return .activeNow

        case .completed:
            return .completed

        case .unconfirmed:
            return .unconfirmed
        }
    }
}

extension Types.State.Core {
    func normalizedContact(by address: String, externalContact: DomainLayer.DTO.Contact?) -> DomainLayer.DTO.Contact? {
        if let mutation = contacts[address] {
            if case let .contact(newContact) = mutation {
                return newContact
            } else {
                return nil
            }
        } else {
            return externalContact
        }
    }
}

extension DomainLayer.DTO.SmartTransaction.MassReceive.Transfer {
    func createTransactionCardAddressCell(isSpam: Bool, core: TransactionCard.State.Core) -> TransactionCardAddressCell.Model {
        let address = recipient.address

        let contact = core.normalizedContact(by: address,
                                             externalContact: recipient.contact)

        let name = contact?.name
        let isEditName = name != nil

        let addressTitle = Localizable.Waves.Transactioncard.Title.receivedFrom

        let contactDetail = ContactDetailView.Model(title: addressTitle, address: address, name: name)
        let rowRecipientModel = TransactionCardAddressCell.Model(contact: recipient.contact,
                                                                 contactDetail: contactDetail,
                                                                 isSpam: isSpam,
                                                                 isEditName: isEditName)

        return rowRecipientModel
    }
}

extension DomainLayer.DTO.SmartTransaction.MassTransfer.Transfer {
    func createTransactionCardMassSentRecipientModel(currency: DomainLayer.DTO.Balance.Currency,
                                                     number: Int,
                                                     core: TransactionCard.State.Core)
        -> TransactionCardMassSentRecipientCell.Model {
        let address = recipient.address

        let contact = core.normalizedContact(by: address, externalContact: recipient.contact)

        let name = contact?.name
        let isEditName = name != nil

        let balance = DomainLayer.DTO.Balance(currency: currency, money: amount)

        let addressTitle = Localizable.Waves.Transactioncard.Title.recipient("\(number)")

        let contactDetail = ContactDetailView.Model(title: addressTitle, address: address, name: name)
        let balanceModel = BalanceLabel.Model(balance: balance, sign: nil, style: .small)
        let rowRecipientModel = TransactionCardMassSentRecipientCell.Model(contact: contact,
                                                                           contactDetail: contactDetail,
                                                                           balance: balanceModel,
                                                                           isEditName: isEditName)

        return rowRecipientModel
    }
}

private extension DomainLayer.DTO.SmartTransaction {
    var isSelfTransfer: Bool {
        switch kind {
        case .selfTransfer:
            return true

        default:
            return false
        }
    }
}
