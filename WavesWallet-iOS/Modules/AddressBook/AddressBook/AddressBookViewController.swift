//
//  AddressBookViewController.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 9/22/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxFeedback
import DomainLayer
import Extensions

final class AddressBookViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var searchBar: SearchBarView!
    @IBOutlet private weak var labelNoInfo: UILabel!
    @IBOutlet private weak var viewNoInfo: UIView!
    
    weak var delegate: AddressBookModuleOutput?
    var isEditMode: Bool = false
    
    var presenter: AddressBookPresenterProtocol!
    private var modelSection = AddressBookTypes.ViewModel.Section(items: [])
    private var isSearchMode: Bool = false
    private let sendEvent: PublishRelay<AddressBookTypes.Event> = PublishRelay<AddressBookTypes.Event>()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(image: Images.topbarAddaddress.image, style: .plain, target: self, action: #selector(addUserTapped))
        setupLocalization()
        createBackButton()
        setupFeedBack()
        tableView.keyboardDismissMode = .onDrag
        searchBar.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupSmallNavigationBar()
        removeTopBarLine()
        navigationItem.backgroundImage = UIImage()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationItem.backgroundImage = nil
    }
}

//MARK: - UI

private extension AddressBookViewController {
    
    func setupLocalization() {
        title = Localizable.Waves.Addressbook.Label.addressBook
        labelNoInfo.text = Localizable.Waves.Addressbook.Label.noInfo
    }

    func setupUIState() {
        let isEmpty = modelSection.isEmpty && !isSearchMode
        viewNoInfo.isHidden = !isEmpty
        tableView.isHidden = isEmpty
        searchBar.isHidden = isEmpty
    }


    func showEditContact(_ contact: DomainLayer.DTO.Contact) {
        let controller = AddAddressBookModuleBuilder(output: self).build(input: .init(kind: .edit(contact: contact, isMutable: true)))
        navigationController?.pushViewController(controller, animated: true)
    }
}

//MARK: - Actions
private extension AddressBookViewController {
    
    @objc func addUserTapped() {
        
        UseCasesFactory
            .instance
            .analyticManager
            .trackEvent(.addressBook(.profileAddressBookAdd))
        
        //TODO: Move to Coordinator
        let controller = AddAddressBookModuleBuilder(output: self).build(input: .init(kind: .add(nil, isMutable: true)))
        navigationController?.pushViewController(controller, animated: true)
    }
}

// MARK: Feedback

private extension AddressBookViewController {
    
    func setupFeedBack() {
        
        let feedback = bind(self) { owner, state -> Bindings<AddressBookTypes.Event> in
            return Bindings(subscriptions: owner.subscriptions(state: state), events: owner.events())            
        }
        
        let readyViewFeedback: AddressBookPresenter.Feedback = { [weak self] _ in
            guard let self = self else { return Signal.empty() }
            return self.rx.viewWillAppear.take(1).map { _ in AddressBookTypes.Event.readyView }.asSignal(onErrorSignalWith: Signal.empty())
        }
        presenter.system(feedbacks: [feedback, readyViewFeedback])
    }
    
    func events() -> [Signal<AddressBookTypes.Event>] {
        return [sendEvent.asSignal()]
    }
    
    func subscriptions(state: Driver<AddressBookTypes.State>) -> [Disposable] {
        let subscriptionSections = state
            .drive(onNext: { [weak self] state in
                
                guard let self = self else { return }
                guard state.action != .none else { return }
                self.modelSection = state.section
                self.tableView.reloadData()
                self.setupUIState()
            })
        
        return [subscriptionSections]
    }
}


// MARK: - SearchBarViewDelegate
extension AddressBookViewController: SearchBarViewDelegate {
    
    func searchBarDidChangeText(_ searchText: String) {
        isSearchMode = searchText.count > 0
        sendEvent.accept(.searchTextChange(text: searchText))
    }
}

// MARK: - UITableViewDelegate
extension AddressBookViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let contact = modelSection.items[indexPath.row].contact

        if isEditMode {
            showEditContact(contact)
        } else {
            delegate?.addressBookDidSelectContact(contact)
            navigationController?.popViewController(animated: true)
        }
    }
}

// MARK: - UITableViewDataSource
extension AddressBookViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return modelSection.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       
        let cell = tableView.dequeueCell() as AddressBookCell
        let contact = modelSection.items[indexPath.row].contact
        cell.update(with: .init(contact: contact, isEditMode: isEditMode))
        cell.delegate = self
        return cell
    }
}

//MARK: - AddressBookCellDelegate

extension AddressBookViewController: AddressBookCellDelegate {
    
    func addressBookCellDidTapEdit(_ cell: AddressBookCell) {
        
        if let indexPath = tableView.indexPath(for: cell) {
            
            UseCasesFactory
                .instance
                .analyticManager
                .trackEvent(.addressBook(.profileAddressBookEdit))
            
            let contact = modelSection.items[indexPath.row].contact
            showEditContact(contact)
        }
    }
}

extension AddressBookViewController: AddAddressBookModuleOutput {
       
    func addAddressBookDidDelete(contact: DomainLayer.DTO.Contact) {
        SuccessSystemMessageView.showWithMessage(Localizable.Waves.Addressbook.Label.addressDeleted)
    }
}
