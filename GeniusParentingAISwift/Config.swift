import Foundation

struct Config {
    static var strapiBaseUrl: String {
        #if DEBUG
        return "http://localhost:8080" // Local development
        #else
        return "https://strapi.geniusparentingai.ca" // Production
        #endif
    }
}
