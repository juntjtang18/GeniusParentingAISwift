// HomeViewModel.swift

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
    
    @Published var dailyTips: [Tip] = []
    @Published var isLoadingDailyTips: Bool = true
    @Published var dailyTipsErrorMessage: String? = nil

    private let strapiUrl = "\(Config.strapiBaseUrl)/api"
    private let keychain = Keychain(service: Config.keychainService)

    func fetchDailyTips() async {
        let isRefreshEnabled = UserDefaults.standard.bool(forKey: "isRefreshModeEnabled")
        guard isRefreshEnabled || self.dailyTips.isEmpty else {
            print("HomeViewModel: Skipping fetch for daily tips, using cached data.")
            return
        }
        
        print("HomeViewModel: Fetching daily tips...")
        isLoadingDailyTips = true
        dailyTipsErrorMessage = nil

        guard let token = keychain["jwt"] else {
            dailyTipsErrorMessage = "Authentication token not found."
            isLoadingDailyTips = false
            return
        }
        
        let populateQuery = "populate[tips][populate][icon_image]=true"
        guard let url = URL(string: "\(strapiUrl)/daily-tip?\(populateQuery)") else {
            dailyTipsErrorMessage = "Invalid URL."
            isLoadingDailyTips = false; return
        }
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                print("HomeViewModel: Received non-200 status code for daily tips: \(statusCode)")
                dailyTipsErrorMessage = "Server error or no tips configured."
                isLoadingDailyTips = false; return
            }
            
            let decoder = JSONDecoder()
            let decodedResponse = try decoder.decode(StrapiSingleResponse<DailyTip>.self, from: data)
            
            // FIX: Use ?? [] to safely unwrap the now-optional data property.
            self.dailyTips = decodedResponse.data.attributes.tips.data ?? []
        } catch {
            dailyTipsErrorMessage = "Failed to fetch daily tips: \(error.localizedDescription)"
            if let decodingError = error as? DecodingError {
               print("HomeViewModel: Daily Tip Decoding error details: \(decodingError)")
           }
        }
        isLoadingDailyTips = false
    }

    func fetchHotTopics() async {
        let isRefreshEnabled = UserDefaults.standard.bool(forKey: "isRefreshModeEnabled")
        guard isRefreshEnabled || self.hotTopics.isEmpty else {
            print("HomeViewModel: Skipping fetch for hot topics, using cached data.")
            return
        }

        print("HomeViewModel: Fetching hot topics...")
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
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let rawJSONString = String(data: data, encoding: .utf8) {
                print("--- RAW HOT TOPIC JSON RESPONSE ---\n\(rawJSONString)\n---------------------------------")
            }
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                hotTopicsErrorMessage = (statusCode == 404) ? "No hot topics have been set for today." : "Server error."
                isLoadingHotTopics = false
                return
            }
            
            let decoder = JSONDecoder()
            let decodedResponse = try decoder.decode(StrapiSingleResponse<HotTopic>.self, from: data)
            
            // FIX: Use ?? [] to safely unwrap the now-optional data property.
            self.hotTopics = decodedResponse.data.attributes.topics.data ?? []
        } catch {
            hotTopicsErrorMessage = "Failed to fetch hot topics: \(error.localizedDescription)"
            if let decodingError = error as? DecodingError {
               print("HomeViewModel: Hot Topic Decoding error details: \(decodingError)")
           }
        }
        isLoadingHotTopics = false
    }

    func fetchDailyLessons() async {
        let isRefreshEnabled = UserDefaults.standard.bool(forKey: "isRefreshModeEnabled")
        guard isRefreshEnabled || self.todaysLessons.isEmpty else {
            print("HomeViewModel: Skipping fetch for daily lessons, using cached data.")
            return
        }

        print("HomeViewModel: Fetching daily lessons...")
        isLoading = true
        errorMessage = nil

        guard let token = keychain["jwt"] else {
            errorMessage = "Authentication token not found."
            isLoading = false
            return
        }
        
        let populateQuery = "populate[dailylessons][populate][courses][populate][icon_image]=true"
        guard let url = URL(string: "\(strapiUrl)/dailylesson?\(populateQuery)") else {
            errorMessage = "Invalid URL."; isLoading = false; return
        }

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                errorMessage = "Server error."; isLoading = false; return
            }
            
            let decoder = JSONDecoder()
            // REMOVED: decoder.keyDecodingStrategy = .convertFromSnakeCase
            let decodedResponse = try decoder.decode(StrapiSingleResponse<DailyLessonPlan>.self, from: data)

            let today = Calendar.current.component(.weekday, from: Date())
            let weekdayString = Calendar.current.weekdaySymbols[today - 1]

            let allLessonPlans = decodedResponse.data.attributes.dailylessons
            
            if let todaysPlan = allLessonPlans.first(where: { $0.day == weekdayString }) {
                // FIX: Use ?? [] to safely unwrap the now-optional data property.
                self.todaysLessons = todaysPlan.courses.data ?? []
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
