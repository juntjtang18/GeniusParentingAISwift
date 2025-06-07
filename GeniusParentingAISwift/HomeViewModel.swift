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
        print("HomeViewModel: JWT token found.")

        let populateQuery = "populate[dailylessons][populate][courses][populate]=icon_image"
        guard let url = URL(string: "\(strapiUrl)/dailylesson?\(populateQuery)") else {
            errorMessage = "Invalid URL."
            isLoading = false
            print("HomeViewModel: Error - Invalid URL constructed.")
            return
        }
        print("HomeViewModel: Fetching from URL: \(url.absoluteString)")


        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                errorMessage = "Invalid server response."
                isLoading = false
                print("HomeViewModel: Error - Response is not a valid HTTPURLResponse.")
                return
            }
            
            print("HomeViewModel: Received HTTP status code: \(httpResponse.statusCode)")

            guard (200...299).contains(httpResponse.statusCode) else {
                errorMessage = "Server error."
                isLoading = false
                if let responseBody = String(data: data, encoding: .utf8) {
                    print("HomeViewModel: ---- ERROR RESPONSE BODY ----")
                    print(responseBody)
                    print("HomeViewModel: ---- END ERROR BODY ----")
                }
                return
            }
            
            // --- PRINT RAW JSON RESPONSE ---
            if let dataString = String(data: data, encoding: .utf8) {
                print("\nHomeViewModel: ---- RAW RESPONSE DATA START ----")
                print(dataString)
                print("HomeViewModel: ---- RAW RESPONSE DATA END ----\n")
            }
            
            print("HomeViewModel: Attempting to decode response...")
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let decodedResponse = try decoder.decode(StrapiSingleResponse<DailyLessonPlan>.self, from: data)
            print("HomeViewModel: Successfully decoded StrapiSingleResponse<DailyLessonPlan>.")

            // --- DUMP DECODED OBJECT ---
            print("\nHomeViewModel: ---- DECODED DATA DUMP START ----")
            dump(decodedResponse.data)
            print("HomeViewModel: ---- DECODED DATA DUMP END ----\n")

            let today = Calendar.current.component(.weekday, from: Date())
            let weekdayString = Calendar.current.weekdaySymbols[today - 1]
            print("HomeViewModel: Current day determined as '\(weekdayString)'.")
            
            let allLessonPlans = decodedResponse.data.attributes.dailylessons
            
            // --- LIST AVAILABLE DAYS ---
            let availableDays = allLessonPlans.map { $0.day }.joined(separator: ", ")
            print("HomeViewModel: Found \(allLessonPlans.count) lesson plans configured in Strapi for the following days: [\(availableDays)]")

            if let todaysPlan = allLessonPlans.first(where: { $0.day == weekdayString }) {
                self.todaysLessons = todaysPlan.courses.data
                print("HomeViewModel: Found a matching lesson plan for today. Number of courses: \(self.todaysLessons.count).")
                if self.todaysLessons.isEmpty {
                    print("HomeViewModel: WARNING - The lesson plan for today exists but contains 0 courses.")
                }
            } else {
                self.todaysLessons = []
                print("HomeViewModel: No lesson plan found for '\(weekdayString)'.")
            }

        } catch {
            errorMessage = "Failed to decode or fetch lessons: \(error.localizedDescription)"
            print("HomeViewModel: An error occurred in the fetch process: \(error)")
             if let decodingError = error as? DecodingError {
                print("HomeViewModel: Decoding error details: \(decodingError)")
            }
        }

        isLoading = false
        print("HomeViewModel: fetchDailyLessons finished. isLoading: \(isLoading), Todays lessons count: \(todaysLessons.count)")
    }
}
