//
//  Asset.swift
//  WavesWallet-iOS
//
//  Created by mefilt on 09.07.2018.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import RealmSwift

final class AssetRealm: Object {
    @objc dynamic var id: String = ""
    @objc dynamic var wavesId: String?
    @objc dynamic var gatewayId: String?
    @objc dynamic var name: String = ""
    @objc dynamic var precision: Int = 0
    @objc dynamic var descriptionAsset: String = ""
    @objc dynamic var height: Int64 = 0
    @objc dynamic var timestamp: Date = Date()
    @objc dynamic var sender: String = ""
    @objc dynamic var quantity: Int64 = 0
    @objc dynamic var ticker: String?
    @objc dynamic var modified: Date = Date()
    @objc dynamic var isReusable: Bool = false
    @objc dynamic var isSpam: Bool = false
    @objc dynamic var isFiat: Bool = false
    @objc dynamic var isGeneral: Bool = false
    @objc dynamic var isMyWavesToken: Bool = false
    @objc dynamic var isWavesToken: Bool = false    
    @objc dynamic var isGateway: Bool = false
    @objc dynamic var isWaves: Bool = false
    @objc dynamic var addressRegEx: String = ""
    @objc dynamic var iconLogoUrl: String?
    @objc dynamic var hasScript: Bool = false
    @objc dynamic var minSponsoredFee: Int64 = 0
    @objc dynamic var gatewayType: String?
    @objc dynamic var isStablecoin: Bool = false
    @objc dynamic var isQualified: Bool = false
    @objc dynamic var isExistInExternalSource: Bool = false    
    
    override class func primaryKey() -> String? {
        return "id"
    }    
}
