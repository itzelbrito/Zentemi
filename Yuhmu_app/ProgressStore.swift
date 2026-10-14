import Combine
import Foundation
import SwiftUI

struct Badge: Identifiable {
    let id: String, title: String, detail: String, icon: String
}

struct UserProgress: Codable {
    var name = "Explorador"
    var points = 0
    var streak = 0
    var bestStreak = 0
    var lastActiveDay: String?
    var completedLessons: [String: Int] = [:]   // lessonId -> estrellas (1...3)
    var learnedWordIds: Set<String> = []
    var badges: Set<String> = []
    var dailyDay: String?
    var dailyCount = 0
    var gamesPlayed = 0
    var memoramaWins = 0
    var perfectChallenges = 0
}

/// Gamificación + persistencia local (100% offline).
/// Para sincronizar con un backend, implementa un ProgressSyncing y llámalo desde save().
final class ProgressStore: ObservableObject {
    @Published var data: UserProgress { didSet { save() } }
    private let key = "yuhmu.progress.v1"

    static let badges: [Badge] = [
        Badge(id: "first_lesson", title: "Primer paso", detail: "Completa tu primera lección", icon: "leaf.fill"),
        Badge(id: "lessons_5", title: "Constante", detail: "Completa 5 lecciones", icon: "books.vertical.fill"),
        Badge(id: "streak_3", title: "Racha de 3", detail: "3 días seguidos", icon: "flame.fill"),
        Badge(id: "streak_7", title: "Racha de 7", detail: "7 días seguidos", icon: "flame.circle.fill"),
        Badge(id: "words_50", title: "50 palabras", detail: "Aprende 50 palabras", icon: "text.book.closed.fill"),
        Badge(id: "words_100", title: "100 palabras", detail: "Aprende 100 palabras", icon: "graduationcap.fill"),
        Badge(id: "points_500", title: "500 puntos", detail: "Suma 500 puntos", icon: "star.circle.fill"),
        Badge(id: "daily_1", title: "Reto diario", detail: "Completa un reto del día", icon: "calendar.badge.checkmark"),
        Badge(id: "memorama_1", title: "Buena memoria", detail: "Gana un Memorama", icon: "brain.head.profile"),
        Badge(id: "perfect_1", title: "¡Perfecto!", detail: "Reto sin errores", icon: "checkmark.seal.fill")
    ]

    init() {
        if let d = UserDefaults.standard.data(forKey: key),
           let p = try? JSONDecoder().decode(UserProgress.self, from: d) {
            data = p
        } else {
            data = UserProgress()
        }
    }

    private func save() {
        if let d = try? JSONEncoder().encode(data) { UserDefaults.standard.set(d, forKey: key) }
    }

    func reset() { data = UserProgress() }

    // MARK: Derivados
    private static let levelStep = 150
    private static let titles = ["Semilla", "Brote", "Milpa", "Maíz tierno", "Mazorca", "Guardián Yuhmu"]

    var level: Int { data.points / Self.levelStep + 1 }
    var levelTitle: String { Self.titles[min(level - 1, Self.titles.count - 1)] }
    var levelProgress: Double { Double(data.points % Self.levelStep) / Double(Self.levelStep) }
    var pointsToNextLevel: Int { Self.levelStep - data.points % Self.levelStep }
    var lessonsCompleted: Int { data.completedLessons.count }
    var wordsLearned: Int { data.learnedWordIds.count }
    var dailyDone: Bool { data.dailyDay == Self.dayString(Date()) }

    /// Racha vigente (se pierde si pasó más de un día sin actividad).
    var currentStreak: Int {
        guard let last = data.lastActiveDay else { return 0 }
        let today = Self.dayString(Date())
        let yesterday = Self.dayString(Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
        return (last == today || last == yesterday) ? data.streak : 0
    }

    static func dayString(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: d)
    }
    static var dayNumber: Int { Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0 }

    // MARK: Acciones
    private func registerActivity() {
        let today = Self.dayString(Date())
        guard data.lastActiveDay != today else { return }
        let yesterday = Self.dayString(Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
        data.streak = (data.lastActiveDay == yesterday) ? data.streak + 1 : 1
        data.bestStreak = max(data.bestStreak, data.streak)
        data.lastActiveDay = today
    }

    func award(_ points: Int) {
        registerActivity()
        data.points += points
        evaluateBadges()
    }

    func completeLesson(_ lesson: Lesson, result: ChallengeResult) {
        award(result.points + (result.stars > 0 ? 20 : 0))
        if result.stars > 0 {
            data.completedLessons[lesson.id] = max(data.completedLessons[lesson.id] ?? 0, result.stars)
            lesson.words.forEach { data.learnedWordIds.insert($0.id) }
        }
        if result.correct == result.total && result.total > 0 { data.perfectChallenges += 1 }
        evaluateBadges()
    }

    func completeDaily(_ result: ChallengeResult) {
        guard !dailyDone else { return }
        award(result.points + 50)
        data.dailyDay = Self.dayString(Date())
        data.dailyCount += 1
        evaluateBadges()
    }

    func recordChallenge(_ result: ChallengeResult) {
        award(result.points)
        data.gamesPlayed += 1
        if result.correct == result.total && result.total > 0 { data.perfectChallenges += 1 }
        evaluateBadges()
    }

    func recordMemorama(points: Int, won: Bool) {
        award(points)
        data.gamesPlayed += 1
        if won { data.memoramaWins += 1 }
        evaluateBadges()
    }

    private func evaluateBadges() {
        var b = data.badges
        if lessonsCompleted >= 1 { b.insert("first_lesson") }
        if lessonsCompleted >= 5 { b.insert("lessons_5") }
        if data.bestStreak >= 3 { b.insert("streak_3") }
        if data.bestStreak >= 7 { b.insert("streak_7") }
        if wordsLearned >= 50 { b.insert("words_50") }
        if wordsLearned >= 100 { b.insert("words_100") }
        if data.points >= 500 { b.insert("points_500") }
        if data.dailyCount >= 1 { b.insert("daily_1") }
        if data.memoramaWins >= 1 { b.insert("memorama_1") }
        if data.perfectChallenges >= 1 { b.insert("perfect_1") }
        if b != data.badges { data.badges = b }
    }
}
