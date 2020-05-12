//
//  EnterSelectAccountViewController.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 6/28/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import DomainLayer
import IdentityImg
import MGSwipeTableCell
import RxCocoa
import RxFeedback
import RxSwift
import UIKit
import UITools

private enum Constants {
    static let swipeButtonWidth: CGFloat = 72
    static let editButtonTag = 1000
    static let deleteButtonTag = 1001
}

final class ChooseAccountViewController: UIViewController {
    fileprivate typealias Types = ChooseAccountTypes

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var viewNoResult: UIView!
    @IBOutlet private weak var noResultInfoLabel: UILabel!

    private var eventInput: PublishSubject<Types.Event> = PublishSubject<Types.Event>()

    var presenter: ChooseAccountPresenterProtocol!

    private var wallets: [DomainLayer.DTO.Wallet] = .init()
    private let identity: Identity = Identity(options: Identity.defaultOptions)

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .basic50
        noResultInfoLabel.text = Localizable.Waves.Chooseaccount.Label.nothingWallets
        setupNavigation()

        setupSystem()
    }

    private func setupNavigation() {
        navigationItem.title = Localizable.Waves.Chooseaccount.Navigation.title
        setupBigNavigationBar()
        navigationItem
            .leftBarButtonItem = UIBarButtonItem(image: Images.btnBack.image.withRenderingMode(.alwaysOriginal), style: .plain,
                                                 target: self, action: #selector(backTapped))

        navigationItem
            .rightBarButtonItem = UIBarButtonItem(image: Images.topbarAdd.image.withRenderingMode(.alwaysOriginal), style: .plain,
                                                  target: self, action: #selector(tapAddAccount))
        removeTopBarLine()
    }

    @objc override func backTapped() {
        eventInput.onNext(.tapBack)
    }

    @objc func tapAddAccount() {
        eventInput.onNext(.tapAddAccount)
    }

    // MARK: - Content

    var swipeButtons: [UIView] {
        let edit = MGSwipeButton(title: "", icon: Images.editaddress24Submit300.image, backgroundColor: nil)
        edit.buttonWidth = Constants.swipeButtonWidth
        edit.tag = Constants.editButtonTag

        let delete = MGSwipeButton(title: "", icon: Images.deladdress24Error400.image, backgroundColor: nil)
        delete.buttonWidth = Constants.swipeButtonWidth
        delete.tag = Constants.deleteButtonTag

        return [delete, edit]
    }

    fileprivate var editButtonIndex: Int {
        return swipeButtons.firstIndex(where: { (view) -> Bool in
            view.tag == Constants.editButtonTag
        })!
    }

    fileprivate var deleteButtonIndex: Int {
        return swipeButtons.firstIndex(where: { (view) -> Bool in
            view.tag == Constants.deleteButtonTag
        })!
    }

    // MARK: - State

    fileprivate func reloadTableView() {
        tableView.reloadData()

        if !wallets.isEmpty {
            hideEmptyView()
        } else {
            showEmptyView()
        }
    }

    fileprivate func removeAccount(atIndexPath indexPath: IndexPath) {
        CATransaction.begin()

        CATransaction.setCompletionBlock {
            if !self.wallets.isEmpty {
                self.hideEmptyView()
            } else {
                self.showEmptyView()
            }
        }

        tableView.beginUpdates()

        tableView.deleteRows(at: [indexPath], with: .fade)

        tableView.endUpdates()
        CATransaction.commit()
    }

    // MARK: Actions

    fileprivate func deleteTap(atIndexPath indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? ChooseAccountCell else { return }

        UseCasesFactory
            .instance
            .analyticManager
            .trackEvent(.singIn(.startAccountDelete))

        let wallet = wallets[indexPath.row]

        let alert = UIAlertController(title: Localizable.Waves.Chooseaccount.Alert.Delete.title,
                                      message: Localizable.Waves.Chooseaccount.Alert.Delete.message,
                                      preferredStyle: .alert)

        let cancel = UIAlertAction(title: Localizable.Waves.Chooseaccount.Alert.Button.no, style: .cancel) { _ in
            cell.hideSwipe(animated: true)
        }

        let yes = UIAlertAction(title: Localizable.Waves.Chooseaccount.Alert.Button.ok, style: .default) { [weak self] _ in

            guard let self = self else { return }
            self.eventInput.onNext(.tapRemoveButton(wallet, indexPath: indexPath))
        }

        alert.addAction(cancel)
        alert.addAction(yes)

        present(alert, animated: true, completion: nil)
    }

    private func editTap(atIndexPath indexPath: IndexPath) {
        let wallet = wallets[indexPath.row]

        eventInput.onNext(.tapEditButton(wallet, indexPath: indexPath))

        UseCasesFactory
            .instance
            .analyticManager
            .trackEvent(.singIn(.startAccountEdit))
    }

    // MARK: Empty

    private func showEmptyView() {
        tableView.addSubview(viewNoResult)
        viewNoResult.setNeedsLayout()
        viewNoResult.frame.origin = CGPoint(x: (tableView.frame.width - viewNoResult.frame.width) * 0.5,
                                            y: (tableView.frame.height - viewNoResult.frame.height - layoutInsets.top) * 0.5)
        viewNoResult.alpha = 0
        UIView.animate(withDuration: UIView.fastDurationAnimation) {
            self.viewNoResult.alpha = 1
        }
    }

    private func hideEmptyView() {
        viewNoResult.removeFromSuperview()
    }
}

// MARK: RxFeedback

private extension ChooseAccountViewController {
    func setupSystem() {
        let uiFeedback: ChooseAccountPresenterProtocol.Feedback = bind(self) { (owner, state) -> (Bindings<Types.Event>) in
            Bindings(subscriptions: owner.subscriptions(state: state), events: owner.events())
        }

        let readyViewFeedback: ChooseAccountPresenterProtocol.Feedback = { [weak self] _ in
            guard let self = self else { return Signal.empty() }

            return self
                .rx
                .viewWillAppear
                .asObservable()
                .asSignal(onErrorSignalWith: Signal.empty())
                .map { _ in Types.Event.readyView }
        }

        let viewDidDisappearFeedback: ChooseAccountPresenterProtocol.Feedback = { [weak self] _ in
            guard let self = self else { return Signal.empty() }

            return self
                .rx
                .viewDidDisappear
                .asObservable()
                .asSignal(onErrorSignalWith: Signal.empty())
                .map { _ in Types.Event.viewDidDisappear }
        }

        presenter.system(feedbacks: [uiFeedback, readyViewFeedback, viewDidDisappearFeedback])
    }

    func events() -> [Signal<Types.Event>] {
        return [eventInput.asSignal(onErrorSignalWith: Signal.empty())]
    }

    func subscriptions(state: Driver<Types.State>) -> [Disposable] {
        let subscriptionSections = state.drive(onNext: { [weak self] state in

            guard let self = self else { return }

            self.updateView(with: state.displayState)
        })

        return [subscriptionSections]
    }

    func updateView(with state: Types.DisplayState) {
        if wallets.count != state.wallets.count {
            UseCasesFactory
                .instance
                .analyticManager
                .trackEvent(.singIn(.startAccountCounter(state.wallets.count)))
        }

        wallets = state.wallets

        switch state.action {
        case .reload:

            reloadTableView()

        case let .remove(indexPath):

            removeAccount(atIndexPath: indexPath)

        case .none:

            reloadTableView()
        }
    }
}

extension ChooseAccountViewController: UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return wallets.count
    }

    func numberOfSections(in _: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ChooseAccountCell = tableView.dequeueAndRegisterCell()
        let wallet = wallets[indexPath.row]

        let model = ChooseAccountCell.Model(
            title: wallet.name,
            address: wallet.address,
            image: identity.createImage(by: wallet.address, size: cell.imageIcon.frame.size))

        cell.update(with: model)
        cell.delegate = self

        return cell
    }
}

extension ChooseAccountViewController: UITableViewDelegate {
    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let wallet = wallets[indexPath.row]
        eventInput.onNext(.tapWallet(wallet))
    }
}

extension ChooseAccountViewController: MGSwipeTableCellDelegate {
    func swipeTableCell(_ cell: MGSwipeTableCell, tappedButtonAt index: Int, direction: MGSwipeDirection,
                        fromExpansion _: Bool) -> Bool {
        guard let indexPath = tableView.indexPath(for: cell) else { return false }

        if direction == .rightToLeft {
            if index == deleteButtonIndex {
                deleteTap(atIndexPath: indexPath)

            } else if index == editButtonIndex {
                editTap(atIndexPath: indexPath)
            }
        }

        return true
    }

    func swipeTableCell(
        _: MGSwipeTableCell,
        swipeButtonsFor direction: MGSwipeDirection,
        swipeSettings _: MGSwipeSettings,
        expansionSettings _: MGSwipeExpansionSettings) -> [UIView]? {
        if direction == .rightToLeft {
            return swipeButtons
        }

        return nil
    }
}
