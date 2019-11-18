//
//  QRCodeReaderCoordinator.swift
//  WavesWallet-iOS
//
//  Created by Mac on 08/11/2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import UIKit
import QRCodeReader

final class QRCodeReaderControllerCoordinator: Coordinator {

    var childCoordinators: [Coordinator] = []
    weak var parent: Coordinator?

    private let navigationRouter: NavigationRouter

    private let completionBlock: ((String) -> Void)

    private let readerVC: QRCodeReaderViewController = QRCodeReaderFactory.deffaultCodeReader

    init(navigationRouter: NavigationRouter, completionBlock: @escaping ((String) -> Void)) {
        self.navigationRouter = navigationRouter
        self.completionBlock = completionBlock
        self.readerVC.delegate = self
        self.readerVC.completionBlock = { [weak self] (result) -> Void in

            guard let self = self else { return }
            if let seed = result?.value {
                self.completionBlock(seed)
            }
            self.navigationRouter.dismiss()
            self.removeFromParentCoordinator()
        }
    }
    
    func start() {
        guard QRCodeReader.isAvailable() else { return }

        CameraAccess.requestAccess(success: { [weak self] in
            guard let self = self else { return }
            self.navigationRouter.present(self.readerVC)
        }, failure: { [weak self] in
            guard let self = self else { return }
            let alert = CameraAccess.alertController
            self.navigationRouter.present(alert)
        })
    }

}

extension QRCodeReaderControllerCoordinator: QRCodeReaderViewControllerDelegate {
    func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {

    }

    func readerDidCancel(_ reader: QRCodeReaderViewController) {

    }
}
