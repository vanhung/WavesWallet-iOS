//
//  MyOrdersViewController.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 20.12.2019.
//  Copyright © 2019 Waves Platform. All rights reserved.
//

import DomainLayer
import Extensions
import MGSwipeTableCell
import RxCocoa
import RxFeedback
import RxSwift
import UIKit
import UITools

private enum Constants {
    static let deleteButtonWidth: CGFloat = 70
}

final class MyOrdersViewController: UIViewController {
    @IBOutlet private weak var scrolledTablesComponent: ScrolledContainerView!
    private let disposeBag: DisposeBag = DisposeBag()
    private var section = MyOrdersTypes.ViewModel.Section.empty

    private var transactionCardCoordinator: TransactionCardCoordinator?
    private var navigationRouter: NavigationRouter?

    var system: System<MyOrdersTypes.State, MyOrdersTypes.Event>!

    override func viewDidLoad() {
        super.viewDidLoad()

        createBackButton()
        title = Localizable.Waves.Dextradercontainer.Button.myOrders
        view.backgroundColor = .basic50

        scrolledTablesComponent.containerViewDelegate = self

        let segmentedItems = [Localizable.Waves.Dexmyorders.Label.all,
                              Localizable.Waves.Dexmyorders.Label.active,
                              Localizable.Waves.Dexmyorders.Label.closed,
                              Localizable.Waves.Dexmyorders.Label.cancelled]
        scrolledTablesComponent
            .setup(segmentedItems: segmentedItems.map { .title($0) }, tableDataSource: self, tableDelegate: self)

        setupSystem()
        setupCancelOrderButton()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        removeTopBarLine()
        for table in scrolledTablesComponent.tableViews {
            table.startSkeletonCells()
        }
        scrolledTablesComponent.viewControllerWillAppear()
    }

    @objc private func cancelAllOrders() {
        let vc = UIAlertController(title: Localizable.Waves.Myorders.Alert.Cancelallorders.title,
                                   message: Localizable.Waves.Myorders.Alert.Cancelallorders.subtitle,
                                   preferredStyle: .alert)

        let cancel = UIAlertAction(title: Localizable.Waves.Myorders.Alert.Button.no, style: .cancel, handler: nil)

        let action = UIAlertAction(title: Localizable.Waves.Myorders.Alert.Button.yes, style: .default) { _ in
            self.system.send(.cancelAllOrders)
        }
        vc.addAction(cancel)
        vc.addAction(action)
        present(vc, animated: true, completion: nil)
    }

    private func setupCancelOrderButton() {
        navigationItem
            .rightBarButtonItem = UIBarButtonItem(image: Images.deleteAllCopy.image, style: .plain, target: self,
                                                  action: #selector(cancelAllOrders))
        navigationItem.rightBarButtonItem?.isEnabled = section.activeItems.filter { $0.order != nil }.count > 0
    }

    private func setupSystem() {
        let readyViewFeedback: (Driver<MyOrdersTypes.State>) -> Signal<MyOrdersTypes.Event> = { [weak self] _ in
            guard let self = self else { return Signal.empty() }
            return self.rx.viewWillAppear.take(1)
                .map { _ in MyOrdersTypes.Event.readyView }
                .asSignal(onErrorSignalWith: Signal.empty())
        }

        let refreshEvent: (Driver<MyOrdersTypes.State>) -> Signal<MyOrdersTypes.Event> = { [weak self] _ in
            guard let self = self else { return Signal.empty() }
            return self.scrolledTablesComponent.rx
                .didRefreshing(refreshControl: self.scrolledTablesComponent.refreshControl!)
                .map { _ in MyOrdersTypes.Event.refresh }
                .asSignal(onErrorSignalWith: Signal.empty())
        }

        system
            .start(sideEffects: [readyViewFeedback, refreshEvent])
            .drive(onNext: { [weak self] state in

                guard let self = self else { return }
                switch state.uiAction {
                case .none:
                    return

                case let .ordersDidFinishCanceledSuccess(isMultipleOrders):
                    if isMultipleOrders {
                        self.showSuccesSnack(title: Localizable.Waves.Myorders.Message.Cancelorders.success)
                    } else {
                        self.showSuccesSnack(title: Localizable.Waves.Myorders.Message.Cancelorder.success)
                    }

                case let .ordersDidFinishCanceledError(error):

                    switch error {
                    case .internetNotWorking:
                        self.showWithoutInternetSnackWithoutAction()

                    case let .message(message):
                        self.showErrorSnack(title: message)

                    default:
                        self.showErrorNotFoundSnack()
                    }

                default:
                    break
                }

                self.section = state.section
                self.scrolledTablesComponent.reloadData()
                self.setupCancelOrderButton()

                DispatchQueue.main.async {
                    self.scrolledTablesComponent.endRefreshing()
                }
            })
            .disposed(by: disposeBag)
    }

    private func showDetailScreen(order: DomainLayer.DTO.Dex.MyOrder) {
        guard let navigationController = self.navigationController else { return }
        let nav = NavigationRouter(navigationController: navigationController)
        let coordinator = TransactionCardCoordinator(kind: .order(order), router: nav)

        // TODO: Move code to parent Coordinat
        navigationRouter = nav
        transactionCardCoordinator = coordinator
        coordinator.delegate = self
        coordinator.start()
    }
}

// MARK: - ScrolledContainerViewDelegate

extension MyOrdersViewController: ScrolledContainerViewDelegate {
    func scrolledContainerViewDidScrollToIndex(_: Int) {
        DispatchQueue.main.async {
            self.scrolledTablesComponent.endRefreshing()
        }
    }
}

// MARK: - UITableViewDelegate

extension MyOrdersViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = section.items(tableIndex: tableView.tag)[indexPath.row]

        switch row {
        case let .order(order):
            showDetailScreen(order: order)
        default:
            break
        }
    }
}

// MARK: - UITableViewDataSource

extension MyOrdersViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = section.items(tableIndex: tableView.tag)[indexPath.row]
        switch row {
        case .order:
            return DexMyOrdersCell.viewHeight()

        case .skeleton:
            return MyOrdersSkeletonCell.viewHeight()

        case .emptyData:
            return tableView.frame.size.height / 2 + MyOrdersEmptyDataCell.viewHeight() / 2
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection _: Int) -> Int {
        return section.items(tableIndex: tableView.tag).count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = section.items(tableIndex: tableView.tag)[indexPath.row]

        switch row {
        case let .order(myOrder):
            let cell = tableView.dequeueAndRegisterCell() as DexMyOrdersCell
            cell.update(with: .init(order: myOrder, index: indexPath.row))
            cell.delegate = self
            return cell

        case .skeleton:
            return tableView.dequeueAndRegisterCell() as MyOrdersSkeletonCell

        case .emptyData:
            return tableView.dequeueAndRegisterCell() as MyOrdersEmptyDataCell
        }
    }
}

// MARK: - TransactionCardCoordinator

extension MyOrdersViewController: TransactionCardCoordinatorDelegate {
    func transactionCardCoordinatorCanceledOrder(_: DomainLayer.DTO.Dex.MyOrder) {
        system.send(.refresh)
    }
}

// MARK: - MGSwipeTableCellDelegate

extension MyOrdersViewController: MGSwipeTableCellDelegate {
    func swipeTableCell(_ cell: MGSwipeTableCell, canSwipe _: MGSwipeDirection, from _: CGPoint) -> Bool {
        guard let indexPath = scrolledTablesComponent.visibleTableView.indexPath(for: cell) else { return false }

        let row = section.items(tableIndex: scrolledTablesComponent.visibleTableView.tag)[indexPath.row]

        if let order = row.order {
            return order.isActive
        }

        return false
    }

    func swipeTableCell(_ cell: MGSwipeTableCell, tappedButtonAt index: Int, direction: MGSwipeDirection,
                        fromExpansion _: Bool) -> Bool {
        if direction == .rightToLeft {
            let row = section.items(tableIndex: scrolledTablesComponent.visibleTableView.tag)[index]

            if let order = row.order {
                let assetPair = order.amountAsset.displayName + "/" + order.priceAsset.displayName

                let vc = UIAlertController(title: Localizable.Waves.Myorders.Alert.Cancelorder.title,
                                           message: Localizable.Waves.Myorders.Alert.Cancelorder.subTitle(assetPair),
                                           preferredStyle: .alert)

                let cancel = UIAlertAction(title: Localizable.Waves.Myorders.Alert.Button.no, style: .cancel) { _ in
                    cell.hideSwipe(animated: true)
                }

                let action = UIAlertAction(title: Localizable.Waves.Myorders.Alert.Button.yes, style: .default) { _ in

                    self.system.send(.cancelOrder(order))
                    cell.hideSwipe(animated: true)
                }
                vc.addAction(cancel)
                vc.addAction(action)
                present(vc, animated: true, completion: nil)
            }
        }

        return false
    }

    func swipeTableCell(
        _: MGSwipeTableCell,
        swipeButtonsFor direction: MGSwipeDirection,
        swipeSettings _: MGSwipeSettings,
        expansionSettings _: MGSwipeExpansionSettings) -> [UIView]? {
        if direction == .rightToLeft {
            let delete = MGSwipeButton(title: "", icon: Images.closewhite.image, backgroundColor: .error400)
            delete.buttonWidth = Constants.deleteButtonWidth
            return [delete]
        }

        return nil
    }
}