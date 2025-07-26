import Foundation
import KeychainAccess

@MainActor
class CourseViewModel: ObservableObject {
    @Published var categories: [CategoryData] = []
    @Published var loadingCategoryIDs = Set<Int>()
    @Published var errorMessage: String?
    @Published var initialLoadCompleted = false

    private let strapiUrl = "\(Config.strapiBaseUrl)/api"
    private let keychain = Keychain(service: Config.keychainService)
    private let lastViewedCategoryKey = "lastViewedCategoryID"

    var coursesByCategoryID: [Int: [Course]] {
        get {
            guard let userId = SessionManager.shared.currentUser?.id else { return [:] }
            return SessionStore.shared.getUserData("coursesByCategoryID", userId: userId) ?? [:]
        }
        set {
            if let userId = SessionManager.shared.currentUser?.id {
                SessionStore.shared.setUserData(newValue, forKey: "coursesByCategoryID", userId: userId)
            }
        }
    }

    func initialFetch() async {
        guard !initialLoadCompleted else { return }
        
        guard let token = keychain["jwt"] else {
            errorMessage = "Authentication token not found."
            return
        }
        
        let categoryQuery = "sort=order&populate=header_image"
        guard let url = URL(string: "\(strapiUrl)/coursecategories?\(categoryQuery)") else {
            errorMessage = "Internal error: Invalid URL."
            return
        }

        do {
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoder = JSONDecoder()
            let decodedResponse = try decoder.decode(StrapiListResponse<CategoryData>.self, from: data)
            
            self.categories = decodedResponse.data ?? []
            SessionStore.shared.setNonUserData(categories, forKey: "categories")
            self.initialLoadCompleted = true

            var priorityCategoryID: Int? = UserPreferencesManager.shared.value(forKey: lastViewedCategoryKey)
            if priorityCategoryID == nil || priorityCategoryID == 0 {
                priorityCategoryID = self.categories.first?.id
            }
            
            if let categoryID = priorityCategoryID {
                await fetchCourses(for: categoryID)
            }
        } catch {
            errorMessage = "Failed to fetch categories: \(error.localizedDescription)"
        }
    }

    func fetchCourses(for categoryID: Int) async {
        guard coursesByCategoryID[categoryID] == nil, !loadingCategoryIDs.contains(categoryID) else {
            return
        }

        guard let userId = SessionManager.shared.currentUser?.id else {
            errorMessage = "No active user session."
            return
        }

        loadingCategoryIDs.insert(categoryID)
        defer { loadingCategoryIDs.remove(categoryID) }

        guard let token = keychain["jwt"] else {
            print("Authentication token not found for fetching courses.")
            return
        }

        var allCourses: [Course] = []
        var currentPage = 1
        var totalPages = 1
        let pageSize = 100

        do {
            repeat {
                let populateQuery = "populate=icon_image,translations,coursecategory"
                let filterQuery = "filters[coursecategory][id][$eq]=\(categoryID)"
                let sortQuery = "sort[0]=order:asc&sort[1]=title:asc"
                let paginationQuery = "pagination[page]=\(currentPage)&pagination[pageSize]=\(pageSize)"
                
                var urlComponents = URLComponents(string: "\(strapiUrl)/courses")
                urlComponents?.query = "\(populateQuery)&\(filterQuery)&\(sortQuery)&\(paginationQuery)"

                guard let url = urlComponents?.url else {
                    print("Internal error: Invalid URL for fetching courses.")
                    break
                }

                var request = URLRequest(url: url)
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Accept")

                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                    print("Server error \(statusCode) while fetching courses for category \(categoryID) on page \(currentPage).")
                    break
                }
                
                let decoder = JSONDecoder()
                let decodedResponse = try decoder.decode(StrapiListResponse<Course>.self, from: data)

                if let newCourses = decodedResponse.data {
                    allCourses.append(contentsOf: newCourses)
                }

                if let pagination = decodedResponse.meta?.pagination {
                    totalPages = pagination.pageCount
                }
                
                currentPage += 1

            } while currentPage <= totalPages

            var currentCourses = coursesByCategoryID
            currentCourses[categoryID] = allCourses
            SessionStore.shared.setUserData(currentCourses, forKey: "coursesByCategoryID", userId: userId)

        } catch {
            print("Failed to fetch or decode courses for category \(categoryID): \(error.localizedDescription)")
            if let decodingError = error as? DecodingError {
                print("Decoding error details: \(decodingError)")
            }
        }
    }
}
