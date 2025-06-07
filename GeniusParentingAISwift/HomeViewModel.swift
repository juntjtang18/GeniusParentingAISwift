import Foundation
import KeychainAccess

@MainActor
class HomeViewModel: ObservableObject {
    @Published var todaysLessons: [LessonCourse] = []
    @Published var isLoading: Bool = true
    @Published var errorMessage: String? = nil

    private let strapiUrl = "\(Config.strapiBaseUrl)/api"
    private let keychain = Keychain(service: "com.geniusparentingai.GeniusParentingAISwift")

    func fetchDailyLessons() async {
        print("HomeViewModel: Starting fetchDailyLessons...")
        isLoading = true
        errorMessage = nil

        guard let token = keychain["jwt"] else {
            errorMessage = "Authentication token not found."
            isLoading = false
            print("HomeViewModel: Error - No JWT token found in Keychain.")
            return
        }
        
        // Reverted to the simpler query that fetches the full weekly plan.
        let populateQuery = "populate[dailylessons][populate][courses][populate][icon_image]=true"

        guard let url = URL(string: "\(strapiUrl)/dailylesson?\(populateQuery)") else {
            errorMessage = "Invalid URL."
            isLoading = false
            print("HomeViewModel: Error - Invalid URL constructed.")
            return
        }
        
        print("HomeViewModel: Fetching full weekly plan from URL: \(url.absoluteString)")

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                print("HomeViewModel: Received non-200 status code: \(statusCode)")
                errorMessage = "Server error."
                isLoading = false
                return
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let decodedResponse = try decoder.decode(StrapiSingleResponse<DailyLessonPlan>.self, from: data)

            // Re-introduce client-side filtering for reliability.
            let today = Calendar.current.component(.weekday, from: Date())
            let weekdayString = Calendar.current.weekdaySymbols[today - 1]
            print("HomeViewModel: Filtering for day: '\(weekdayString)' on the client.")

            let allLessonPlans = decodedResponse.data.attributes.dailylessons
            
            if let todaysPlan = allLessonPlans.first(where: { $0.day == weekdayString }) {
                self.todaysLessons = todaysPlan.courses.data
                print("HomeViewModel: Successfully found plan for today. Courses: \(self.todaysLessons.count).")
            } else {
                self.todaysLessons = []
                print("HomeViewModel: No lesson plan configured for '\(weekdayString)'.")
            }

        } catch {
            errorMessage = "Failed to decode or fetch lessons: \(error.localizedDescription)"
            print("HomeViewModel: An error occurred in the fetch process: \(error)")
             if let decodingError = error as? DecodingError {
                print("HomeViewModel: Decoding error details: \(decodingError)")
            }
        }

        isLoading = false
        print("HomeViewModel: fetchDailyLessons finished.")
    }
}
