import Foundation

struct Word: Codable, Identifiable, Hashable {
    let id: String          // ej. "cuerpo_012" -> también es el nombre del audio: cuerpo_012.m4a
    let yuhmu: String
    let spanish: String
    var note: String?

    var categoryId: String { String(id.split(separator: "_").first ?? "") }
}

struct WordCategory: Codable, Identifiable {
    let id: String
    let title: String
    let icon: String        // nombre de SF Symbol
    let words: [Word]
}

struct VocabularyFile: Codable {
    let version: Int
    let categories: [WordCategory]
}

struct Lesson: Identifiable, Hashable {
    let id: String
    let categoryId: String
    let categoryTitle: String
    let number: Int
    let words: [Word]
    var title: String { "\(categoryTitle) \(number)" }
}

struct Question: Identifiable {
    enum Kind { case yuhmuToSpanish, spanishToYuhmu, listen }
    let id = UUID()
    let wordId: String
    let kind: Kind
    let prompt: String
    let options: [String]
    let answer: String
}
