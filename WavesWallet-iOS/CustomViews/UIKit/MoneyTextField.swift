//
//  DexInputTextField.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 9/12/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import UIKit
import AudioToolbox
import Extensions

private enum Constants {
    static let locale = Locale(identifier: "en_US")
    static let maximumInputDigits = 10
}

protocol MoneyTextFieldDelegate: AnyObject {
    func moneyTextField(_ textField: MoneyTextField, didChangeValue value: Money)
}

final class MoneyTextField: UITextField {

    private var externalDelegate: UITextFieldDelegate?
    
    //TODO: textString, text, textNSString WTF?
    private var textString: String {
        return text ?? ""
    }
    private var textNSString: NSString {
        return textString as NSString
    }

    override var delegate: UITextFieldDelegate? {
        didSet {
            externalDelegate = delegate
            super.delegate = self
        }
    }

    weak var moneyDelegate: MoneyTextFieldDelegate?
    
    private var isShakeView: Bool = true
        
    private var hasSetDecimals = false
   
    private(set) var decimals: Int = 0
    
    var value: Money {
        
        set {
            setDecimals(newValue.decimals, forceUpdateMoney: false)
            setValue(value: newValue)
        }
        
        get {
            if let decimal = Decimal(string: textString,
                                     locale: Constants.locale) {
                return Money(value: decimal, decimals)
            } else {
                return Money(0, decimals)
            }
        }
    }
    
    override var text: String? {
        didSet {
            setNeedUpdateTextField(isNeedNotify: false)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    private func initialize() {
        super.delegate = self
        placeholder = "0"
        addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        keyboardType = .decimalPad
    }
}

// MARK: - Methods
extension MoneyTextField {
        
    // forceUpdateMoney need if we want call -> MoneyTextFieldDelegate: moneyTextField(_ textField: MoneyTextField, didChangeValue value: Money)
    //TODO: Need remove forceUpdateMoney then it stupid logic    
    func setDecimals(_ decimals: Int,
                     forceUpdateMoney: Bool) {
        self.decimals = decimals
        hasSetDecimals = true
        
        setNeedUpdateTextField(isNeedNotify: forceUpdateMoney)
        setupAttributedText(text: formattedStringFrom(value))
    }
    
    //TODO: Need remove forceUpdateMoney then it stupid logic
    func setDecimals(_ decimals: Int) {
        setDecimals(decimals,
                    forceUpdateMoney: false)
    }

    //TODO: Need remove forceUpdateMoney then it stupid logic
    func setValue(value: Money) {
        setupAttributedText(text: formattedStringFrom(value))
    }
    
    func addPlusValue() {
        setValue(value: value.add(deltaValue))
    }
    
    func addMinusValue() {
        setValue(value: value.minus(deltaValue))
    }
    
    func clearInput() {
        text = nil
        setNeedUpdateTextField(isNeedNotify: false)
    }
    
    func clear() {
        decimals = 0
        hasSetDecimals = false
    }
}


// MARK: - Override
extension MoneyTextField {
    
    override func target(forAction action: Selector, withSender sender: Any?) -> Any? {
        return nil
    }
}

// MARK: - UI
private extension MoneyTextField {
    
    func setupAttributedText(text: String) {
        let range = selectedTextRange
        attributedText = NSAttributedString.styleForBalance(text: text, font: font!)
        selectedTextRange = range
    }
    
    func shakeTextFieldIfNeed() {
        if isShakeView {
            superview?.shakeView()
        }
    }
    
    private func setNeedUpdateTextField(isNeedNotify: Bool = true) {
        if textString.count > 0 {
            setupAttributedText(text: textNSString.replacingOccurrences(of: ",", with: "."))
            checkCorrectInputAfterRemoveText()
        } else {
            attributedText = nil
        }
        
        if isNeedNotify {
            moneyDelegate?.moneyTextField(self, didChangeValue: value)
        }
    }
}

// MARK: - Check after input

private extension MoneyTextField {
    
    func checkCorrectInputAfterRemoveText() {
        
        if isExistDot {
            
            let isEmptyFieldBeforeDot = textNSString.substring(to: dotRange.location).count == 0
            
            if isEmptyFieldBeforeDot {
                var string = textString
                string.insert("0", at: String.Index(encodedOffset: 0))
                setupAttributedText(text: string)
                
                if textString == "0." {
                    if let range = selectedTextRange, let from = position(from: range.start, offset: 1) {
                        selectedTextRange = textRange(from: from, to: from)
                    }
                }
            }
        } else if isEmptyDotAfterZero() {
            var string = textString
            string.remove(at: String.Index(encodedOffset: 0))
            setupAttributedText(text: string)
        }
    }
    
    func isEmptyDotAfterZero() -> Bool {
        
        if textString.count > 1 {
            
            let firstCharacter = textNSString.substring(to: 1)
            let secondCharacter = (textNSString.substring(from: 1) as NSString).substring(to: 1)
            if firstCharacter == "0" && secondCharacter != "." {
                return true
            }
        }
        return false
    }
}

// MARK: - UITextFieldDelegate
extension MoneyTextField: UITextFieldDelegate {
    
    @objc func textDidChange() {
        setNeedUpdateTextField()
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        externalDelegate?.textFieldDidBeginEditing?(textField)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        externalDelegate?.textFieldDidEndEditing?(textField)
    }
        
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
     
        if string == "" {
            return true
        }
        
        if isValidInput(input: string, inputRange: range) {
            return true
        } else {
            //TODO: Remove shake :)
            //TODO: Send delegate incorrect input
            shakeTextFieldIfNeed()
            return false
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool  {
       
        if let externalDelegate = externalDelegate {
            if externalDelegate.responds(to: #selector(textFieldShouldReturn(_:))) {
                return externalDelegate.textFieldShouldReturn!(textField)
            }
        }
        return true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        
        if let externalDelegate = externalDelegate {
            if externalDelegate.responds(to: #selector(textFieldShouldBeginEditing(_:))) {
                return externalDelegate.textFieldShouldBeginEditing!(textField)
            }
        }
        
        return true
    }
    
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if let externalDelegate = externalDelegate {
            if externalDelegate.responds(to: #selector(textFieldShouldEndEditing(_:))) {
                return externalDelegate.textFieldShouldEndEditing!(textField)
            }
        }
        
        return true
    }
}

// MARK: - Calculation
private extension MoneyTextField {
    
    var dotRange: NSRange {
        return textNSString.range(of: ".")
    }
    
    var isExistDot: Bool {
        return dotRange.location != NSNotFound
    }
    
    var countInputDecimals: Int {
        
        var decimals = 0
        
        if isExistDot {
            let substring = textNSString.substring(from: dotRange.location + 1)
            decimals = substring.count > 0 ? substring.count : 1
        }
        
        return decimals
    }
    
    var deltaValue: Double {
                
        var deltaValue : Double = 1
        for _ in 0..<countInputDecimals {
            deltaValue *= 0.1
        }
        
        return deltaValue
    }
}

// MARK: - InputValidation
private extension MoneyTextField {
    
    func isValidInput(input: String, inputRange: NSRange) -> Bool {
        
        if dotRange.location == NSNotFound {
            if textString.last == "0" && input == "0" && textString.count == 1 {
                return false
            } else if textString.last == "0" && input != "." && input != "," && textString.count == 1 {
                
                if inputRange.location == 0 && (input as NSString).integerValue > 0 {
                    return true
                }
                return false
            }
        }

        if (input == "," || input == ".") && isExistDot {
            return false
        }
        
        if !isValidInputAfterDot(input: input, inputRange: inputRange) {
            return false
        }
        
        if !isValidInputBeforeDot(input: input, inputRange: inputRange) {
            return false
        }
        
        if !isValidBigNumber(input: input, inputRange: inputRange) {
            return false
        }
        
        return true
    }
    
    func isValidInputAfterDot(input: String, inputRange: NSRange) -> Bool {

        var isMaximumInputDecimals = false
        if hasSetDecimals {
            isMaximumInputDecimals = countInputDecimals >= decimals && input.count > 0

        } else {
            isMaximumInputDecimals = countInputDecimals >= decimals && decimals > 0 && input.count > 0
        }

        if isMaximumInputDecimals {
            if inputRange.location > dotRange.location {
                return false
            }
        }
        
        return true
    }
    
    func isValidBigNumber(input: String, inputRange: NSRange) -> Bool {
        
        if input == "." || input == "," {
            return true
        }
        
        if isExistDot {
            if inputRange.location < dotRange.location {
                let s = textNSString.substring(to: dotRange.location)
                return s.count + input.count <= Constants.maximumInputDigits
            }
        } else {
            return textString.count + input.count <= Constants.maximumInputDigits
        }
        return true
    }
        
    //TODO: If we paste string with two and more zero (for example "000"), then code is dont work :)
    func isValidInputBeforeDot(input: String, inputRange: NSRange) -> Bool {
                
        if isExistDot && textString.count > 1 {
            
            let isZeroBeforeFirstNumber = input == "0" && inputRange.location == 0 && inputRange.length == 0

            let substring = textNSString.substring(to: dotRange.location + dotRange.length)
            
            let isSymbolAfterZero: Bool = substring == "0." && inputRange.location == 1
            let isZeroBeforeZero: Bool = substring == "0." && input == "0" && inputRange.location == 0
            
            if isSymbolAfterZero || isZeroBeforeZero || isZeroBeforeFirstNumber {
                return false
            }
        }
        return true
    }
}

// MARK: - NumberFormatter

private extension MoneyTextField {
    
    static func numberFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.decimalSeparator = "."
        return formatter
    }
    
    func formattedStringFrom(_ value: Money) -> String {
        let formatter = MoneyTextField.numberFormatter()
        formatter.maximumFractionDigits = decimals
        formatter.minimumFractionDigits = min(countInputDecimals, decimals)
        return formatter.string(from: value.decimalValue as NSNumber) ?? ""
    }
}
