//
//  InfoPageConfirmView.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 3/6/19.
//  Copyright © 2019 Waves Exchange. All rights reserved.
//

import UIKit
import Extensions

protocol InfoPageConfirmViewDelegate: AnyObject {
    func infoPageConfirmView(isActive: Bool)
    func infoPageContirmViewDidTapURL(_ url: URL)
}

private enum Constants {
    static let buttonDeltaWidth: CGFloat = 24
    static let topTitlePadding: CGFloat = 44
}


final class InfoPageConfirmView: UIView {

    @IBOutlet private weak var labelTitle: UILabel!
    @IBOutlet private weak var labelSubtitle: UILabel!
    @IBOutlet private weak var checkBox2: UIImageView!
    @IBOutlet private weak var checkBox3: UIImageView!
    @IBOutlet private weak var label2: UILabel!
    @IBOutlet private weak var label3: UILabel!
    @IBOutlet private weak var buttonTermsUse: HighlightedButton!
    @IBOutlet private weak var buttonTermsConditions: HighlightedButton!
    @IBOutlet private weak var termsOfUseWidth: NSLayoutConstraint!
    @IBOutlet private weak var termsConditionsWidth: NSLayoutConstraint!
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var buttonsScrollView: UIScrollView!
    
    @IBOutlet private weak var titlePositionTop: NSLayoutConstraint!
    
    @IBOutlet private var rightGradientView: GradientView!
    @IBOutlet private var leftGradientView: GradientView!
    
    weak var delegate: InfoPageConfirmViewDelegate?
            
    private var isCheck2 = false
    private var isCheck3 = false
   
    override func awakeFromNib() {
        super.awakeFromNib()
        setupLocalization()
        setupCheckBoxes()
        buttonsScrollView.delegate = self

        rightGradientView.startColor = UIColor.basic50.withAlphaComponent(0.0)
        rightGradientView.endColor = UIColor.basic50
        rightGradientView.direction = .custom(GradientView.Settings.init(startPoint: CGPoint(x: 0.0, y: 0),
                                                                         endPoint: CGPoint(x: 1, y: 0),
                                                                         locations: [0.0, 1]))
        leftGradientView.startColor = UIColor.basic50
        leftGradientView.endColor = UIColor.basic50.withAlphaComponent(0.0)
        leftGradientView.direction = .custom(GradientView.Settings.init(startPoint: CGPoint(x: 0.0, y: 0),
                                                                        endPoint: CGPoint(x: 1, y: 0),
                                                                        locations: [0, 1.0]))
        
        
        if Platform.isIphone5 {
            titlePositionTop.constant = Constants.topTitlePadding            
        }
    }
        
    @IBAction private func check2Tapped(_ sender: Any) {
        isCheck2 = !isCheck2
        setupCheckBoxes()
        delegate?.infoPageConfirmView(isActive: isActive)
    }
    
    @IBAction private func check3Tapped(_ sender: Any) {
        isCheck3 = !isCheck3
        setupCheckBoxes()
        delegate?.infoPageConfirmView(isActive: isActive)
    }
    
    @IBAction private func termsOfUseTapped(_ sender: Any) {
        delegate?.infoPageContirmViewDidTapURL(URL(string: UIGlobalConstants.URL.termsOfUse)!)
    }
    
    @IBAction private func termsOfConditionsTapped(_ sender: Any) {
        delegate?.infoPageContirmViewDidTapURL(URL(string: UIGlobalConstants.URL.termsOfConditions)!)
    }
    
    private var isActive: Bool {
        return isCheck2 && isCheck3
    }
    
    func setupContentInset(_ inset: UIEdgeInsets) {
        scrollView.contentInset = inset
    }
}

extension InfoPageConfirmView: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.x > 0 {
            leftGradientView.isHidden = false
        } else {
            leftGradientView.isHidden = true
        }
    }
}

private extension InfoPageConfirmView {
    
    var on: UIImage {
        return Images.checkboxOn.image
    }
    
    var off: UIImage {
        return Images.checkboxOff.image
    }
    
    func setupCheckBoxes() {
        checkBox2.image = isCheck2 ? on : off
        checkBox3.image = isCheck3 ? on : off
    }
    
    func setupLocalization() {
        labelTitle.text = Localizable.Waves.Hello.Page.Confirm.title
                        
        labelSubtitle.text = Localizable.Waves.Hello.Page.Confirm.subtitle
        
        label2.text = Localizable.Waves.Hello.Page.Confirm.description2
        label3.text = Localizable.Waves.Hello.Page.Confirm.description3
        
        let privacyPolicyText = Localizable.Waves.Hello.Page.Confirm.Button.privacyPolicy
        let termsOfConditions = Localizable.Waves.Hello.Page.Confirm.Button.termsAndConditions
        
        buttonTermsUse.setTitle(privacyPolicyText, for: .normal)
        buttonTermsConditions.setTitle(termsOfConditions, for: .normal)
        
        guard let font = buttonTermsUse.titleLabel?.font else { return }
        termsOfUseWidth.constant = privacyPolicyText.maxWidth(font: font) + Constants.buttonDeltaWidth
        termsConditionsWidth.constant = termsOfConditions.maxWidth(font: font) + Constants.buttonDeltaWidth
    }
    
}
