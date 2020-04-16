//
//  String+Size.swift
//  WavesWallet-iOS
//
//  Created by rprokofev on 24/05/2019.
//  Copyright © 2019 Waves Exchange. All rights reserved.
//

import Foundation
import UIKit

public extension String {

    func maxHeight(font: UIFont, forWidth: CGFloat) -> CGFloat {
        let text = self as NSString
        return ceil(text.boundingRect(with: CGSize(width: forWidth, height: CGFloat.greatestFiniteMagnitude),
                                      options: .usesLineFragmentOrigin,
                                      attributes: [.font: font],
                                      context: nil).size.height)
    }
    
    func maxHeightMultiline(font: UIFont, forWidth: CGFloat) -> CGFloat {
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byWordWrapping
        
        let rect = NSAttributedString(string: self, attributes: [.font: font,
                                                                 .paragraphStyle: style])
            .boundingRect(with: CGSize(width: forWidth, height: CGFloat.greatestFiniteMagnitude),
                          options: [.usesLineFragmentOrigin, .usesFontLeading],
                          context: nil)
        
        return ceil(rect.height)
    }
    
    func maxWidth(font: UIFont) -> CGFloat {
        let text = self as NSString
        let size = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        
        return ceil(text.boundingRect(with: size,
                                      options: .usesLineFragmentOrigin,
                                      attributes: [.font: font],
                                      context: nil).size.width)
    }        
}

public extension NSAttributedString {
    
    func boundingRect(with size: CGSize) -> CGRect {
        boundingRect(with: size, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
    }
}
