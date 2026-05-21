//
//  SocketModel.swift
//  Heapchat_swift-sdk
//
//  Created by Aman Kumar on 03/04/25.
//

import Foundation
import SocketIO

struct JoinRoomModel: Codable {
    let conversationId: String
}

struct NewMessageModel: Codable {
    let messageId: String
    let conversationId: String
    let content: String
    let isFromCustomer: Bool
}

struct ReadStatusModel: Codable {
    let conversationId: String
    let messageIds: [String]
}

struct TypingMessageModel: Codable {
    let messageId: String
    let conversationId: String
    let typedMessage: String
}

struct PaginateMessagesModel: Codable {
    let conversationId: String
    let page: Int
    let limit: Int
}

struct PaginateMetadataModel: Codable {
    let pageSize: Int
    let totalPages: Int
}

struct AgentActivityModel: Codable {
    let available: Bool
}

struct JoinAgentActivityModel: Codable {
    let projectId: String
}
