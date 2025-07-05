import Foundation
import KeychainAccess
import os

/// A centralized, generic manager for handling all network requests.
class NetworkManager {
    static let shared = NetworkManager()
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let keychain = Keychain(service: Config.keychainService)
    private let logger = Logger(subsystem: "com.geniusparentingai.GeniusParentingAI", category: "NetworkManager")

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

    // MARK: - Public API Methods

    /// Fetches a list of items from an endpoint (e.g., /api/posts).
    /// The endpoint is expected to return a StrapiListResponse object.
    func fetchList<T: Codable>(from url: URL) async throws -> [T] {
        let response: StrapiListResponse<T> = try await performRequest(url: url, method: "GET")
        return response.data ?? []
    }

    /// Fetches a single item from an endpoint (e.g., /api/daily-tip).
    /// The endpoint is expected to return a StrapiSingleResponse object.
    func fetchSingle<T: Codable>(from url: URL) async throws -> T {
        let response: StrapiSingleResponse<T> = try await performRequest(url: url, method: "GET")
        return response.data
    }

    /// Fetches a resource directly without a 'data' wrapper (e.g., /api/users/me).
    func fetchDirect<T: Decodable>(from url: URL) async throws -> T {
        return try await performRequest(url: url, method: "GET")
    }

    /// Sends data to an endpoint and decodes the response.
    func post<RequestBody: Encodable, ResponseBody: Decodable>(to url: URL, body: RequestBody) async throws -> ResponseBody {
        return try await performRequest(url: url, method: "POST", body: body)
    }
    
    /// Updates data at an endpoint and decodes the response.
    func put<RequestBody: Encodable, ResponseBody: Decodable>(to url: URL, body: RequestBody) async throws -> ResponseBody {
        return try await performRequest(url: url, method: "PUT", body: body)
    }

    /// Sends a DELETE request to an endpoint.
    func delete(at url: URL) async throws {
        // We don't need the response, but the request must be successful.
        let _: EmptyResponse = try await performRequest(url: url, method: "DELETE")
    }

    // MARK: - Private Core Request Function

    /// The single, private function that handles all network requests.
    private func performRequest<ResponseBody: Decodable, RequestBody: Encodable>(
        url: URL,
        method: String,
        body: RequestBody? = nil
    ) async throws -> ResponseBody {
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = keychain["jwt"] {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else if url.absoluteString.contains("/api/auth/local") == false {
            // Log a warning if the token is missing for any request other than login/register.
            logger.warning("JWT token not found. Request to \(url.lastPathComponent) will be unauthenticated.")
        }
        
        if let body = body {
            request.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("Invalid response from server for URL \(url). Not an HTTPURLResponse.")
            throw URLError(.badServerResponse)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "No response body"
            logger.error("HTTP Error: \(method) request to \(url) failed with status code \(httpResponse.statusCode). Body: \(errorBody)")
            
            // Try to decode a specific Strapi error message for better diagnostics.
            if let errorResponse = try? decoder.decode(StrapiErrorResponse.self, from: data) {
                throw NSError(domain: "NetworkManager.StrapiError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorResponse.error.message])
            }
            
            throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: "Received status code \(httpResponse.statusCode)."])
        }
        
        // Handle successful but empty responses (e.g., from a DELETE request).
        if data.isEmpty {
            guard let empty = EmptyResponse() as? ResponseBody else {
                 throw URLError(.cannotParseResponse)
            }
            return empty
        }

        do {
            return try decoder.decode(ResponseBody.self, from: data)
        } catch {
            logger.error("Decoding Error: Failed to decode \(ResponseBody.self). Error: \(error.localizedDescription)")
            logger.error("Decoding Error Details: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                logger.error("Raw JSON that failed to decode:\n--- START JSON ---\n\(jsonString)\n--- END JSON ---")
            }
            throw error
        }
    }
    
    /// Overload for requests that don't have a request body (like GET and DELETE).
    private func performRequest<ResponseBody: Decodable>(url: URL, method: String) async throws -> ResponseBody {
        let emptyBody: EmptyPayload? = nil
        return try await performRequest(url: url, method: method, body: emptyBody)
    }
}

// MARK: - Helper Structs
private struct EmptyResponse: Codable {}
private struct EmptyPayload: Codable {}
