//
//  Constants.swift
//  Heapchat_swift-sdk
//
//  Created by Aman Kumar on 03/04/25.
//

import Foundation
import ExyteMediaPicker
import ExyteChat

struct Constants {
    static let defaultBackendURL = "https://api.heap.chat"

    static var backendURL: String {
        UserDefaults.standard.string(forKey: UserDefaultsKey.backendURL) ?? defaultBackendURL
    }
}

typealias ExyteUser = ExyteChat.User
typealias ExyteMessage = ExyteChat.Message
typealias ExyteRecording = ExyteChat.Recording
typealias ExyteMedia = ExyteMediaPicker.Media
typealias ExyteAttachment = ExyteChat.Attachment
typealias ExyteAttachmentType = ExyteChat.AttachmentType
