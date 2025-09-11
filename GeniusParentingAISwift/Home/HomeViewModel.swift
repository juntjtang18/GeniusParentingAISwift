// HomeViewModel.swift

import Foundation

@MainActor
class HomeViewModel: ObservableObject {
    private let logger = AppLogger(category: "HomeViewModel")
    
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

    // NEW: pull "my recommendations" and map into existing card model
    @MainActor
    func fetchRecommendedCourses(force: Bool = false) async {
        logger.info("[fetchRecommendedCourses] force=\(force)")
        let isRefreshEnabled = UserDefaults.standard.bool(forKey: "isRefreshModeEnabled")

        if !force {
            if !(isRefreshEnabled || self.todaysLessons.isEmpty) {
                logger.info("[fetchRecommendedCourses] Using cached data (isRefreshEnabled=\(isRefreshEnabled), currentCount=\(self.todaysLessons.count))")
                return
            }
        }

        logger.info("[fetchRecommendedCourses] Fetching…")
        isLoading = true
        errorMessage = nil
        do {
            let resp = try await StrapiService.shared.fetchRecommendedCourses()
            let lessons: [LessonCourse] = (resp.data ?? []).compactMap { cp in
                guard let c = cp.attributes.course?.data else { return nil }
                return LessonCourse(id: c.id, attributes: c.attributes)
            }
            logger.info("[fetchRecommendedCourses] serverItems=\(resp.data?.count ?? -1) mappedLessons=\(lessons.count)")
            self.todaysLessons = lessons
        } catch {
            logger.error("[fetchRecommendedCourses] ERROR: \(error.localizedDescription)")
            self.errorMessage = "Failed to fetch recommended courses: \(error.localizedDescription)"
            self.todaysLessons = []
        }
        isLoading = false
    }

    
    func fetchDailyTips() async {
        let isRefreshEnabled = UserDefaults.standard.bool(forKey: "isRefreshModeEnabled")
        guard isRefreshEnabled || self.dailyTips.isEmpty else {
            print("HomeViewModel: Skipping fetch for daily tips, using cached data.")
            return
        }
        
        print("HomeViewModel: Fetching daily tips...")
        isLoadingDailyTips = true
        dailyTipsErrorMessage = nil
        
        guard let url = URL(string: "\(strapiUrl)/daily-tip?populate[tips][populate][icon_image]=true") else {
            dailyTipsErrorMessage = "Invalid URL."
            isLoadingDailyTips = false
            return
        }
        
        do {
            let dailyTipResponse: DailyTip = try await NetworkManager.shared.fetchSingle(from: url)
            self.dailyTips = dailyTipResponse.attributes.tips.data ?? []
        } catch {
            dailyTipsErrorMessage = "Failed to fetch daily tips: \(error.localizedDescription)"
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
        
        guard let url = URL(string: "\(strapiUrl)/hot-topic?populate[topics][populate][icon_image]=true") else {
            hotTopicsErrorMessage = "Invalid URL."
            isLoadingHotTopics = false
            return
        }
        
        do {
            let hotTopicResponse: HotTopic = try await NetworkManager.shared.fetchSingle(from: url)
            self.hotTopics = hotTopicResponse.attributes.topics.data ?? []
        } catch {
            hotTopicsErrorMessage = "Failed to fetch hot topics: \(error.localizedDescription)"
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

        guard let url = URL(string: "\(strapiUrl)/dailylesson?populate[dailylessons][populate][courses][populate][icon_image]=true") else {
            errorMessage = "Invalid URL."
            isLoading = false
            return
        }

        do {
            let lessonPlan: DailyLessonPlan = try await NetworkManager.shared.fetchSingle(from: url)
            
            let today = Calendar.current.component(.weekday, from: Date())
            let weekdayString = Calendar.current.weekdaySymbols[today - 1]

            if let todaysPlan = lessonPlan.attributes.dailylessons.first(where: { $0.day == weekdayString }) {
                self.todaysLessons = todaysPlan.courses.data ?? []
            } else {
                self.todaysLessons = []
            }
        } catch {
            errorMessage = "Failed to fetch lessons: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
