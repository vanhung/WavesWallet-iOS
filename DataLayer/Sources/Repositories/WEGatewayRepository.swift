//
//  WEGatewayRepositoryProtocol.swift
//  DataLayer
//
//  Created by rprokofev on 12.03.2020.
//  Copyright © 2020 Waves Platform. All rights reserved.
//

import DomainLayer
import Foundation
import Moya
import RxSwift
import WavesSDK
import WavesSDKCrypto

private enum Constants {
    static let sessionLifeTime: Int64 = 1_200_000
    static let grantType: String = "password"
    static let scope: String = "client"

    static let currencyForLink: String = "USD"
    static let currencyForAd: String = "AC_USD"
}

private struct TransferBindingResponse: Codable {
    let addresses: [String]
    let amount_min: String
    let amount_max: String
    let tax_rate: Double
    let tax_flat: String
}

private struct RegisterOrderResponse: Codable {
    struct AuthenticationData: Codable {
        let sciName: String
        let accountEmail: String
        var signature: String

        enum CodingKeys: String, CodingKey {
            case sciName = "sci_name"
            case accountEmail = "account_email"
            case signature
        }
    }

    let orderId: String
    let authenticationData: AuthenticationData

    enum CodingKeys: String, CodingKey {
        case orderId = "order_id"
        case authenticationData = "authentication_data"
    }
}

// TODO: Split Usecase and services
final class WEGatewayRepository: WEGatewayRepositoryProtocol {
    private let developmentConfigsRepository: DevelopmentConfigsRepositoryProtocol
    private let weGateway: MoyaProvider<WEGateway.Service> = .anyMoyaProvider()

    init(developmentConfigsRepository: DevelopmentConfigsRepositoryProtocol) {
        self.developmentConfigsRepository = developmentConfigsRepository
    }

    func transferBinding(
        serverEnvironment: ServerEnvironment,
        request: DomainLayer.Query.WEGateway.TransferBinding) -> Observable<DomainLayer.DTO.WEGateway.TransferBinding> {
        return developmentConfigsRepository
            .developmentConfigs()
            .flatMap { [weak self] developmentConfigs -> Observable<DomainLayer.DTO.WEGateway.TransferBinding> in
                guard let self = self else { return Observable.empty() }

                let url = serverEnvironment.servers.gateways.v2
                let exchangeClientSecret = developmentConfigs.exchangeClientSecret

                let transferBinding: WEGateway.Query.TransferBinding = .init(token: exchangeClientSecret,
                                                                             senderAsset: request.senderAsset,
                                                                             recipientAsset: request.recipientAsset,
                                                                             recipientAddress: request.recipientAddress)

                return self
                    .weGateway
                    .rx
                    .request(.transferBinding(baseURL: url,
                                              query: transferBinding),
                             callbackQueue: DispatchQueue.global(qos: .userInteractive))
                    .filterSuccessfulStatusAndRedirectCodes()
                    .map(TransferBindingResponse.self)
                    .map {
                        DomainLayer.DTO.WEGateway.TransferBinding(addresses: $0.addresses,
                                                                  amountMin: $0.amount_min.decodeInt64FromBase64(),
                                                                  amountMax: $0.amount_max.decodeInt64FromBase64(),
                                                                  taxRate: $0.tax_rate,
                                                                  taxFlat: $0.tax_flat.decodeInt64FromBase64())
                    }
                    .asObservable()
            }
    }

    func adCashDepositsRegisterOrder(serverEnvironment: ServerEnvironment,
                                     request: DomainLayer.Query.WEGateway.RegisterOrder)
        -> Observable<DomainLayer.DTO.WEGateway.Order> {
        let url = serverEnvironment.servers.gateways.v2

        let token = request.token.accessToken
        let currency = DomainLayerConstants.acUSDId
        let amount = request.amount
        let address = request.address

        let adCashDepositsRegisterOrder: WEGateway.Query.AdCashDepositsRegisterOrder = .init(currency: currency,
                                                                                             amount: "\(amount)",
                                                                                             address: address)
        return weGateway
            .rx
            .request(.adCashDepositsRegisterOrder(baseURL: url,
                                                  token: token,
                                                  query: adCashDepositsRegisterOrder),
                     callbackQueue: DispatchQueue.global(qos: .userInteractive))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(RegisterOrderResponse.self)
            .map { response -> DomainLayer.DTO.WEGateway.Order? in
                guard let url = response.createAdCashUrl(amount: amount, currency: Constants.currencyForLink) else {
                    return nil
                }

                return DomainLayer.DTO.WEGateway.Order(url: url)
            }
            .flatMap { order -> Single<DomainLayer.DTO.WEGateway.Order> in
                guard let order = order else { return Single.error(NetworkError.notFound) }
                return Single.just(order)
            }
            .asObservable()
    }
}

private extension RegisterOrderResponse {
    func createAdCashUrl(amount: Decimal, currency: String) -> URL? {
        let accountEmail = authenticationData.accountEmail
        let acSciName = authenticationData.sciName
        let acSign = authenticationData.signature
        let acAmount = String(format: "%.2f", amount.floatValue)
        let acOrderId = orderId
        let acCurrency = currency
        let acSuccessUrl = DomainLayerConstants.URL.fiatDepositSuccess
        let acFailUrl = DomainLayerConstants.URL.fiatDepositFail

        var params: [String: String] = .init()
        params["ac_account_email"] = accountEmail
        params["ac_sci_name"] = acSciName
        params["ac_sign"] = acSign
        params["ac_amount"] = acAmount
        params["ac_order_id"] = acOrderId
        params["ac_currency"] = acCurrency
        params["ac_success_url"] = acSuccessUrl
        params["ac_fail_url"] = acFailUrl

        var components = URLComponents(string: DomainLayerConstants.URL.advcash)
        components?.queryItems = params.map {
            URLQueryItem(name: $0, value: $1)
        }

        let url = components?.url

        return url
    }
}