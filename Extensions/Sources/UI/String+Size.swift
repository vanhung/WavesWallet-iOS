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

    public func maxHeight(font: UIFont, forWidth: CGFloat) -> CGFloat {
        let text = self as NSString
        return ceil(text.boundingRect(with: CGSize(width: forWidth, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil).size.height)
    }
    
    public func maxHeightMultiline(font: UIFont, forWidth: CGFloat) -> CGFloat {
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byWordWrapping
        
        let rect = NSAttributedString(string: self, attributes: [.font: font,
                                                                 .paragraphStyle: style])
            .boundingRect(with: CGSize(width: forWidth,
                                       height: CGFloat.greatestFiniteMagnitude),
                          options: [.usesLineFragmentOrigin, .usesFontLeading],
                          context: nil)
        
        return ceil(rect.height)
    }
    
    public func maxWidth(font: UIFont) -> CGFloat {
        let text = self as NSString
        return ceil(text.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil).size.width)
    }        
}

public extension NSAttributedString {
    
    func boundingRect(with size: CGSize) -> CGRect {
        return boundingRect(with: size, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
    }
}
