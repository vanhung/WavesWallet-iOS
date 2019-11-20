//
//  HistoryHeaderSkeletonCell.swift
//  WavesWallet-iOS
//
//  Created by Mac on 17/08/2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import UIKit
import Skeleton
import Extensions

final class HeaderSkeletonView: UITableViewHeaderFooterView, SkeletonAnimatable, NibReusable {
    
    @IBOutlet var views: [GradientContainerView]!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let baseColor = UIColor.basic100
        let nextColor = UIColor.basic50
        gradientLayers.forEach { gradientLayer in
            
            gradientLayer.colors = [baseColor.cgColor,
                                    nextColor.cgColor,
                                    baseColor.cgColor]
        }
    }
    
    var gradientLayers: [CAGradientLayer] {
        return views.map { $0.gradientLayer }
    }
    
    class func cellHeight() -> CGFloat {
        return 36
    }
}
