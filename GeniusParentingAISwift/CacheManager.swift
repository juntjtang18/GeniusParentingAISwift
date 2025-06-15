import Foundation

class CacheManager {
    static let shared = CacheManager() // Singleton for easy access
    
    private let fileManager = FileManager.default
    private let cacheFileName = "cachedPosts.json"
    
    private var cacheURL: URL? {
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("CacheManager: Could not find documents directory.")
            return nil
        }
        return documentsDirectory.appendingPathComponent(cacheFileName)
    }
    
    private init() {}

    func save(posts: [Post]) {
        guard let url = cacheURL else { return }
        
        do {
            let data = try JSONEncoder().encode(posts)
            try data.write(to: url)
            print("CacheManager: Successfully saved \(posts.count) posts to disk.")
        } catch {
            print("CacheManager: Failed to save posts - \(error)")
        }
    }
    
    func load() -> [Post]? {
        guard let url = cacheURL, fileManager.fileExists(atPath: url.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let posts = try JSONDecoder().decode([Post].self, from: data)
            print("CacheManager: Successfully loaded \(posts.count) posts from disk.")
            return posts
        } catch {
            print("CacheManager: Failed to load or decode posts - \(error)")
            return nil
        }
    }
}
