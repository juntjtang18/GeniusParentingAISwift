import Foundation
import KeychainAccess

@MainActor
class HomeViewModel: ObservableObject {
    @Published var todaysLessons: [LessonCourse] = []
    @Published var isLoading: Bool = true
    @Published var errorMessage: String? = nil

    @Published var hotTopics: [Topic] = []
    @Published var isLoadingHotTopics: Bool = true
    @Published var hotTopicsErrorMessage: String? = nil
    
    // --- ADDITIONS START ---
    @Published var dailyTips: [Tip] = []
    @Published var isLoadingDailyTips: Bool = true
    @Published var dailyTipsErrorMessage: String? = nil
    // --- ADDITIONS END ---

    private let strapiUrl = "\(Config.strapiBaseUrl)/api"
    private let keychain = Keychain(service: "com.geniusparentingai.GeniusParentingAISwift")

    // --- NEW FUNCTION START ---
    func fetchDailyTips() async {
        print("HomeViewModel: Starting fetchDailyTips...")
        isLoadingDailyTips = true
        dailyTipsErrorMessage = nil

        guard let token = keychain["jwt"] else {
            dailyTipsErrorMessage = "Authentication token not found."
            isLoadingDailyTips = false
            return
        }
        
        // Populate the 'tips' relation and the 'icon_image' within each tip
        let populateQuery = "populate[tips][populate][icon_image]=true"
        
        guard let url = URL(string: "\(strapiUrl)/daily-tip?\(populateQuery)") else {
            dailyTipsErrorMessage = "Invalid URL."
            isLoadingDailyTips = false
            return
        }
        
        print("HomeViewModel: Fetching daily tips from URL: \(url.absoluteString)")

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                print("HomeViewModel: Received non-200 status code for daily tips: \(statusCode)")
                dailyTipsErrorMessage = "Server error or no tips configured."
                isLoadingDailyTips = false
                return
            }
            
            let decoder = JSONDecoder()
            let decodedResponse = try decoder.decode(StrapiSingleResponse<DailyTip>.self, from: data)
            
            self.dailyTips = decodedResponse.data.attributes.tips.data
            print("HomeViewModel: Successfully fetched \(self.dailyTips.count) daily tips.")

        } catch {
            dailyTipsErrorMessage = "Failed to fetch daily tips: \(error.localizedDescription)"
            print("HomeViewModel: An error occurred in the daily tips fetch process: \(error)")
            if let decodingError = error as? DecodingError {
               print("HomeViewModel: Daily Tip Decoding error details: \(decodingError)")
           }
        }

        isLoadingDailyTips = false
        print("HomeViewModel: fetchDailyTips finished.")
    }
    // --- NEW FUNCTION END ---

    func fetchHotTopics() async {
        print("HomeViewModel: Starting fetchHotTopics...")
        isLoadingHotTopics = true
        hotTopicsErrorMessage = nil

        guard let token = keychain["jwt"] else {
            hotTopicsErrorMessage = "Authentication token not found."
            isLoadingHotTopics = false
            return
        }
        
        let populateQuery = "populate[topics][populate][icon_image]=true"
        
        guard let url = URL(string: "\(strapiUrl)/hot-topic?\(populateQuery)") else {
            hotTopicsErrorMessage = "Invalid URL."
            isLoadingHotTopics = false
            return
        }
        
        print("HomeViewModel: Fetching hot topics from URL: \(url.absoluteString)")

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // --- DEBUBGING STEP: Print the raw JSON string from the server ---
            if let rawJSONString = String(data: data, encoding: .utf8) {
                print("--- RAW HOT TOPIC JSON RESPONSE ---")
                print(rawJSONString)
                print("---------------------------------")
            }
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                print("HomeViewModel: Received non-200 status code for hot topics: \(statusCode)")
                if statusCode == 404 {
                    hotTopicsErrorMessage = "No hot topics have been set for today."
                } else {
                    hotTopicsErrorMessage = "Server error."
                }
                isLoadingHotTopics = false
                return
            }
            
            let decoder = JSONDecoder()
            let decodedResponse = try decoder.decode(StrapiSingleResponse<HotTopic>.self, from: data)
            
            self.hotTopics = decodedResponse.data.attributes.topics.data
            print("HomeViewModel: Successfully fetched \(self.hotTopics.count) hot topics.")
            
            // --- DEBUGING STEP: Verify the decoded data ---
            for topic in self.hotTopics {
                print("Decoded Topic ID: \(topic.id), Title: '\(topic.title)', Image URL: \(topic.iconImageMedia?.urlString ?? "NIL")")
            }

        } catch {
            hotTopicsErrorMessage = "Failed to fetch hot topics: \(error.localizedDescription)"
            print("HomeViewModel: An error occurred in the hot topics fetch process: \(error)")
            if let decodingError = error as? DecodingError {
               print("HomeViewModel: Hot Topic Decoding error details: \(decodingError)")
           }
        }

        isLoadingHotTopics = false
        print("HomeViewModel: fetchHotTopics finished.")
    }

    func fetchDailyLessons() async {
        // ... this function remains unchanged and will continue to work correctly.
        print("HomeViewModel: Starting fetchDailyLessons...")
        isLoading = true
        errorMessage = nil

        guard let token = keychain["jwt"] else {
            errorMessage = "Authentication token not found."
            isLoading = false
            return
        }
        
        let populateQuery = "populate[dailylessons][populate][courses][populate][icon_image]=true"

        guard let url = URL(string: "\(strapiUrl)/dailylesson?\(populateQuery)") else {
            errorMessage = "Invalid URL."
            isLoading = false
            return
        }

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                errorMessage = "Server error."
                isLoading = false
                return
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let decodedResponse = try decoder.decode(StrapiSingleResponse<DailyLessonPlan>.self, from: data)

            let today = Calendar.current.component(.weekday, from: Date())
            let weekdayString = Calendar.current.weekdaySymbols[today - 1]

            let allLessonPlans = decodedResponse.data.attributes.dailylessons
            
            if let todaysPlan = allLessonPlans.first(where: { $0.day == weekdayString }) {
                self.todaysLessons = todaysPlan.courses.data
            } else {
                self.todaysLessons = []
            }

        } catch {
            errorMessage = "Failed to decode or fetch lessons: \(error.localizedDescription)"
            if let decodingError = error as? DecodingError {
               print("HomeViewModel: Daily Lesson Decoding error details: \(decodingError)")
           }
        }

        isLoading = false
    }
}
