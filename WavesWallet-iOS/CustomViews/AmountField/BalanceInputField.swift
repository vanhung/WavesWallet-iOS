//
//  AmountField.swift
//  WavesWallet-iOS
//
//  Created by rprokofev on 20.02.2020.
//  Copyright © 2020 Waves Platform. All rights reserved.
//

import UIKit
import Extensions
import DomainLayer

final class BalanceInputField: UIView, NibOwnerLoadable {
        
    enum Style {
        case normal
        case error
    }
    
    enum State {
        case empty(_ decimal: Int, _ currency: DomainLayer.DTO.Balance.Currency)
        case balance(DomainLayer.DTO.Balance)
    }
    
    struct Model {
        let style: Style
        let state: State
    }
    
    @IBOutlet private weak var numberTextField: MoneyTextField!
    @IBOutlet private var tickerView: TickerView!
    @IBOutlet private var separatorView: SeparatorView!

    var style: Style = .normal {
        didSet {
            setNeedUpdateStyle()
        }
    }
    
    var didChangeInput: ((_ value: Money) -> Void)?
            
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadNibContent()
        
    }
}


// MARK: - Private Methods
private extension BalanceInputField  {
    
    func setNeedUpdateStyle() {
        //TODO: Set cool colorSeparatorView
        switch style {
        case .normal:
            self.separatorView.lineColor = .black
        case .error:
            self.separatorView.lineColor = .red
        }
    }
}
    
    
// MARK: - ViewConfiguration

extension BalanceInputField: ViewConfiguration {
    
    func update(with model: Model) {

        self.style = model.style
                
        switch model.state {
        case .empty(let decimal, let currency):
            tickerView.update(with: .init(text: currency.displayText,
                                          style: .normal))
            numberTextField.setDecimals(decimal)
            numberTextField.clearInput()
            
        case .balance(let balance):
            
            tickerView.update(with: .init(text: balance.currency.displayText,
                                          style: .normal))
            
            numberTextField.value = balance.money
        }
    }
}

//TODO: MoneyTextFieldDelegate

extension BalanceInputField: MoneyTextFieldDelegate {
    
    func moneyTextField(_ textField: MoneyTextField, didChangeValue value: Money) {
        didChangeInput?(value)
    }
}
