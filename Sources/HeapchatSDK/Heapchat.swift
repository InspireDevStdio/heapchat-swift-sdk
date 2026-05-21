//
//  Heapchat.swift
//  Heapchat_swift-sdk
//
//  Created by Aman Kumar on 03/04/25.
//

import Foundation
import UIKit

// MARK: - Notification Names
extension Notification.Name {
    static let heapchatIdsChanged = Notification.Name("heapchatIdsChanged")
}

public final class Heapchat {
    public static let shared = Heapchat()
    
    private var apiKey: String? = nil
    var projectData: ProjectResponseModel? = nil

    private var isConfigured = false
    
    private var pendingCustomId: String?
    private var pendingCustomerData: [String: String?]?
    private var pendingDeviceToken: String?
    private var pendingCustomData: [String: String]?

    public func configure(apiKey: String) {
        configure(apiKey: apiKey, backendURL: Constants.defaultBackendURL)
    }

    public func configure(apiKey: String, backendURL: String) {
        let normalizedBackendURL = backendURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let previousApiKey = UserDefaults.standard.string(forKey: UserDefaultsKey.apiKey)
        let previousBackendURL = UserDefaults.standard.string(forKey: UserDefaultsKey.backendURL) ?? Constants.defaultBackendURL
        let isEnvironmentChanged = previousApiKey != apiKey || previousBackendURL != normalizedBackendURL

        if isEnvironmentChanged {
            UserDefaults.standard.removeObject(forKey: UserDefaultsKey.customerId)
            UserDefaults.standard.removeObject(forKey: UserDefaultsKey.conversationId)
        }

        self.apiKey = apiKey
        
        UserDefaults.standard.set(apiKey, forKey: UserDefaultsKey.apiKey)
        UserDefaults.standard.set(normalizedBackendURL, forKey: UserDefaultsKey.backendURL)
        Task {
            await createCustomer()
            await createConversation()
            await getProject()
            isConfigured = true
            saveDeviceLanguage()
            setDeviceToken(pendingDeviceToken ?? "")
            login(userId: pendingCustomId ?? "")
            setCustomerData(UserDataModel(
                name: pendingCustomerData?["name"] ?? nil,
                email: pendingCustomerData?["email"] ?? nil,
                phone: pendingCustomerData?["phone"] ?? nil
            ))
            setCustomData(pendingCustomData ?? [:])
        }
    }
    
    // Create customer
    private func createCustomer() async {
        // Get customer data from UserDefaults
        let storedCustomerId = UserDefaults.standard.string(forKey: UserDefaultsKey.customerId)
        
        // If customer ID already exists, return
        guard storedCustomerId == nil else {
            return
        }
        
        // Create customer data
        do {
            let newCustomerId = try await BackendServiceAPI.shared.createCustomer()
            UserDefaults.standard.set(newCustomerId, forKey: UserDefaultsKey.customerId)
            Log.info("Flow: Created customer with ID: \(newCustomerId)")
        } catch {
            Log.error("Error creating customer: \(error.localizedDescription)")
        }
    }
    
    // Create conversation
    private func createConversation() async {
        // Get customer data from UserDefaults
        let storedConversationId = UserDefaults.standard.string(forKey: UserDefaultsKey.conversationId)
        let storedCustomerId = UserDefaults.standard.string(forKey: UserDefaultsKey.customerId)
        
        Log.info("Stored Conversation ID: \(storedConversationId ?? "nil")")
        
        // If conversation ID already exists, return
        guard storedConversationId == nil else {
            return
        }
        
        // Create conversation data
        do {
            guard let customerId = storedCustomerId else {
                throw NSError(domain: "Heapchat", code: 0, userInfo: [NSLocalizedDescriptionKey: "Customer ID is nil"])
            }
            let conversationPayload = ConversationPayloadModel(customerId: customerId)
            let newConversationId = try await BackendServiceAPI.shared.createConversation(for: conversationPayload)
            UserDefaults.standard.set(newConversationId, forKey: UserDefaultsKey.conversationId)
            Log.info("Flow: Created conversation with ID: \(newConversationId)")
        } catch {
            Log.error("Error creating conversation: \(error.localizedDescription)")
        }
    }
    
    public func login(userId: String) {
        // Set pending custom ID
        pendingCustomId = userId
        
        let storedCustomerId = UserDefaults.standard.string(forKey: UserDefaultsKey.customerId)
        
        guard
            let storedCustomerId = storedCustomerId,
            !userId.isEmpty
        else {
            Log.error("Customer ID is nil or user ID is empty")
            return
        }
        
        // Prevent login if already logged in, allow if its a different ID
        let storedCustomId = UserDefaults.standard.string(forKey: UserDefaultsKey.customerCustomId)
        guard storedCustomId != userId else {
            Log.info("Already logged in with the same user ID")
            return
        }
        
        Task {
            do {
                if isConfigured {
                    let customerData = try await BackendServiceAPI.shared.setCustomerCustomId(customId: userId, customerId: storedCustomerId)
                    Log.info("Customer data: \(customerData)")
                    
                    UserDefaults.standard.set(customerData.id, forKey: UserDefaultsKey.customerId)
                    UserDefaults.standard.set(customerData.conversation?.id, forKey: UserDefaultsKey.conversationId)
                    UserDefaults.standard.set(customerData.customId, forKey: UserDefaultsKey.customerCustomId)
                    Log.info("Flow: Set customer custom ID: \(userId)")
                    
                    // Notify socket service about ID changes
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .heapchatIdsChanged, object: nil)
                    }
                }
            } catch {
                Log.error("Error setting customer custom ID: \(error.localizedDescription)")
            }
        }
    }
    
    public func logout() {
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.customerId)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.customerName)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.customerEmail)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.customerPhone)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.conversationId)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.customerCustomId)
        Log.info("Flow: Logged out")
        
        Task {
            await createCustomer()
            await createConversation()
            setDeviceToken(pendingDeviceToken ?? "")
            saveDeviceLanguage()
        }
        Log.info("Flow: Created customer and conversation after logout")
    }
    
    public func setCustomerData(_ userData: UserDataModel) {
        // Set pending customer data
        pendingCustomerData = [
            "name": userData.name,
            "email": userData.email,
            "phone": userData.phone
        ]
        
        let storedCustomerId = UserDefaults.standard.string(forKey: UserDefaultsKey.customerId)
        
        guard let storedCustomerId = storedCustomerId else {
            Log.error("Customer ID is nil")
            return
        }
        
        // Prevent setting customer data if already set, allow if its a different data
        let storedName = UserDefaults.standard.string(forKey: UserDefaultsKey.customerName)
        let storedEmail = UserDefaults.standard.string(forKey: UserDefaultsKey.customerEmail)
        let storedPhone = UserDefaults.standard.string(forKey: UserDefaultsKey.customerPhone)
        
        let nameChanged = (userData.name != nil) && (userData.name != storedName)
        let emailChanged = (userData.email != nil) && (userData.email != storedEmail)
        let phoneChanged = (userData.phone != nil) && (userData.phone != storedPhone)
        
        guard nameChanged || emailChanged || phoneChanged else {
            Log.info("Customer data already set")
            return
        }
        
        Task {
            do {
                if isConfigured {
                    let customerPayload = CustomerPayloadModel(
                        id: storedCustomerId,
                        name: userData.name,
                        email: userData.email,
                        phone: userData.phone
                    )
                    let customerData = try await BackendServiceAPI.shared.setCustomerData(customerData: customerPayload)
                    
                    UserDefaults.standard.set(customerData.name, forKey: UserDefaultsKey.customerName)
                    UserDefaults.standard.set(customerData.email, forKey: UserDefaultsKey.customerEmail)
                    UserDefaults.standard.set(customerData.phone, forKey: UserDefaultsKey.customerPhone)
                    UserDefaults.standard.set(customerData.id, forKey: UserDefaultsKey.customerId)
                    UserDefaults.standard.set(customerData.conversation?.id, forKey: UserDefaultsKey.conversationId)
                    Log.info("Flow: Set customer data: \(customerData)")
                    
                    // Notify socket service about ID changes
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .heapchatIdsChanged, object: nil)
                    }
                }
            } catch {
                Log.error("Error setting customer data: \(error.localizedDescription)")
            }
        }
    }
    
    public func setDeviceToken(_ deviceToken: String) {
        pendingDeviceToken = deviceToken
        
        let storedCustomerId = UserDefaults.standard.string(forKey: UserDefaultsKey.customerId)
        
        guard
            let customerId = storedCustomerId,
            !deviceToken.isEmpty
        else {
            Log.error("Customer ID is nil or device token is empty")
            return
        }
        
        Task {
            do {
                if isConfigured {
                    let deviceTokenPayload = DeviceTokenPayloadModel(
                        token: deviceToken,
                        customerId: customerId
                    )
                    try await BackendServiceAPI.shared.saveDeviceToken(deviceToken: deviceTokenPayload)
                }
            } catch {
                Log.error("Error saving device token: \(error.localizedDescription)")
            }
        }
    }

    private func saveDeviceLanguage() {
        if let languageCode = Locale.preferredLanguages.first?.prefix(2) {
            Task {
                do {
                    let storedCustomerId = UserDefaults.standard.string(forKey: UserDefaultsKey.customerId)
                    guard let customerId = storedCustomerId else {
                        Log.error("Customer ID is nil")
                        return
                    }

                    let deviceLanguagePayload = DeviceLanguagePayloadModel(
                        customerId: customerId,
                        languageCode: String(languageCode)
                    )

                    try await BackendServiceAPI.shared.saveDeviceLanguage(deviceLanguagePayload)
                } catch {
                    Log.error("Error saving device language: \(error.localizedDescription)")
                }
            }
        }
    }

    public func setCustomData(_ customData: [String: String]) {
        pendingCustomData = customData

        let storedCustomerId = UserDefaults.standard.string(forKey: UserDefaultsKey.customerId)

        guard
            let customerId = storedCustomerId,
            !customData.isEmpty
        else {
            Log.error("Customer ID is nil or custom data is empty")
            return
        }
        
        Task {
            do {
                if isConfigured {
                    let customDataPayload = CustomerCustomDataPayloadModel(
                        customerId: customerId,
                        customData: customData
                    )
                    try await BackendServiceAPI.shared.saveCustomData(customDataPayload)
                    Log.info("Flow: Set customer custom data: \(customData)")
                }
            } catch {
                Log.error("Error setting customer custom data: \(error.localizedDescription)")
            }
        }
    }

    // Get project
    private func getProject() async {
        guard let apiKey = apiKey else {
            Log.error("API Key is not configured")
            return
        }
        
        do {
            projectData = try await BackendServiceAPI.shared.getProject()
            Log.info("Project data fetched successfully: \(String(describing: projectData))")
        } catch {
            Log.error("Error fetching project data: \(error.localizedDescription)")
        }
    }

    // Handle notification
    public func handleNotification(response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) -> Bool {
        let userInfo = response.notification.request.content.userInfo
        Log.info("Flow: User info: \(userInfo)")
        
        // Suppress notification if CustomerSupportScreen is open
        if ScreenStateManager.shared.isCustomerSupportScreenOpen {
            Log.info("Notification suppressed because CustomerSupportScreen is open")
            completionHandler()
            return false
        }

        // Check if the notification type is supportMessage from Heapchat
        if let notificationType = userInfo["notificationType"] as? String {
            switch notificationType {
            case "supportMessage":
                if let conversationId = userInfo["conversationId"] as? String {
                    let storedConversationId = UserDefaults.standard.string(forKey: UserDefaultsKey.conversationId)
                    if storedConversationId != conversationId {
                        Log.info("Notification suppressed because conversation ID does not match")
                        completionHandler()
                        return false
                    }
                } else {
                    Log.info("Notification suppressed because conversation ID is missing in payload")
                    completionHandler()
                    return false
                }
                return true
            default:
                Log.info("Unknown notification type: \(notificationType)")
                completionHandler()
                return false
            }
        }

        // Allow other notification types to pass through
        Log.info("Notification type missing in payload")
        return false
    }
    
    public func suppressNotification(notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        
        // Suppress notification if CustomerSupportScreen is open
        if ScreenStateManager.shared.isCustomerSupportScreenOpen {
            Log.info("Notification suppressed because CustomerSupportScreen is open")
            completionHandler([])
            return
        }
        
        // Check if the notification type is supportMessage from Heapchat
        if let notificationType = userInfo["notificationType"] as? String {
            switch notificationType {
            case "supportMessage":
                if let conversationId = userInfo["conversationId"] as? String {
                    let storedConversationId = UserDefaults.standard.string(forKey: UserDefaultsKey.conversationId)
                    if storedConversationId != conversationId {
                        Log.info("Notification suppressed because conversation ID does not match")
                        completionHandler([])
                        return
                    }
                } else {
                    Log.info("Notification suppressed because conversation ID is missing in payload")
                    completionHandler([])
                    return
                }
            default:
                Log.info("Unknown notification type: \(notificationType)")
            }
        }

        // Show the notification with sound, badge, and banner
        completionHandler([.banner, .sound, .badge])
    }
}
