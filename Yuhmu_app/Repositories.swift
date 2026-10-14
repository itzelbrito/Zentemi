import Combine
import Foundation
import AVFoundation

// MARK: - Capa de contenido (escalable)
// Para agregar módulos nuevos basta con añadir categorías al JSON o
// implementar otro ContentRepository (por ejemplo, uno remoto con caché local).

protocol ContentRepository {
    func loadCategories() -> [WordCategory]
}

final class LocalContentRepository: ContentRepository {
    func loadCategories() -> [WordCategory] {
        guard let url = Bundle.main.url(forResource: "vocabulary", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(VocabularyFile.self, from: data) else {
            assertionFailure("No se pudo cargar vocabulary.json")
            return []
        }
        return file.categories
    }
}

// MARK: - Contenido, lecciones y preguntas

final class ContentStore: ObservableObject {
    @Published private(set) var categories: [WordCategory] = []
    @Published private(set) var lessons: [Lesson] = []

    let wordsPerLesson = 8
    private let repository: ContentRepository

    init(repository: ContentRepository = LocalContentRepository()) {
        self.repository = repository
        reload()
    }

    func reload() {
        categories = repository.loadCategories()
        lessons = buildLessons()
    }

    var allWords: [Word] { categories.flatMap { $0.words } }

    func lessons(in category: WordCategory) -> [Lesson] {
        lessons.filter { $0.categoryId == category.id }
    }

    private func buildLessons() -> [Lesson] {
        var out: [Lesson] = []
        for c in categories {
            var chunks: [[Word]] = stride(from: 0, to: c.words.count, by: wordsPerLesson).map {
                Array(c.words[$0..<min($0 + wordsPerLesson, c.words.count)])
            }
            // Evita una última lección demasiado corta
            if chunks.count > 1, let last = chunks.last, last.count < 4 {
                chunks.removeLast()
                chunks[chunks.count - 1].append(contentsOf: last)
            }
            for (i, ws) in chunks.enumerated() {
                out.append(Lesson(id: "\(c.id)_L\(i + 1)", categoryId: c.id,
                                  categoryTitle: c.title, number: i + 1, words: ws))
            }
        }
        return out
    }

    // MARK: Preguntas (Retos de Vocabulario)

    func makeQuestions(from words: [Word], count: Int) -> [Question] {
        let chosen = Array(words.shuffled().prefix(count))
        return chosen.enumerated().map { (i, w) in
            var kind: Question.Kind = .yuhmuToSpanish
            if i % 3 == 1 { kind = .spanishToYuhmu }
            if i % 3 == 2 { kind = AudioPlayer.shared.hasAudio(w.id) ? .listen : .yuhmuToSpanish }
            return question(for: w, kind: kind, pool: words)
        }
    }

    func dailyQuestions(day: Int, count: Int = 5) -> [Question] {
        let all = allWords
        guard !all.isEmpty else { return [] }
        var picked: [Word] = []
        var idx = (day * 31) % all.count
        while picked.count < min(count, all.count) {
            if !picked.contains(all[idx]) { picked.append(all[idx]) }
            idx = (idx + 17) % all.count
        }
        return makeQuestions(from: picked, count: count)
    }

    private func question(for w: Word, kind: Question.Kind, pool: [Word]) -> Question {
        let pick: (Word) -> String = { kind == .spanishToYuhmu ? $0.yuhmu : $0.spanish }
        let answer = pick(w)
        var options = [answer]
        let candidates = (pool + allWords.filter { $0.categoryId == w.categoryId } + allWords.shuffled())
        for c in candidates where options.count < 4 {
            let t = pick(c)
            if !options.contains(t) { options.append(t) }
        }
        let prompt: String
        switch kind {
        case .yuhmuToSpanish: prompt = w.yuhmu
        case .spanishToYuhmu: prompt = w.spanish
        case .listen:         prompt = "Escucha y elige el significado"
        }
        return Question(wordId: w.id, kind: kind, prompt: prompt,
                        options: options.shuffled(), answer: answer)
    }
}

// MARK: - Audio offline
// Coloca los .m4a grabados por hablantes nativos en la carpeta "Audio" (folder reference).
// Nombre del archivo = id de la palabra (ver audio_checklist.csv).

final class AudioPlayer {
    static let shared = AudioPlayer()
    private var player: AVAudioPlayer?

    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    private func url(for id: String) -> URL? {
        Bundle.main.url(forResource: id, withExtension: "m4a", subdirectory: "Audio")
            ?? Bundle.main.url(forResource: id, withExtension: "m4a")
    }

    func hasAudio(_ id: String) -> Bool { url(for: id) != nil }

    @discardableResult
    func play(_ id: String) -> Bool {
        guard let u = url(for: id) else { return false }
        player = try? AVAudioPlayer(contentsOf: u)
        player?.play()
        return player != nil
    }
}
