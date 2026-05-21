//
//  SocketEvent.swift
//  Heapchat_swift-sdk
//
//  Created by Aman Kumar on 03/04/25.
//

import Foundation

enum SocketEvent: String {
    case joinRoom = "join_room"
    case leaveRoom = "leave_room"
    case newMessage = "new_message"
    case chatMessage = "chat_message"
    case readStatus = "read_status"
    case typingMessage = "typing_message"
    case previousMessages = "previous_messages"
    case paginateMessages = "paginate_messages"
    case paginateMessagesMetadata = "paginate_messages_metadata"
    case joinAgentActivity = "join_agent_activity"
    case leaveAgentActivity = "leave_agent_activity"
    case agentActivity = "agent_activity"
}
