//
//  CameraAccess.swift
//  WavesWallet-iOS
//
//  Created by Mac on 25/11/2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import UIKit
import AVFoundation

enum CameraAccess {
    
    static var alertController: UIAlertController = {
        let alert = UIAlertController(
            title: Localizable.Waves.Cameraaccess.Alert.title,
            message: Localizable.Waves.Cameraaccess.Alert.message,
            preferredStyle: UIAlertController.Style.alert
        )
        
        alert.addAction(UIAlertAction(title: Localizable.Waves.Cameraaccess.Alert.cancel, style: .cancel, handler: nil))
        
        alert.addAction(UIAlertAction(title: Localizable.Waves.Cameraaccess.Alert.allow, style: .default, handler: { (alert) -> Void in
            
            if #available(iOS 10.0, *) {
                
                if let url = URL(string:UIApplication.openSettingsURLString) {
                    DispatchQueue.main.async {
                        if UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
                        }
                    }
                }
                
            }
        }))
        
        return alert
    }()
    
    static func requestAccess(success: (() -> Void)?, failure: (() -> Void)?) {
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch cameraAuthorizationStatus {
        case .notDetermined: CameraAccess.requestCameraPermission { (isSuccess) in
                if isSuccess {
                    success?()
                } else {
                    failure?()
                }
            }
            case .authorized: success?()
            case .restricted, .denied: failure?()
        }
    }
    
    static func requestCameraPermission(completion: @escaping ((Bool) -> Void)) {
        
        AVCaptureDevice.requestAccess(for: .video, completionHandler: { accessGranted in
            DispatchQueue.main.async {
                completion(accessGranted)
            }
        })
        
    }
    
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
