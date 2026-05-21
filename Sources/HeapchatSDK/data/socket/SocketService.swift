//
//  SocketService.swift
//  Heapchat_swift-sdk
//
//  Created by Aman Kumar on 03/04/25.
//

import Foundation
import SocketIO
import ExyteChat

@MainActor
final class SocketService: ObservableObject {
    private var manager: SocketManager?
    private var socket: SocketIOClient?

    @Published private(set) var sortedMessages: [ExyteMessage] = []
    @Published private var messages: [String:ExyteMessage] = [:]
    @Published private var currentPage: Int = 1
    @Published private var totalPages: Int = 1
    @Published private var messageId = UUID().uuidString
    @Published var showActivityIndicator = false
    @Published private(set) var isActive = true

    @Published var hasNewMessages: Bool = false

    private var conversationId: String?
    private var apiKey: String?
    private var projectData: ProjectResponseModel?

    private var retryCount = 0
    private var maxRetries = 5
    private var retryTimer: Timer?

    init() {
        self.conversationId = UserDefaults.standard.string(forKey: UserDefaultsKey.conversationId)
        self.apiKey = UserDefaults.standard.string(forKey: UserDefaultsKey.apiKey)
        self.projectData = Heapchat.shared.projectData
    }

    func generateNewMessageId() {
        messageId = UUID().uuidString
    }
    
    func refreshAndConnect() {
        self.conversationId = UserDefaults.standard.string(forKey: UserDefaultsKey.conversationId)
        self.apiKey = UserDefaults.standard.string(forKey: UserDefaultsKey.apiKey)
        self.projectData = Heapchat.shared.projectData
        connect()
    }
    
    func handleIdChange() {
        let newConversationId = UserDefaults.standard.string(forKey: UserDefaultsKey.conversationId)
        let newCustomerId = UserDefaults.standard.string(forKey: UserDefaultsKey.customerId)
        
        // Check if IDs have actually changed
        if newConversationId != conversationId || newCustomerId != UserDefaults.standard.string(forKey: UserDefaultsKey.customerId) {
            Log.info("SocketService: IDs changed, reconnecting with new data")
            disconnect()
            refreshAndConnect()
        }
    }
    
    private func scheduleRetry() {
        guard retryCount < maxRetries else {
            Log.info("SocketService: Max retries reached")
            showActivityIndicator = false
            return
        }
        
        let delays = [1.0, 3.0, 6.0, 12.0, 24.0]
        let delay = delays[retryCount]
        
        Log.info("SocketService: Scheduling retry \(retryCount + 1)/\(maxRetries) in \(delay)s")
        
        retryTimer?.invalidate()
        retryTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.retryCount += 1
                self?.refreshAndConnect()
            }
        }
    }

    func connect() {
        guard
            let serverURL = URL(string: Constants.backendURL),
            let apiKey = apiKey,
            let conversationId = conversationId,
            !conversationId.isEmpty,
            let projectData = projectData
        else {
            Log.info("SocketService: Cannot connect - missing required data, scheduling retry")
            scheduleRetry()
            return 
        }

        Log.info("SocketService: Connecting with conversationId: \(conversationId)")
        retryCount = 0 // Reset retry count on successful connection attempt
        retryTimer?.invalidate()
        
        manager = SocketManager(
            socketURL: serverURL,
            config: [
                .log(true),
                .compress,
                .extraHeaders(["Authorization": "Bearer \(apiKey)"])
            ]
        )
        socket = manager?.defaultSocket

        setupEventHandlers()
        socket?.connect()
    }

    func disconnect() {
        socket?.disconnect()
        messages = [:]
        retryTimer?.invalidate()
        retryCount = 0
    }

    private func setupEventHandlers() {
        guard let socket = socket else { return }

        socket.on(clientEvent: .connect) { [weak self] _, _ in
            Log.info("SocketService: Connected to socket server")
            self?.retryCount = 0 // Reset retry count on successful connection
            self?.joinRoom()
            self?.joinAgentActivity()
        }

        socket.on(clientEvent: .disconnect) { [weak self] _, _ in
            Log.info("SocketService: Disconnected from socket server")
            self?.leaveRoom()
            self?.leaveAgentActivity()
        }

        socket.on(clientEvent: .error) { data, _ in
            if let error = data.first as? String {
                Log.error("Socket error: \(error)")
            }
        }

        socket.on(SocketEvent.previousMessages.rawValue) { [weak self] data, _ in
            guard let messagesData = data.first as? [[String: Any]] else { return }
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: messagesData)
                let decoder = JSONDecoder.iso8601Decoder
                let decodedMessages = try decoder.decode([MessageModel].self, from: jsonData)
                let exyteMessages: [(String, ExyteMessage)] = decodedMessages.map { ($0.id, $0.toExyteMessage()) }
                self?.messages = Dictionary(uniqueKeysWithValues: exyteMessages)
                self?.sortedMessages = exyteMessages
                    .map(\.1)
                    .sorted(by: { $0.createdAt < $1.createdAt })

                let unreadMessageIds = decodedMessages
                    .filter({ !$0.isFromCustomer && $0.readAt == nil })
                    .map({ $0.id })

                guard
                    let conversationId = self?.conversationId
                else {
                    Log.error("Conversation ID is nil")
                    return
                }

                let readStatusData = ReadStatusModel(
                    conversationId: conversationId,
                    messageIds: unreadMessageIds
                )

                if !unreadMessageIds.isEmpty {
                    if let jsonDict = readStatusData.toJSONDict() {
                        self?.socket?.emit(SocketEvent.readStatus.rawValue, jsonDict)
                    }
                }
                self?.showActivityIndicator = false
            } catch {
                self?.showActivityIndicator = false
                Log.error("Error decoding previous messages: \(error)")
            }
        }

        socket.on(SocketEvent.paginateMessages.rawValue) { [weak self] data, _ in
            guard let paginateData = data.first as? [[String: Any]] else { return }

            do {
                let jsonData = try JSONSerialization.data(withJSONObject: paginateData)
                let decoder = JSONDecoder.iso8601Decoder
                let messagesPage = try decoder.decode([MessageModel].self, from: jsonData)
                let exyteMessages: [(String, ExyteMessage)] = messagesPage.map { ($0.id, $0.toExyteMessage()) }

                Log.info("Exyte Messages: \(exyteMessages) for page \(self?.currentPage ?? 0)")

                self?.messages.merge(
                    Dictionary(uniqueKeysWithValues: exyteMessages),
                    uniquingKeysWith: { $1 }
                )

                Log.info("Merged messages: \(String(describing: self?.messages))")

                self?.sortedMessages = self?.messages.values
                    .sorted(by: { $0.createdAt < $1.createdAt }) ?? []

                Log.info("Sorted messages: \(String(describing: self?.sortedMessages))")
                self?.currentPage += 1 // Increment the current page after loading more messages
            } catch {
                Log.error("Error decoding paginated messages: \(error)")
            }
        }

        socket.on(SocketEvent.paginateMessagesMetadata.rawValue) { [weak self] data, _ in
            guard let metadata = data.first as? [String: Any] else { return }
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: metadata)
                let decoder = JSONDecoder.iso8601Decoder
                let metadataModel = try decoder.decode(PaginateMetadataModel.self, from: jsonData)
                self?.totalPages = metadataModel.totalPages
            } catch {
                Log.error("Error decoding pagination metadata: \(error)")
            }
        }

        socket.on(SocketEvent.chatMessage.rawValue) { [weak self] data, _ in
            guard let messageData = data.first as? [String: Any] else { return }
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: messageData)
                let decoder = JSONDecoder.iso8601Decoder
                let message = try decoder.decode(MessageModel.self, from: jsonData)
                
                // If the message with this ID already exists (i.e., it was a `.sending` message), replace it
                self?.messages[message.id] = message.toExyteMessage()
                self?.sortedMessages = self?.messages.values
                    .sorted(by: { $0.createdAt < $1.createdAt }) ?? []

                guard
                    let conversationId = self?.conversationId
                else {
                    Log.error("Conversation ID is nil")
                    return
                }

                // Update UUID for typing status
                if message.id == self?.messageId {
                    self?.generateNewMessageId()
                }

                if !message.isFromCustomer && message.readAt == nil {
                    let readStatusData = ReadStatusModel(
                        conversationId: conversationId,
                        messageIds: [message.id]
                    )

                    if let jsonDict = readStatusData.toJSONDict() {
                        self?.socket?.emit(SocketEvent.readStatus.rawValue, jsonDict)
                    }

                    self?.hasNewMessages = true
                }
            } catch {
                Log.error("Error decoding chat message: \(error)")
            }
        }

        socket.on(SocketEvent.readStatus.rawValue) { [weak self] data, _ in
            guard let readData = data.first as? [[String: Any]] else { return }
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: readData)
                let decoder = JSONDecoder.iso8601Decoder
                let updatedMessages = try decoder.decode([MessageModel].self, from: jsonData)

                for updatedMessage in updatedMessages {
                    self?.messages[updatedMessage.id] = updatedMessage.toExyteMessage()
                }
                
                self?.sortedMessages = self?.messages.values
                    .sorted(by: { $0.createdAt < $1.createdAt }) ?? []
            } catch {
                Log.error("Error updating message read status: \(error)")
            }
        }

        socket.on(SocketEvent.agentActivity.rawValue) { [weak self] data, _ in
            guard let activityData = data.first as? [String: Any] else { return }
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: activityData)
                let decoder = JSONDecoder.iso8601Decoder
                let agentActivity = try decoder.decode(AgentActivityModel.self, from: jsonData)
                Log.info("Agent activity available: \(agentActivity.available)")
                self?.isActive = agentActivity.available
            } catch {
                Log.error("Error decoding agent activity: \(error)")
            }
        }
    }

    func joinRoom() {
        guard
            let conversationId = self.conversationId
        else {
            Log.error("Conversation ID is nil")
            return
        }
        
        let joinData = JoinRoomModel(conversationId: conversationId)
        if let jsonDict = joinData.toJSONDict() {
            socket?.emit(SocketEvent.joinRoom.rawValue, jsonDict)
        }
    }

    func leaveRoom() {
        guard
            let conversationId = self.conversationId
        else {
            Log.error("Conversation ID is nil")
            return
        }

        let leaveData = JoinRoomModel(conversationId: conversationId)
        if let jsonDict = leaveData.toJSONDict() {
            socket?.emit(SocketEvent.leaveRoom.rawValue, jsonDict)
        }
    }

    func sendMessage(_ draft: DraftMessage) {
        guard
            let conversationId = self.conversationId,
            let customerId = UserDefaults.standard.string(forKey: UserDefaultsKey.customerId),
            showActivityIndicator == false
        else {
            Log.error("Customer ID or Conversation ID is nil")
            return
        }

        let customerName = UserDefaults.standard.string(forKey: UserDefaultsKey.customerName) ?? "Customer \(customerId.prefix(6))"
        let customerUser = ExyteUser(
            id: customerId,
            name: customerName,
            avatarURL: nil,
            isCurrentUser: true
        )

        Task {
            let exyteMessage = await Message.makeMessage(id: messageId, user: customerUser, status: .sending, draft: draft)
            messages[exyteMessage.id] = exyteMessage
            sortedMessages = messages.values.sorted(by: { $0.createdAt < $1.createdAt })
            
            let messageData = NewMessageModel(
                messageId: messageId,
                conversationId: conversationId,
                content: exyteMessage.text,
                isFromCustomer: true
            )

            if draft.medias.count > 0 {
                do {
                    try await BackendServiceAPI.shared.uploadMediaFile(
                        files: draft.medias,
                        messageId: messageId,
                        conversationId: conversationId,
                        content: exyteMessage.text.isEmpty ? "Attachment" : exyteMessage.text
                    )
                } catch {
                    Log.error("Error uploading media files: \(error)")
                }
                return
            }

            if let jsonDict = messageData.toJSONDict() {
                socket?.emit(SocketEvent.newMessage.rawValue, jsonDict)
            }
        }
    }

    func typingMessage(_ inputText: String) {
        guard
            let conversationId = self.conversationId,
            let customerId = UserDefaults.standard.string(forKey: UserDefaultsKey.customerId)
        else {
            Log.error("Customer ID or Conversation ID is nil")
            return
        }

        let typingMessageData = TypingMessageModel(
            messageId: messageId,
            conversationId: conversationId,
            typedMessage: inputText
        )

        if let jsonDict = typingMessageData.toJSONDict() {
            socket?.emit(SocketEvent.typingMessage.rawValue, jsonDict)
        }
    }

    func loadMoreMessages() {
        guard
            let conversationId = self.conversationId
        else {
            Log.error("Conversation ID is nil")
            return
        }

        if currentPage > totalPages {
            Log.info("No more pages to load")
            return
        }
        let loadMoreData = PaginateMessagesModel(
            conversationId: conversationId,
            page: currentPage + 1,
            limit: 20
        )

        Log.info("Loading page \(currentPage) for conversation \(conversationId)")

        if let jsonDict = loadMoreData.toJSONDict() {
            socket?.emit(SocketEvent.paginateMessages.rawValue, jsonDict)
        }
    }

    func joinAgentActivity() {
        guard
            let projectId = projectData?.id
        else {
            Log.error("Project ID is nil")
            return
        }

        let joinAgentActivityModel = JoinAgentActivityModel(
            projectId: projectId
        )

        Log.info("Joining agent activity for project \(projectId)")

        if let jsonDict = joinAgentActivityModel.toJSONDict() {
            socket?.emit(SocketEvent.joinAgentActivity.rawValue, jsonDict)
        }
    }

    func leaveAgentActivity() {
        guard
            let projectId = projectData?.id
        else {
            Log.error("Project ID is nil")
            return
        }

        let leaveAgentActivityModel = JoinAgentActivityModel(
            projectId: projectId
        )

        Log.info("Leaving agent activity for project \(projectId)")

        if let jsonDict = leaveAgentActivityModel.toJSONDict() {
            socket?.emit(SocketEvent.leaveAgentActivity.rawValue, jsonDict)
        }
    }
}
