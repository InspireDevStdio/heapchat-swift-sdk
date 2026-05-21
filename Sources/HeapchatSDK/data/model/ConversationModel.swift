//
//  ConversationModel.swift
//  Heapchat_swift-sdk
//
//  Created by Aman Kumar on 03/04/25.
//

import Foundation

struct ConversationPayloadModel: Codable {
    let customerId: String
}

struct ConversationResponseModel: Codable {
    let id: String
    let customerId: String
}
