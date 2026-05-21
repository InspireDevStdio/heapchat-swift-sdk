//
//  ExyteMessage.swift
//  Heapchat_swift-sdk
//
//  Created by Aman Kumar on 03/04/25.
//

import Foundation

extension MessageModel {
    func toExyteMessage() -> ExyteMessage {
        let messageModel = self
        let customerId = UserDefaults.standard.string(forKey: UserDefaultsKey.customerId) ?? ""
        let customerName = UserDefaults.standard.string(forKey: UserDefaultsKey.customerName) ?? "Customer \(customerId.prefix(6))"
        let projectIcon: String = (Heapchat.shared.projectData?.icon.isEmpty == false)
            ? Heapchat.shared.projectData?.icon ?? "https://www.heap.chat/favicon.ico"
            : "https://www.heap.chat/favicon.ico"

        let allUsers = [
            ExyteUser(
                id: "123",
                name: "Support Agent",
                avatarURL: projectIcon.toURL(),
                avatarCacheKey: projectIcon.toURL()?.cacheKey,
                isCurrentUser: false
            ),
            ExyteUser(
                id: customerId,
                name: customerName,
                avatarURL: nil,
                isCurrentUser: true
            )
        ]

        let convertedAttachments = messageModel.attachments?.toExyteAttachments() ?? []

        return ExyteMessage(
            id: messageModel.id,
            user: messageModel.isFromCustomer ? allUsers[1] : allUsers[0],
            status: messageModel.readAt != nil ? .read : .sent,
            createdAt: messageModel.createdAt,
            text: messageModel.isFromCustomer ? messageModel.content : messageModel.translatedContent ?? messageModel.content,
            attachments: convertedAttachments
        )
    }
}

extension [AttachmentModel] {
    func toExyteAttachments() -> [ExyteAttachment]? {
        let attachments = self
        return attachments.compactMap { attachmentModel in
            guard
                let fullURL = attachmentModel.url.toURL(),
                let type = attachmentModel.type.toExyteAttachment()
            else { return nil }

            let thumbURL = attachmentModel.thumbnailUrl?.toURL() ?? fullURL
            return ExyteAttachment(
                id: UUID().uuidString,
                thumbnail: thumbURL,
                full: fullURL,
                type: type,
                thumbnailCacheKey: thumbURL.cacheKey,
                fullCacheKey: fullURL.cacheKey,
            )
        }
    }
}

extension AttachmentType {
    func toExyteAttachment() -> ExyteAttachmentType? {
        switch self {
        case .IMAGE:
            return .image
        case .VIDEO:
            return .video
        default:
            return nil
        }
    }
}
