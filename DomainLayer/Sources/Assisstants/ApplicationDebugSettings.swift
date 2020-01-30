//
//  ApplicationDebugSettings.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 3/28/19.
//  Copyright © 2019 Waves Exchange. All rights reserved.
//

import Foundation
import Extensions
import WavesSDKExtensions


public struct ApplicationDebugSettings: TSUD, Codable, Mutating {
    
    private static let key: String = "com.waves.debug.settings"

    private var isEnableStage: Bool = false
    private var isEnableNotificationsSettingTest: Bool = false
    private var isEnableEnviromentTest: Bool = false
    private var isEnableVersionUpdateTest: Bool = false
    private var isEnableDebugSettingsTest: Bool = false
    private var isEnableTradeCategoriesConfigTest: Bool = false

    private var debugButtonPosition: CGPoint? = nil
    
    public static var defaultValue: ApplicationDebugSettings {
        return ApplicationDebugSettings(isEnableStage: false,
                                        isEnableNotificationsSettingTest: false,
                                        debugButtonPosition: nil,
                                        isEnableEnviromentTest: false,
                                        isEnableVersionUpdateTest: false,
                                        isEnableDebugSettingsTest: false,
                                        isEnableTradeCategoriesConfigTest: false)
    }
    
    public static var stringKey: String {
        return key
    }
    
    public static var isEnableStage: Bool {
        return ApplicationDebugSettings.get().isEnableStage
    }
    
    public static var debugButtonPosition: CGPoint? {
        
        get {
            return ApplicationDebugSettings.get().debugButtonPosition
        }
        
        set {
            var settings = ApplicationDebugSettings.get()
            settings.debugButtonPosition = newValue
            ApplicationDebugSettings.set(settings)
        }
    }
    
    public init() {}
        
    public init(isEnableStage: Bool,
                isEnableNotificationsSettingTest: Bool,
                debugButtonPosition: CGPoint?,
                isEnableEnviromentTest: Bool,
                isEnableVersionUpdateTest: Bool,
                isEnableDebugSettingsTest: Bool,
                isEnableTradeCategoriesConfigTest: Bool) {
        self.isEnableStage = isEnableStage
        self.isEnableEnviromentTest = isEnableEnviromentTest
        self.isEnableVersionUpdateTest = isEnableVersionUpdateTest
        self.isEnableNotificationsSettingTest = isEnableNotificationsSettingTest
        self.debugButtonPosition = debugButtonPosition
        self.isEnableDebugSettingsTest = isEnableDebugSettingsTest
        self.isEnableTradeCategoriesConfigTest = isEnableTradeCategoriesConfigTest
    }
    
    
    public static func setupIsEnableStage(isEnable: Bool) {
        var settings = ApplicationDebugSettings.get()
        settings.isEnableStage = isEnable
        ApplicationDebugSettings.set(settings)
    }
    
    public static var isEnableNotificationsSettingTest: Bool {
        return ApplicationDebugSettings.get().isEnableNotificationsSettingTest
    }
    
    public static func setEnableNotificationsSettingTest(isEnable: Bool) {
        var settings = ApplicationDebugSettings.get()
        settings.isEnableNotificationsSettingTest = isEnable
        ApplicationDebugSettings.set(settings)
    }
    
    public static var isEnableEnviromentTest: Bool {
        return ApplicationDebugSettings.get().isEnableEnviromentTest
    }
    
    public static func setEnableEnviromentTest(isEnable: Bool) {
        var settings = ApplicationDebugSettings.get()
        settings.isEnableEnviromentTest = isEnable
        ApplicationDebugSettings.set(settings)
    }
    
    public static var isEnableVersionUpdateTest: Bool {
        return ApplicationDebugSettings.get().isEnableVersionUpdateTest
    }
    
    public static func setEnableVersionUpdateTest(isEnable: Bool) {
        var settings = ApplicationDebugSettings.get()
        settings.isEnableVersionUpdateTest = isEnable
        ApplicationDebugSettings.set(settings)
    }
    
    public static var isEnableDebugSettingsTest: Bool {
        return ApplicationDebugSettings.get().isEnableDebugSettingsTest
    }
    
    public static func setEnableDebugSettingsTest(isEnable: Bool) {
        var settings = ApplicationDebugSettings.get()
        settings.isEnableDebugSettingsTest = isEnable
        ApplicationDebugSettings.set(settings)
    }
    
    public static var isEnableTradeCategoriesConfigTest: Bool {
        return ApplicationDebugSettings.get().isEnableTradeCategoriesConfigTest
    }
    
    public static func setEnableTradeCategoriesConfigTest(isEnable: Bool) {
        var settings = ApplicationDebugSettings.get()
        settings.isEnableTradeCategoriesConfigTest = isEnable
        ApplicationDebugSettings.set(settings)
    }
}
