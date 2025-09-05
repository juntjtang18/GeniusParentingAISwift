// GeniusParentingAISwift/NetworkManager.swift

import Foundation
import KeychainAccess

extension Notification.Name {
    static let didInvalidateSession = Notification.Name("didInvalidateSession")
}

class NetworkManager {
    static let shared = NetworkManager()
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let keychain = Keychain(service: Config.keychainService)
    private let logger = AppLogger(category: "NetworkManager")

    private init() {
        decoder = JSONDecoder()
        encoder = JSONEncoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        decoder.dateDecodingStrategy = .formatted(formatter)
        encoder.dateEncodingStrategy = .formatted(formatter)
    }

    func login(credentials: LoginCredentials) async throws -> AuthResponse {
        guard let url = URL(string: "\(Config.strapiBaseUrl)/api/auth/local?populate=deep") else { throw URLError(.badURL) }
        return try await performRequest(url: url, method: "POST", body: credentials)
    }

    func fetchUser() async throws -> StrapiUser {
        guard let url = URL(string: "\(Config.strapiBaseUrl)/api/users/me?populate=deep") else { throw URLError(.badURL) }
        return try await performRequest(url: url, method: "GET")
    }

    // ... (rest of the public methods are unchanged) ...
    func signup(payload: RegistrationPayload) async throws -> AuthResponse {
        guard let url = URL(string: "\(Config.strapiBaseUrl)/api/auth/local/register") else { throw URLError(.badURL) }
        return try await performRequest(url: url, method: "POST", body: payload)
    }

    func fetchPage<T: Codable>(baseURLComponents: URLComponents, page: Int, pageSize: Int = 25) async throws -> StrapiListResponse<T> {
        var components = baseURLComponents
        var queryItems = components.queryItems ?? []
        queryItems.removeAll { $0.name == "pagination[page]" || $0.name == "pagination[pageSize]" }
        queryItems.append(URLQueryItem(name: "pagination[page]", value: String(page)))
        queryItems.append(URLQueryItem(name: "pagination[pageSize]", value: String(pageSize)))
        components.queryItems = queryItems
        guard let url = components.url else { throw URLError(.badURL) }
        return try await performRequest(url: url, method: "GET")
    }

    func fetchAllPages<T: Codable>(baseURLComponents: URLComponents) async throws -> [T] {
        var allItems: [T] = []
        var currentPage = 1
        var totalPages = 1
        repeat {
            let response: StrapiListResponse<T> = try await fetchPage(baseURLComponents: baseURLComponents, page: currentPage, pageSize: 100)
            if let items = response.data { allItems.append(contentsOf: items) }
            if let pagination = response.meta?.pagination { totalPages = pagination.pageCount }
            currentPage += 1
        } while currentPage <= totalPages
        return allItems
    }
    
    func fetchSingle<T: Codable>(from url: URL) async throws -> T {
        let response: StrapiSingleResponse<T> = try await performRequest(url: url, method: "GET")
        return response.data
    }

    func fetchDirect<T: Decodable>(from url: URL) async throws -> T {
        return try await performRequest(url: url, method: "GET")
    }

    func post<RequestBody: Encodable, ResponseBody: Decodable>(to url: URL, body: RequestBody) async throws -> ResponseBody {
        return try await performRequest(url: url, method: "POST", body: body)
    }
    
    func put<RequestBody: Encodable, ResponseBody: Decodable>(to url: URL, body: RequestBody) async throws -> ResponseBody {
        return try await performRequest(url: url, method: "PUT", body: body)
    }

    func delete(at url: URL) async throws {
        let _: EmptyResponse = try await performRequest(url: url, method: "DELETE")
    }

    private func performRequest<ResponseBody: Decodable, RequestBody: Encodable>(url: URL, method: String, body: RequestBody? = nil) async throws -> ResponseBody {
        let functionName = #function
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let isAuthRequest = url.path.contains("/api/auth/local")
        if let token = keychain["jwt"], !isAuthRequest {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try encoder.encode(body)
        }
        
        logger.debug("[\(String(describing: self))::\(functionName)] - Sending \(method) request to URL: \(url)")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        
        // ADDED: Detailed logging for auth and user fetch responses
        if isAuthRequest || url.path.contains("/api/users/me") {
            if let jsonString = String(data: data, encoding: .utf8) {
                logger.info("[\(String(describing: self))::\(functionName)] - Full JSON response for \(url.path):\n\(jsonString)")
            }
        }

        if httpResponse.statusCode == 401 {
            logger.warning("[\(String(describing: self))::\(functionName)] - Received 401 Unauthorized. Invalidating session.")
            keychain["jwt"] = nil
            await MainActor.run { SessionManager.shared.currentUser = nil }
            NotificationCenter.default.post(name: .didInvalidateSession, object: nil)
            throw URLError(.userAuthenticationRequired)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "No response body"
            logger.error("[\(String(describing: self))::\(functionName)] - HTTP Error \(httpResponse.statusCode) for \(method) request to \(url). Body: \(errorBody)")
            if let errorResponse = try? decoder.decode(StrapiErrorResponse.self, from: data) {
                throw NSError(domain: "NetworkManager.StrapiError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorResponse.error.message])
            }
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: "Received status code \(httpResponse.statusCode)."])
        }
        
        if let jsonString = String(data: data, encoding: .utf8), !isAuthRequest, !url.path.contains("/api/users/me") {
            logger.debug("[\(String(describing: self))::\(functionName)] - Raw JSON Response from \(url):\n\(jsonString)")
        }
        
        if data.isEmpty {
            guard let empty = EmptyResponse() as? ResponseBody else { throw URLError(.cannotParseResponse) }
            return empty
        }

        do {
            return try decoder.decode(ResponseBody.self, from: data)
        } catch {
            logger.error("[\(String(describing: self))::\(functionName)] - Decoding Error for type \(ResponseBody.self). Error: \(error.localizedDescription)")
            if let jsonString = String(data: data, encoding: .utf8) { logger.error("[\(String(describing: self))::\(functionName)] - Raw JSON that failed to decode: \(jsonString)") }
            throw error
        }
    }
    
    private func performRequest<ResponseBody: Decodable>(url: URL, method: String) async throws -> ResponseBody {
        let emptyBody: EmptyPayload? = nil
        return try await performRequest(url: url, method: method, body: emptyBody)
    }
}

private struct EmptyResponse: Codable {}
//private struct EmptyPayload: Codable {}
