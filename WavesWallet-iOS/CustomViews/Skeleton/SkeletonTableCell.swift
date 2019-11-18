//
//  SkeletonCell.swift
//  WavesWallet-iOS
//
//  Created by mefilt on 17.07.2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import UIKit
import Skeleton

class SkeletonTableCell: UITableViewCell, SkeletonAnimatable {

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
}

extension UITableView {

    func startSkeletonCells() {
        self.visibleCells
            .map { $0 as? SkeletonTableCell }
            .compactMap { $0 }
            .forEach { $0.startAnimation() }
    }

    func stopSkeletonCells() {
        self.visibleCells
            .map { $0 as? SkeletonTableCell }
            .compactMap { $0 }
            .forEach { $0.stopAnimation() }
    }
}
