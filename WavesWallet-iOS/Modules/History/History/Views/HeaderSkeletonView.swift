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
import UITools

final class HeaderSkeletonView: UITableViewHeaderFooterView, SkeletonAnimatable, NibReusable {
    
    @IBOutlet private var views: [GradientContainerView]!
    
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
        views.map { $0.gradientLayer }
    }
    
    class func cellHeight() -> CGFloat { 36 }
}
