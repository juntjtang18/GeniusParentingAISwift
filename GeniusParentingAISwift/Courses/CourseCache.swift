//
//  CourseCache.swift
//  GeniusParentingAISwift
//
//  Created by James Tang on 2025/7/26.
//


import Foundation

@MainActor
class CourseCache {
    static let shared = CourseCache()
    private init() {}

    func get(courseId: Int) -> Course? {
        guard let userId = SessionManager.shared.currentUser?.id else { return nil }
        let courses: [Int: Course] = SessionStore.shared.getUserData("courseCache", userId: userId) ?? [:]
        return courses[courseId]
    }

    func set(course: Course) {
        guard let userId = SessionManager.shared.currentUser?.id else { return }
        var courses: [Int: Course] = SessionStore.shared.getUserData("courseCache", userId: userId) ?? [:]
        courses[course.id] = course
        SessionStore.shared.setUserData(courses, forKey: "courseCache", userId: userId)
    }
}