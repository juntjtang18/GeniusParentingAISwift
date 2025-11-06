import Foundation
import KeychainAccess

@MainActor
class CourseViewModel: ObservableObject {
    @Published var categories: [CategoryData] = []
    @Published var coursesByCategoryID: [Int: [Course]] = [:]
    @Published var loadingCategoryIDs = Set<Int>()
    @Published var errorMessage: String?
    @Published var initialLoadCompleted = false

    private let strapiUrl = "\(Config.strapiBaseUrl)/api"
    private let keychain = Keychain(service: Config.keychainService)
    private let lastViewedCategoryKey = "lastViewedCategoryID"

    // maps for locale bridging
    // en: order -> enID
    private var enIdByOrder: [Int: Int] = [:]
    // current-locale: id -> order
    private var localOrderById: [Int: Int] = [:]

    private func currentStrapiLocale() -> String {
        let appLang = Locale.current.language.languageCode?.identifier.lowercased() ?? "en"
        return appLang.hasPrefix("zh") ? "zh" : "en"
    }

    // MARK: - Initial fetch: load EN + current-locale categories, build maps, show localized if available
    func initialFetch() async {
        guard !initialLoadCompleted else { return }

        guard let token = keychain["jwt"] else {
            errorMessage = "Authentication token not found."
            return
        }

        let current = currentStrapiLocale()

        do {
            let enCats = try await fetchCategories(locale: "en", token: token)
            self.enIdByOrder = Dictionary(uniqueKeysWithValues:
                enCats.compactMap { cat in
                    guard let order = cat.attributes.order else { return nil }
                    return (order, cat.id)
                }
            )

            let localCats = (current == "en")
                ? enCats
                : try await fetchCategories(locale: current, token: token)

            if current != "en" {
                self.localOrderById = Dictionary(uniqueKeysWithValues:
                    localCats.compactMap { cat in
                        guard let order = cat.attributes.order else { return nil }
                        return (cat.id, order)
                    }
                )
            } else {
                self.localOrderById = Dictionary(uniqueKeysWithValues:
                    enCats.compactMap { cat in
                        guard let order = cat.attributes.order else { return nil }
                        return (cat.id, order)
                    }
                )
            }

            // Prefer localized categories if they exist, else fall back to EN
            let displayCats = (current != "en" && !localCats.isEmpty) ? localCats : enCats
            self.categories = displayCats
            self.initialLoadCompleted = true

            var priorityCategoryID: Int? = UserPreferencesManager.shared.value(forKey: lastViewedCategoryKey)
            if priorityCategoryID == nil || priorityCategoryID == 0 {
                priorityCategoryID = self.categories.first?.id
            }
            if let id = priorityCategoryID {
                await fetchCourses(for: id)
            }
        } catch {
            errorMessage = "Failed to fetch categories: \(error.localizedDescription)"
        }
    }

    // MARK: - Fetch courses with locale fallback and category-id mapping
    func fetchCourses(for categoryID: Int) async {
        guard coursesByCategoryID[categoryID] == nil, !loadingCategoryIDs.contains(categoryID) else { return }
        loadingCategoryIDs.insert(categoryID)
        defer { loadingCategoryIDs.remove(categoryID) }

        guard let token = keychain["jwt"] else {
            print("Authentication token not found for fetching courses.")
            return
        }

        let current = currentStrapiLocale()
        // Attempt 1: use tapped category id with current locale
        if let courses = try? await fetchCoursesPagewise(categoryId: categoryID, locale: current, token: token),
           !courses.isEmpty {
            self.coursesByCategoryID[categoryID] = courses
            return
        }

        // Attempt 2: map tapped id -> order -> EN id, then fetch with en
        var fallbackCourses: [Course] = []
        if let order = localOrderById[categoryID], let enId = enIdByOrder[order] {
            if let courses = try? await fetchCoursesPagewise(categoryId: enId, locale: "en", token: token),
               !courses.isEmpty {
                fallbackCourses = courses
            }
        }

        self.coursesByCategoryID[categoryID] = fallbackCourses // may be empty; UI can handle “no courses”
    }

    // MARK: - Helpers

    private func fetchCategories(locale: String, token: String) async throws -> [CategoryData] {
        let query = "sort=order&populate=header_image&locale=\(locale)"
        guard let url = URL(string: "\(strapiUrl)/coursecategories?\(query)") else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, _) = try await URLSession.shared.data(for: req)
        let decoded = try JSONDecoder().decode(StrapiListResponse<CategoryData>.self, from: data)
        return decoded.data ?? []
    }

    private func fetchCoursesPagewise(categoryId: Int, locale: String, token: String) async throws -> [Course] {
        var all: [Course] = []
        var page = 1
        var pageCount = 1
        let pageSize = 100

        repeat {
            let populateQuery   = "populate=icon_image,translations,coursecategory"
            let filterQuery     = "filters[coursecategory][id][$eq]=\(categoryId)"
            let sortQuery       = "sort[0]=order:asc&sort[1]=title:asc"
            let paginationQuery = "pagination[page]=\(page)&pagination[pageSize]=\(pageSize)"
            let localeQuery     = "locale=\(locale)"

            var comps = URLComponents(string: "\(strapiUrl)/courses")
            comps?.query = "\(populateQuery)&\(filterQuery)&\(sortQuery)&\(paginationQuery)&\(localeQuery)"

            guard let url = comps?.url else { break }

            var req = URLRequest(url: url)
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            req.setValue("application/json", forHTTPHeaderField: "Accept")

            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else { break }

            let decoded = try JSONDecoder().decode(StrapiListResponse<Course>.self, from: data)
            if let items = decoded.data { all.append(contentsOf: items) }
            if let p = decoded.meta?.pagination { pageCount = p.pageCount }
            page += 1
        } while page <= pageCount

        return all
    }
}
