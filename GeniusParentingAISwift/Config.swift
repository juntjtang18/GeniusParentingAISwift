import Foundation

struct Config {
    static let keychainService = "com.geniusparentingai.GeniusParentingAISwift"
    static var strapiBaseUrl: String {
        #if DEBUG
        #if USE_LOCAL_IP
        return "http://192.168.1.66:8080" // Use your actual IP
        #else
        return "http://localhost:8080"
        #endif
        #else
        return "https://strapi.geniusparentingai.ca"
        #endif
    }
    /*
    // NEW: URL for the Subscription Subsystem
    static var subscriptionSubsystemBaseUrl: String {
        #if DEBUG
        // For local development, both might run on different ports
        // Or you might proxy them under the same IP. Adjust as needed.
        return "http://192.168.1.66:2337"
        //return "http://gpasubsys.geniusParentingAI.ca"
        #else
        return "http://gpasubsys.geniusParentingAI.ca"
        #endif
    }
     */
}
