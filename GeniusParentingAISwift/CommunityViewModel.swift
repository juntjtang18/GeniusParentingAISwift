import Foundation
import KeychainAccess

// Models for decoding the response from fetching user's likes
struct LikeResponse: Codable, Identifiable {
    let id: Int
    let attributes: LikeAttributes
}
struct LikeAttributes: Codable {
    let post: StrapiSingleResponse<PostRelationData>?
}
struct PostRelationData: Codable, Identifiable {
    let id: Int
}


@MainActor
class CommunityViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var likedPosts: [Int: Int] = [:]
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    var hasMorePages: Bool {
        currentPage <= totalPages
    }
    
    private let cacheManager = CacheManager.shared
    private var currentPage = 1
    private var totalPages = 1
    private var isFetching = false
    private let keychain = Keychain(service: "com.geniusparentingai.GeniusParentingAISwift")
    private let strapiUrl = "\(Config.strapiBaseUrl)/api"
    
    init() {
        if let cachedPosts = cacheManager.load() {
            self.posts = cachedPosts
            print("ViewModel: Initialized with \(cachedPosts.count) posts from cache.")
        } else {
            print("ViewModel: No cached posts found.")
        }
    }

    func fetchLikedPosts() async {
        guard let token = keychain["jwt"],
              let userID = UserDefaults.standard.value(forKey: "userID") as? Int else {
            return
        }
        
        let filters = "filters[users_permissions_user][id][$eq]=\(userID)"
        let populate = "populate[post][fields][0]=id"
        guard let url = URL(string: "\(strapiUrl)/likes?\(filters)&\(populate)") else { return }
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let decodedResponse = try JSONDecoder().decode(StrapiListResponse<LikeResponse>.self, from: data)
            
            var likedPostsDict: [Int: Int] = [:]
            for like in decodedResponse.data {
                if let postID = like.attributes.post?.data.id {
                    likedPostsDict[postID] = like.id
                }
            }
            self.likedPosts = likedPostsDict
        } catch {
            print("CommunityViewModel: Failed to fetch liked posts: \(error)")
        }
    }

    func fetchPosts(isRefresh: Bool = false) async {
        if !isRefresh {
            guard !isFetching, hasMorePages else { return }
        }
        
        if isRefresh {
            currentPage = 1
            totalPages = 1
            // Don't clear posts immediately for a better refresh UX, they will be replaced.
        }
        
        isFetching = true
        isLoading = true
        
        if currentPage == 1 {
            await fetchLikedPosts()
        }
        
        guard let token = keychain["jwt"] else {
            errorMessage = "Authentication token not found."; isLoading = false; isFetching = false; return
        }
        let sortQuery = "sort[0]=create_time:desc"
        let populateQuery = "populate[users_permissions_user][populate][avatar]=true&populate[likes][count]=true"
        let paginationQuery = "pagination[page]=\(currentPage)&pagination[pageSize]=10"
        guard let url = URL(string: "\(strapiUrl)/posts?\(sortQuery)&\(populateQuery)&\(paginationQuery)") else {
            errorMessage = "Invalid URL."; isLoading = false; isFetching = false; return
        }
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, _) = try await URLSession.shared.data(for: request)
            let decodedResponse = try JSONDecoder().decode(StrapiPostResponse.self, from: data)
            
            if isRefresh {
                posts = decodedResponse.data
            } else {
                posts.append(contentsOf: decodedResponse.data)
            }
            
            totalPages = decodedResponse.meta.pagination?.pageCount ?? 1
            currentPage += 1

            if isRefresh {
                cacheManager.save(posts: self.posts)
            }
            
        } catch {
            errorMessage = "Failed to fetch posts: \(error.localizedDescription)"
            print("CommunityViewModel: Decoding error: \(error)")
        }
        
        isLoading = false
        isFetching = false
    }
    
    func likePost(post: Post) async {
        guard likedPosts[post.id] == nil,
              let token = keychain["jwt"],
              let userID = UserDefaults.standard.value(forKey: "userID") as? Int,
              let url = URL(string: "\(strapiUrl)/likes") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let requestBody: [String: Any] = ["data": ["post": post.id, "users_permissions_user": userID]]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return }
            
            let newLike = try JSONDecoder().decode(StrapiSingleResponse<LikeResponse>.self, from: data)
            likedPosts[post.id] = newLike.data.id
            if let index = posts.firstIndex(where: { $0.id == post.id }) { posts[index].likeCount += 1 }
        } catch {
            print("CommunityViewModel: Error liking post - \(error)")
        }
    }
    
    func unlikePost(post: Post) async {
        guard let likeID = likedPosts[post.id],
              let token = keychain["jwt"],
              let url = URL(string: "\(strapiUrl)/likes/\(likeID)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return }
            
            likedPosts.removeValue(forKey: post.id)
            if let index = posts.firstIndex(where: { $0.id == post.id }) { posts[index].likeCount -= 1 }
        } catch {
            print("CommunityViewModel: Error unliking post - \(error)")
        }
    }
}
