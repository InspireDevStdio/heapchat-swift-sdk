//
//  BackendServiceAPI.swift
//  Heapdotchat_swift-sdk
//
//  Created by Aman Kumar on 03/04/25.
//

import Foundation

final class BackendServiceAPI {
    static let shared = BackendServiceAPI()
    private var baseURL: String {
        Constants.backendURL + "/api/v1/sdk"
    }
    
    func createCustomer() async throws -> String {
        guard let apiKey = UserDefaults.standard.string(forKey: UserDefaultsKey.apiKey) else {
            throw NSError(domain: "Heapdotchat", code: 0, userInfo: [NSLocalizedDescriptionKey: "API key is nil"])
        }
        guard let url = URL(string: baseURL + "/customer") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder.iso8601Decoder
        let responseData = try decoder.decode(CustomerResponseModel.self, from: data)
        Log.info("Customer created with ID: \(responseData.id)")
        return responseData.id
    }
    
    func setCustomerCustomId(customId: String, customerId: String) async throws -> CustomerResponseModel {
        guard let apiKey = UserDefaults.standard.string(forKey: UserDefaultsKey.apiKey) else {
            throw NSError(domain: "Heapdotchat", code: 0, userInfo: [NSLocalizedDescriptionKey: "API key is nil"])
        }
        
        guard let url = URL(string: baseURL + "/customer/custom-id") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let payload = [
            "customId": customId,
            "customerId": customerId
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder.iso8601Decoder
        let responseData = try decoder.decode(CustomerResponseModel.self, from: data)
        
        return responseData
    }
    
    func setCustomerData(customerData: CustomerPayloadModel) async throws -> CustomerResponseModel {
        guard let apiKey = UserDefaults.standard.string(forKey: UserDefaultsKey.apiKey) else {
            throw NSError(domain: "Heapdotchat", code: 0, userInfo: [NSLocalizedDescriptionKey: "API key is nil"])
        }
        
        guard let url = URL(string: baseURL + "/customer/update-data") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        request.httpBody = try JSONEncoder().encode(customerData)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder.iso8601Decoder
        let responseData = try decoder.decode(CustomerResponseModel.self, from: data)
        return responseData
    }
    
    func createConversation(for conversationPayloadModel: ConversationPayloadModel) async throws -> String {
        guard let apiKey = UserDefaults.standard.string(forKey: UserDefaultsKey.apiKey) else {
            throw NSError(domain: "Heapdotchat", code: 0, userInfo: [NSLocalizedDescriptionKey: "API key is nil"])
        }
        
        guard let url = URL(string: baseURL + "/conversation") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        request.httpBody = try JSONEncoder().encode(conversationPayloadModel)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        let responseData = try decoder.decode(ConversationResponseModel.self, from: data)
        return responseData.id
    }
    
    func uploadMediaFile(files: [ExyteMedia], messageId: String, conversationId: String, content: String) async throws {
        guard let apiKey = UserDefaults.standard.string(forKey: UserDefaultsKey.apiKey) else {
            throw NSError(domain: "Heapdotchat", code: 0, userInfo: [NSLocalizedDescriptionKey: "API key is nil"])
        }
        
        guard let url = URL(string: baseURL + "/storage/media-upload") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var bodyData = Data()
        
        // Add chat attachment data
        let fields: [String: Any] = [
            "messageId": messageId,
            "conversationId": conversationId,
            "content": content,
            "isFromCustomer": true
        ]
        
        // Add form fields
        for (key, value) in fields {
            bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
            bodyData.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            bodyData.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        // Add files
        for (index, file) in files.enumerated() {
            guard let fileData = await file.getData() else {
                throw NSError(domain: "Heapdotchat", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get file data"])
            }

            guard let fileURL = await file.getURL() else {
                throw NSError(domain: "Heapdotchat", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get file URL"])
            }

            Log.info("Uploading file: \(fileURL) with size: \(fileData.count) bytes")
            
            // Extract file extension from the original URL
            let fileExtension = fileURL.pathExtension.lowercased()
            let originalFileName = fileURL.lastPathComponent
            
            // Determine MIME type based on file extension
            let mimeType = getMimeType(for: fileExtension)
            
            // Use original filename or generate one with correct extension
            let fileName = originalFileName.isEmpty ? "\(file.id).\(fileExtension)" : originalFileName
            
            bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
            bodyData.append("Content-Disposition: form-data; name=\"files\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
            bodyData.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
            bodyData.append(fileData)
            bodyData.append("\r\n".data(using: .utf8)!)
        }
        
        // Add final boundary
        bodyData.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = bodyData
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
    
    func saveDeviceToken(deviceToken: DeviceTokenPayloadModel) async throws {
        guard let apiKey = UserDefaults.standard.string(forKey: UserDefaultsKey.apiKey) else {
            throw NSError(domain: "Heapdotchat", code: 0, userInfo: [NSLocalizedDescriptionKey: "API key is nil"])
        }
        
        guard let url = URL(string: baseURL + "/customer/device-token") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        request.httpBody = try JSONEncoder().encode(deviceToken)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    func saveDeviceLanguage(_ deviceLanguageCode: DeviceLanguagePayloadModel) async throws {
        guard let apiKey = UserDefaults.standard.string(forKey: UserDefaultsKey.apiKey) else {
            throw NSError(domain: "Heapdotchat", code: 0, userInfo: [NSLocalizedDescriptionKey: "API key is nil"])
        }

        guard let url = URL(string: baseURL + "/customer/language-code") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        request.httpBody = try JSONEncoder().encode(deviceLanguageCode)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    func saveCustomData(_ customerCustomData: CustomerCustomDataPayloadModel) async throws {
        guard let apiKey = UserDefaults.standard.string(forKey: UserDefaultsKey.apiKey) else {
            throw NSError(domain: "Heapdotchat", code: 0, userInfo: [NSLocalizedDescriptionKey: "API key is nil"])
        }

        guard let url = URL(string: baseURL + "/customer/custom-data") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        request.httpBody = try JSONEncoder().encode(customerCustomData)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    func getProject() async throws -> ProjectResponseModel {
        guard let apiKey = UserDefaults.standard.string(forKey: UserDefaultsKey.apiKey) else {
            throw NSError(domain: "Heapdotchat", code: 0, userInfo: [NSLocalizedDescriptionKey: "API key is nil"])
        }

        guard let url = URL(string: baseURL + "/project") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder.iso8601Decoder
        let responseData = try decoder.decode(ProjectResponseModel.self, from: data)
        return responseData
    }
}
