//
//  HeapchatScreen.swift
//  Heapchat_swift-sdk
//
//  Created by Aman Kumar on 03/04/25.
//

import SwiftUI
import ExyteMediaPicker
import ExyteChat

public typealias ChatTheme = ExyteChat.ChatTheme
public typealias MediaPickerTheme = ExyteMediaPicker.MediaPickerTheme

public struct HeapchatScreenConfig {
    var chatTheme: ChatTheme? = nil
    var mediaPickerTheme: MediaPickerTheme? = nil
    var noMessageText: String? = nil
    
    public init(
        chatTheme: ChatTheme? = nil,
        mediaPickerTheme: MediaPickerTheme? = nil,
        noMessageText: String? = nil
    ) {
        self.chatTheme = chatTheme
        self.mediaPickerTheme = mediaPickerTheme
        self.noMessageText = noMessageText
    }
}

public struct HeapchatScreen: View {
    @StateObject private var socketService = SocketService()
    @Environment(\.colorScheme) var colorScheme

    var config: HeapchatScreenConfig? = nil
    
    public init(config: HeapchatScreenConfig? = nil) {
        self.config = config
    }

    public var body: some View {
        ZStack {
            config?.chatTheme?.colors.mainBG
                .ignoresSafeArea()
            
            VStack {
                // ChatView
                ChatView(messages: socketService.sortedMessages) { draft in
                    socketService.sendMessage(draft)
                }
                .onTextChange({ inputText in
                    socketService.typingMessage(inputText)
                })
                .enableLoadMore(pageSize: 3) { _ in
                    socketService.loadMoreMessages()
                }
                .keyboardDismissMode(.interactive)
                .betweenListAndInputViewBuilder({
                    if !socketService.isActive {
                        let view = AnyView(
                            Text(String(localized: "Currently unavailable. Leave a message and we’ll get back to you soon."))
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .bold()
                                .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
                            )

                        return view
                    }

                    return AnyView(EmptyView())
                })
                .hasNewMessages($socketService.hasNewMessages)
                .setAvailableInputs([.text, .media])
                .showMessageMenuOnLongPress(false)
                .messageUseMarkdown(true)
                .avatarSize(avatarSize: 24)
                .chatTheme(config?.chatTheme ?? ChatTheme())
                .mediaPickerTheme(config?.mediaPickerTheme ?? MediaPickerTheme())
                .onAppear {
                    socketService.showActivityIndicator = true
                    socketService.connect()
                    ScreenStateManager.shared.isCustomerSupportScreenOpen = true
                    
                    // Listen for ID changes
                    NotificationCenter.default.addObserver(
                        forName: .heapchatIdsChanged,
                        object: nil,
                        queue: .main
                    ) { _ in
                        Task { @MainActor in
                            socketService.handleIdChange()
                        }
                    }
                }
                .onDisappear {
                    socketService.disconnect()
                    ScreenStateManager.shared.isCustomerSupportScreenOpen = false
                    
                    // Remove notification observer
                    NotificationCenter.default.removeObserver(self, name: .heapchatIdsChanged, object: nil)
                }
                    
                HStack(spacing: 0) {
                    Text("Powered by ")
                    Link(destination: URL(string: "https://heap.chat")!) {
                        Text("Heap.chat")
                            .underline()
                    }
                }
                .padding(.bottom)
                .font(.footnote)
                .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
            }

            // ActivityIndicator
            if socketService.showActivityIndicator {
                LoadingIndicator()
            }

            // No support message
            if socketService.sortedMessages.isEmpty && !socketService.showActivityIndicator {
                Text(config?.noMessageText ?? String(localized: "How can we assist you today?"))
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .bold()
                    .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
            }
        }
        .navigationTitle(String(localized: "Support"))
    }
}

