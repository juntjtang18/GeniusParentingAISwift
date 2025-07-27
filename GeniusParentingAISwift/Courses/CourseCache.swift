// GeniusParentingAISwift/Courses/CourseCache.swift
import Foundation

@MainActor
class CourseCache {
    static let shared = CourseCache()

    // The cache is now a private dictionary, keyed by User ID.
    // [UserID: [CourseID: CourseObject]]
    private var userCourseCache: [Int: [Int: Course]] = [:]

    private init() {
        // Listen for the logout notification to automatically clear the cache.
        NotificationCenter.default.addObserver(self, selector: #selector(clearAllCache), name: .didLogout, object: nil)
    }

    func get(courseId: Int) -> Course? {
        guard let userId = SessionManager.shared.currentUser?.id else { return nil }
        return userCourseCache[userId]?[courseId]
    }

    func set(course: Course) {
        guard let userId = SessionManager.shared.currentUser?.id else { return }
        // Ensure the dictionary for the user exists.
        if userCourseCache[userId] == nil {
            userCourseCache[userId] = [:]
        }
        userCourseCache[userId]?[course.id] = course
    }
    
    @objc private func clearAllCache() {
        userCourseCache.removeAll()
        print("CourseCache cleared due to logout.")
    }
}
