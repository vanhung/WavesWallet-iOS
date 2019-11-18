//
//  DexListInteractorProtocol.swift
//  WavesWallet-iOS
//
//  Created by Pavel Gubin on 8/7/18.
//  Copyright © 2018 Waves Exchange. All rights reserved.
//

import Foundation
import RxSwift
import DomainLayer

protocol DexListInteractorProtocol {
    func pairs() -> Observable<ResponseType<DexList.DTO.DisplayInfo>>
    func localPairs() -> Observable<DexList.DTO.LocalDisplayInfo>
}
