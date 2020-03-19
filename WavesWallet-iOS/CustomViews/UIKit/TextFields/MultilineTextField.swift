//
//  MultilineTextField.swift
//  WavesWallet-iOS
//
//  Created by Mac on 16/11/2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import UIKit
import Extensions

protocol MultilineTextFieldDelegate: AnyObject {
    func multilineTextField(textField: MultilineTextField, errorTextForValue value: String) -> String?
    func multilineTextFieldDidChange(textField: MultilineTextField)
    func multilineTextFieldShouldReturn(textField: MultilineTextField)
}

final class MultilineTextField: UIView {
    
    struct Model {
        let title: String
        let placeholder: String?
    }
    
    // конфиогурацию вьюх лучше инкапсулировать (посомтреть в ImportAccountManuallyViewController)
    fileprivate(set) var textView = UITextView(frame: .zero)
    fileprivate let titleLabel = UILabel(frame: .zero)
    fileprivate let placeholderLabel = UILabel(frame: .zero)
    fileprivate let errorLabel = UILabel(frame: .zero)
    fileprivate let separator = UIView()

    var error: String? {
        didSet {
            checkValid()
        }
    }
    
    weak var delegate: MultilineTextFieldDelegate?
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    private func commonInit() {
        setupSeparator()
        setupTextView()
        setupTitleLabel()
        setupPlaceholderLabel()
        setupErrorLabel()
        
        checkTitle()
        checkPlaceholder()
        checkSeparator()
        checkValid()
    }
    
    // MARK: - Setups
    
    private func setupSeparator() {
        separator.backgroundColor = .accent100
        addSubview(separator)
    }
    
    private func setupTextView() {
        textView.delegate = self
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = Constants.containerInset
        textView.scrollsToTop = false
        textView.backgroundColor = .clear
        textView.font = Constants.font
        textView.textColor = .black
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        addSubview(textView)
    }
    
    private func setupTitleLabel() {
        titleLabel.text = ""
        titleLabel.font = Constants.titleFont
        titleLabel.textColor = .basic500
        addSubview(titleLabel)
    }
    
    private func setupPlaceholderLabel() {
        placeholderLabel.text = nil
        placeholderLabel.font = Constants.font
        placeholderLabel.numberOfLines = 0
        placeholderLabel.textColor = .basic500
        addSubview(placeholderLabel)
    }
    
    private func setupErrorLabel() {
        errorLabel.text = nil
        errorLabel.font = Constants.titleFont
        errorLabel.textColor = .error500
        errorLabel.textAlignment = .right
        addSubview(errorLabel)
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let titleHeight = titleLabel.text!.maxHeightMultiline(font: titleLabel.font, forWidth: bounds.width)
        titleLabel.frame = CGRect(x: 0, y: 0, width: bounds.width, height: titleHeight)
        errorLabel.frame = titleLabel.frame
        
        let textViewY = titleLabel.frame.maxY + Constants.titleToTextView
        textView.frame = CGRect(x: 0,
                                y: textViewY,
                                width: bounds.width,
                                height: bounds.height - textViewY - Constants.textViewToSeparator - Constants.separatorHeight)
        placeholderLabel.frame = textView.frame
        separator.frame = CGRect(x: 0,
                                 y: bounds.height - Constants.separatorHeight,
                                 width: bounds.width,
                                 height: Constants.separatorHeight)
        
        if bounds.height <= maximumHeight {
            textView.setContentOffset(.zero, animated: false)
        }
    }
    
    let minimumHeight: CGFloat = Constants.minimumHeight
    let maximumHeight: CGFloat = Constants.maximumHeight
    
    var height: CGFloat {
        let titleHeight = titleLabel.text!.maxHeightMultiline(font: titleLabel.font, forWidth: bounds.width)
        
        let insets = textView.textContainerInset
        
        let placeholderWidth = bounds.width - insets.left - insets.right
        let placeholderHeight = (placeholderLabel.text ?? "").maxHeightMultiline(font: placeholderLabel.font,
                                                                                 forWidth: placeholderWidth)
        let textViewHeight = textView.text.maxHeightMultiline(font: textView.font!,
                                                              forWidth: bounds.width - insets.left - insets.right)
        
        let height = titleHeight +
            Constants.titleToTextView +
            max(placeholderHeight, textViewHeight) +
            Constants.textViewToSeparator + Constants.separatorHeight
        return min(maximumHeight, max(minimumHeight, height))
    }
    
    // MARK: - Content
    
    private(set) var isValidValue: Bool = false
    
    var value: String { textView.text }
    
    var count: Int { value.count }
    
    func updateText(newText: String) {
        textView.text = newText
        
        checkValid()
        checkPlaceholder()
        checkSeparator()
        checkTitle()
        
        delegate?.multilineTextFieldDidChange(textField: self)
    }
 
    // MARK: - Checks
    
    fileprivate func checkPlaceholder() {
        placeholderLabel.isHidden = count > 0
    }
  
    fileprivate func checkSeparator() {
        separator.backgroundColor = textView.isFirstResponder ? .submit400 : .accent100
    }
    
    fileprivate func checkTitle() {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            self.titleLabel.alpha = self.count > 0 ? 1 : 0
        })
    }
    
    fileprivate func checkValid() {
        let text = textView.text
        
        var errorString: String? = ""
        var isValidValue: Bool = false
        
        if let text = text, text.isNotEmpty {
            errorString = delegate?.multilineTextField(textField: self, errorTextForValue: text)
            isValidValue = errorString == nil
        }

        if let error = self.error, error.isNotEmpty {
            errorString = error
            isValidValue = errorString == nil
        }
        
        errorLabel.text = errorString
        errorLabel.isHidden = isValidValue
        self.isValidValue = isValidValue
    }
    
    // MARK: - Helper
    
    @discardableResult override func becomeFirstResponder() -> Bool { textView.becomeFirstResponder() }
    
    @discardableResult override func resignFirstResponder() -> Bool { textView.resignFirstResponder() }
}

extension MultilineTextField: ViewConfiguration {
    func update(with model: MultilineTextField.Model) {
        titleLabel.text = model.title
        placeholderLabel.text = model.placeholder
    }
}

extension MultilineTextField: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        let newText = (textView.text! as NSString).replacingCharacters(in: range, with: text).trimmingLeadingWhitespace()
        
        if text == "\n" {
            checkValid()
            if isValidValue {
                delegate?.multilineTextFieldShouldReturn(textField: self)
            }
            return false
        }
       
        let newRange: NSRange
        if text.isNotEmpty {
            newRange = NSRange(location: textView.selectedRange.location + text.count, length: 0)
        } else {
            let location = textView.selectedRange.location - range.length
            newRange = NSRange(location: location > 0 ? location : 0, length: 0)
        }
        
        updateText(newText: newText)
        if textView.text.count > newRange.location {
            textView.selectedRange = newRange
        }
        return false
    }
 
    func textViewDidBeginEditing(_ textView: UITextView) {
        checkPlaceholder()
        checkSeparator()
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        checkPlaceholder()
        checkSeparator()
    }
}

private enum Constants {
    static let minimumHeight: CGFloat = 65
    static let maximumHeight: CGFloat = 155
    static let titleFont = UIFont.systemFont(ofSize: 13)
    static let separatorHeight: CGFloat = 0.5
    static let titleToTextView: CGFloat = 14
    static let textViewToSeparator: CGFloat = 14
    static let font = UIFont.systemFont(ofSize: 17)
    static let containerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
}
