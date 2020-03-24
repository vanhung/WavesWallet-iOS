//
//  DexCreateInputView.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 9/11/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import UIKit
import Extensions

private enum Constants {
    static let animationFrameDuration: TimeInterval = 0.3
    static let animationErrorLabelDuration: TimeInterval = 0.3

    static let textFieldDefaultOffset: CGFloat = 16
    static let textFieldMarketOffset: CGFloat = 28
}

protocol DexCreateOrderInputViewDelegate: AnyObject {
    func dexCreateOrder(inputView: DexCreateOrderInputView, didChangeValue value: Money)
}


final class DexCreateOrderInputView: UIView, NibOwnerLoadable {

    enum InputType {
        case `default`
        case market
    }
    
    private var isShowInputScrollView = false
    private var isHiddenErrorLabel = true
    
    @IBOutlet private weak var labelTitle: UILabel!
    @IBOutlet private weak var textField: MoneyTextField!
    @IBOutlet private weak var inputScrollView: InputScrollButtonsView!
    @IBOutlet private weak var viewTextField: UIView!
    @IBOutlet private weak var labelError: UILabel!
    @IBOutlet private weak var separatorView: UIView!
    @IBOutlet private weak var iconLock: UIImageView!
    @IBOutlet private weak var buttonPlus: DexCreateOrderAmountButton!
    @IBOutlet private weak var buttonMinus: DexCreateOrderAmountButton!
    @IBOutlet private weak var labelRound: UILabel!
    @IBOutlet private weak var textFieldLeftOffset: NSLayoutConstraint!
    
    weak var delegate: DexCreateOrderInputViewDelegate?
    var input:(() -> [Money])?
    var isShowInputWhenFilled = false
    var maximumFractionDigits: Int = 0 {
        didSet {
            textField.setDecimals(maximumFractionDigits, forceUpdateMoney: false)
        }
    }
    var inputType: InputType = .default {
        didSet {
            iconLock.isHidden = inputType == .default
            buttonMinus.isHidden = inputType == .market
            buttonPlus.isHidden = inputType == .market
            labelRound.isHidden = inputType == .default
            isUserInteractionEnabled = inputType == .default
            textFieldLeftOffset.constant = inputType == .default ? Constants.textFieldDefaultOffset : Constants.textFieldMarketOffset
            textField.textColor = inputType == .default ? .black : .disabled400
        }
    }
    
    var value: Money {
        return textField.value
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadNibContent()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        labelError.alpha = 0
        inputScrollView.inputDelegate = self
        textField.moneyDelegate = self
        textField.delegate = self
        hideInputScrollView(animation: false)
    }
    
    
    // MARK: - Methods
    func setupTitle(title: String) {
        labelTitle.text = title
    }

    
    func setupValue(_ value: Money) {
        textField.setValue(value: value)
        updateViewHeight(inputValue: value, animation: false)
    }
    
    func showErrorMessage(message: String, isShow: Bool) {
    
        if isShow {
            labelError.text = message
            
            if isHiddenErrorLabel {
                isHiddenErrorLabel = false
                UIView.animate(withDuration: Constants.animationErrorLabelDuration) {
                    self.labelError.alpha = 1
                }
            }
        }
        else {
            if !isHiddenErrorLabel {
                isHiddenErrorLabel = true
                
                UIView.animate(withDuration: Constants.animationErrorLabelDuration) {
                    self.labelError.alpha = 0
                }
            }
        }
    }
}

// MARK: - ViewConfiguration

extension DexCreateOrderInputView: ViewConfiguration {

    func update(with input: [String]) {
        
        isShowInputScrollView = input.count > 0
        inputScrollView.update(with: input)
        updateViewHeight(inputValue: textField.value, animation: true)
    }
}

// MARK: - InputNumericTextFieldDelegate
extension DexCreateOrderInputView: MoneyTextFieldDelegate {
  
    func moneyTextField(_ textField: MoneyTextField, didChangeValue value: Money) {
        textFieldDidChangeNewValue()
    }
    func moneyTextFieldShouldReturn() -> Bool { true }
}

// MARK: - UITextFieldDelegate
extension DexCreateOrderInputView: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        separatorView.backgroundColor = .submit400
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        separatorView.backgroundColor = .accent100
    }
}

// MARK: - InputScrollButtonsViewDelegate
extension DexCreateOrderInputView: InputScrollButtonsViewDelegate {
    
    func updateAmount(_ amount: Money) {
        if !isShowInputWhenFilled {
            hideInputScrollView(animation: true)
        }
        
        textField.setValue(value: amount)
        textFieldDidChangeNewValue()
    }
    
    func inputScrollButtonsViewDidTapAt(index: Int) {
        if !isShowInputWhenFilled {
            hideInputScrollView(animation: true)
        }
        
        if let values = input, values().count > index {
            let value = values()[index]
            textField.setValue(value: value)
            textFieldDidChangeNewValue()
        }
    }
}

// MARK: - Actions
private extension DexCreateOrderInputView {
   
    @IBAction func plusTapped(_ sender: Any) {
        textField.addPlusValue()
        
        textFieldDidChangeNewValue()
    }
    
    @IBAction func minusTapped(_ sender: Any) {
        textField.addMinusValue()
        textFieldDidChangeNewValue()
    }
    
    func textFieldDidChangeNewValue() {
        
        delegate?.dexCreateOrder(inputView: self, didChangeValue: textField.value)
        updateViewHeight(inputValue: textField.value, animation: true)
    }
}

// MARK: - Change frame
private extension DexCreateOrderInputView {
    
    func updateViewHeight(inputValue: Money, animation: Bool) {
        
        if isShowInputScrollView {
            if isShowInputWhenFilled {
                showInputScrollView(animation: animation)
            }
            else {
                if inputValue.isZero {
                    showInputScrollView(animation: animation)
                }
                else {
                    hideInputScrollView(animation: animation)
                }
            }
        }
        else {
            hideInputScrollView(animation: animation)
        }
    }
    
    func showInputScrollView(animation: Bool) {
        
        let height = inputScrollView.frame.origin.y + inputScrollView.frame.size.height
        guard heightConstraint.constant != height else { return }
        
        heightConstraint.constant = height
        updateWithAnimationIfNeed(animation: animation, isShowInputScrollView: true)
    }
    
    func hideInputScrollView(animation: Bool) {
        
        let height = viewTextField.frame.origin.y + viewTextField.frame.size.height
        guard heightConstraint.constant != height else { return }

        heightConstraint.constant = height
        updateWithAnimationIfNeed(animation: animation, isShowInputScrollView: false)
    }
    
    func updateWithAnimationIfNeed(animation: Bool, isShowInputScrollView: Bool) {
        if animation {
            UIView.animate(withDuration: Constants.animationFrameDuration) {
                self.firstAvailableViewController().view.layoutIfNeeded()
                self.inputScrollView.alpha = isShowInputScrollView ? 1 : 0
            }
        }
        else {
            inputScrollView.alpha = isShowInputScrollView ? 1 : 0
        }
    }
    
    var heightConstraint: NSLayoutConstraint {
        
        if let constraint = constraints.first(where: {$0.firstAttribute == .height}) {
            return constraint
        }
        return NSLayoutConstraint()
    }
}
