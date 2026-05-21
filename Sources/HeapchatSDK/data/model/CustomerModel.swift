//
//  CustomerModel.swift
//  Heapchat_swift-sdk
//
//  Created by Aman Kumar on 03/04/25.
//

import Foundation

struct CustomerPayloadModel: Codable {
    let id: String
    var name: String? = nil
    var email: String? = nil
    var phone: String? = nil
}

// MARK: - SDK front only
public struct UserDataModel {
    public init(
        name: String? = nil,
        email: String? = nil,
        phone: String? = nil
    ) {
        self.name = name
        self.email = email
        self.phone = phone
    }
    var name: String? = nil
    var email: String? = nil
    var phone: String? = nil
}

struct CustomerResponseModel: Codable {
    let id: String
    let name: String?
    let email: String?
    let phone: String?
    let customId: String?
    let conversation: ConversationResponseModel?
}

enum PlatformType: String, Codable {
    case IOS
    case ANDROID
    case WEB
}

struct DeviceTokenPayloadModel: Codable {
    let token: String
    var platform: PlatformType = .IOS
    let customerId: String
}

struct DeviceLanguagePayloadModel: Codable {
    let customerId: String
    let languageCode: String
}

struct CustomerCustomDataPayloadModel: Codable {
    let customerId: String
    let customData: [String: String]
}
