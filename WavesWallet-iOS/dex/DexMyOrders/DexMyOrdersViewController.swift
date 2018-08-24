//
//  DexMyOrdersViewController.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 8/15/18.
//  Copyright © 2018 Waves Platform. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxFeedback


private enum Constants {
    static let cornerTableRadius: CGFloat = 3
}

final class DexMyOrdersViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var tableContainer: UIView!
    
    private var sections: [DexMyOrders.ViewModel.Section] = []
    var presenter: DexMyOrdersPresenterProtocol!
    private let sendEvent: PublishRelay<DexMyOrders.Event> = PublishRelay<DexMyOrders.Event>()

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.registerHeaderFooter(type: DexMyOrdersHeaderView.self)
        setupFeedBack()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        setupCorners()
    }
}

// MARK: Feedback

fileprivate extension DexMyOrdersViewController {
    
    func setupFeedBack() {
        
        let feedback = bind(self) { owner, state -> Bindings<DexMyOrders.Event> in
            return Bindings(subscriptions: owner.subscriptions(state: state), events: owner.events())
        }
        
        let readyViewFeedback: DexMyOrdersPresenter.Feedback = { [weak self] _ in
            guard let strongSelf = self else { return Signal.empty() }
            return strongSelf.rx.viewWillAppear.take(1).map { _ in DexMyOrders.Event.readyView }.asSignal(onErrorSignalWith: Signal.empty())
        }
        presenter.system(feedbacks: [feedback, readyViewFeedback])
    }
    
    func events() -> [Signal<DexMyOrders.Event>] {
        return [sendEvent.asSignal()]
    }
    
    func subscriptions(state: Driver<DexMyOrders.State>) -> [Disposable] {
        let subscriptionSections = state
            .drive(onNext: { [weak self] state in
                
                guard let strongSelf = self else { return }
                guard state.action != .none else { return }
                
                strongSelf.sections = state.sections
                strongSelf.tableView.reloadData()
            })
        
        return [subscriptionSections]
    }
}


//MARK: - UITableViewDelegate
extension DexMyOrdersViewController: UITableViewDelegate {
   
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let headerModel = sections[section].header
        let header = tableView.dequeueHeaderFooter() as DexMyOrdersHeaderView
        header.update(with: headerModel)
        return header
    }
   
}

//MARK: - UITableViewDataSource
extension DexMyOrdersViewController: UITableViewDataSource {
    
   
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let row = sections[indexPath.section].items[indexPath.row]

        switch row {
        case .order(let myOrder):
            let cell = tableView.dequeueCell() as DexMyOrdersCell
            cell.update(with: myOrder)
            return cell
        }
    }
}

//MARK: - SetupUI

private extension DexMyOrdersViewController {
    
    func setupCorners() {
        
        let shadowPath = UIBezierPath(roundedRect: tableContainer.bounds,
                                      byRoundingCorners: [.topLeft, .topRight],
                                      cornerRadii: CGSize(width: Constants.cornerTableRadius, height: Constants.cornerTableRadius))
        let maskLayer = CAShapeLayer()
        maskLayer.path = shadowPath.cgPath
        tableContainer.layer.mask = maskLayer
    }
}
