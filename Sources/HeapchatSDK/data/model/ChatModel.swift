//
//  ChatModel.swift
//  Heapchat_swift-sdk
//
//  Created by Aman Kumar on 03/04/25.
//

import Foundation

struct MessageModel: Codable {
    let id: String
    let conversationId: String
    let content: String
    let translatedContent: String?
    let isFromCustomer: Bool
    let attachments: [AttachmentModel]?
    let readAt: Date?
    let createdAt: Date
    let updatedAt: Date
}

struct AttachmentModel: Codable {
    let id: String
    let messageId: String
    let type: AttachmentType
    let url: String
    let thumbnailUrl: String?
    let filename: String
    let mimeType: String
    let size: Int
    let duration: Int?
    let width: Int?
    let height: Int?
    let createdAt: Date
    let updatedAt: Date
}

enum AttachmentType: String, Codable {
  case IMAGE
  case VIDEO
  case AUDIO
}

