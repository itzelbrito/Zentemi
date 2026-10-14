import SwiftUI

struct LearningPathView: View {
    @EnvironmentObject var content: ContentStore
    @EnvironmentObject var progress: ProgressStore

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                StatsBar()
                DailyChallengeCard()
                ForEach(content.categories) { category in
                    CategorySection(category: category)
                }
            }
            .padding()
        }
        .background(Brand.cream.ignoresSafeArea())
        .navigationBarTitle("Yuhmu Kids", displayMode: .inline)
    }
}

struct CategorySection: View {
    let category: WordCategory
    @EnvironmentObject var content: ContentStore
    @EnvironmentObject var progress: ProgressStore

    private func isUnlocked(_ lesson: Lesson) -> Bool {
        guard let i = content.lessons.firstIndex(of: lesson), i > 0 else { return true }
        return progress.data.completedLessons[content.lessons[i - 1].id] != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: category.icon).foregroundColor(Brand.purple)
                Text(category.title)
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundColor(Brand.deepPurple)
                Spacer()
                Text("\(category.words.count) palabras").font(.caption).foregroundColor(.gray)
            }
            ForEach(content.lessons(in: category)) { lesson in
                if isUnlocked(lesson) {
                    NavigationLink(destination: LessonView(lesson: lesson)) {
                        LessonRow(lesson: lesson, unlocked: true,
                                  stars: progress.data.completedLessons[lesson.id] ?? 0)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    LessonRow(lesson: lesson, unlocked: false, stars: 0)
                }
            }
        }
    }
}

struct LessonRow: View {
    let lesson: Lesson
    let unlocked: Bool
    let stars: Int

    private var iconName: String { !unlocked ? "lock.fill" : (stars > 0 ? "checkmark" : "play.fill") }
    private var iconColor: Color { !unlocked ? Color.gray : (stars > 0 ? Brand.green : Brand.purple) }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(iconColor)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text("Lección \(lesson.number)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Brand.deepPurple)
                Text("\(lesson.words.count) palabras").font(.caption).foregroundColor(.gray)
            }
            Spacer()
            HStack(spacing: 2) {
                ForEach(1...3, id: \.self) { i in
                    Image(systemName: i <= stars ? "star.fill" : "star")
                        .foregroundColor(Brand.gold).font(.system(size: 14))
                }
            }
        }
        .card()
        .opacity(unlocked ? 1 : 0.55)
    }
}

struct DailyChallengeCard: View {
    @EnvironmentObject var progress: ProgressStore
    var body: some View {
        Group {
            if progress.dailyDone {
                card(done: true)
            } else {
                NavigationLink(destination: DailyChallengeView()) { card(done: false) }
                    .buttonStyle(PlainButtonStyle())
            }
        }
    }
    private func card(done: Bool) -> some View {
        HStack {
            Image(systemName: done ? "checkmark.seal.fill" : "calendar")
                .font(.system(size: 28)).foregroundColor(.white)
            VStack(alignment: .leading) {
                Text("Reto del día").font(.system(size: 18, weight: .heavy)).foregroundColor(.white)
                Text(done ? "¡Completado! Vuelve mañana" : "5 palabras · +50 puntos extra")
                    .font(.caption).foregroundColor(.white.opacity(0.9))
            }
            Spacer()
            if !done { Image(systemName: "chevron.right").foregroundColor(.white) }
        }
        .padding()
        .background(done ? Brand.green : Brand.magenta)
        .cornerRadius(16)
    }
}

struct DailyChallengeView: View {
    @EnvironmentObject var content: ContentStore
    @EnvironmentObject var progress: ProgressStore
    @Environment(\.presentationMode) var presentation
    @State private var questions: [Question] = []

    var body: some View {
        ChallengeView(title: "Reto del día", questions: questions,
                      onComplete: { progress.completeDaily($0) },
                      onClose: { presentation.wrappedValue.dismiss() })
            .onAppear {
                if questions.isEmpty {
                    questions = content.dailyQuestions(day: ProgressStore.dayNumber)
                }
            }
    }
}

// MARK: - Lección: estudio (tarjetas con audio) + quiz

struct LessonView: View {
    let lesson: Lesson
    @EnvironmentObject var content: ContentStore
    @EnvironmentObject var progress: ProgressStore
    @Environment(\.presentationMode) var presentation

    @State private var index = 0
    @State private var questions: [Question] = []
    @State private var quizStarted = false
    @State private var audioMissing = false

    var body: some View {
        Group {
            if quizStarted {
                ChallengeView(title: lesson.title, questions: questions,
                              onComplete: { progress.completeLesson(lesson, result: $0) },
                              onClose: { presentation.wrappedValue.dismiss() })
            } else {
                study
            }
        }
    }

    private var word: Word { lesson.words[index] }

    private var study: some View {
        VStack(spacing: 20) {
            ProgressView(value: Double(index + 1), total: Double(lesson.words.count))
                .accentColor(Brand.purple)
            Spacer()
            VStack(spacing: 14) {
                Text(word.yuhmu).font(.system(size: 40, weight: .heavy))
                    .foregroundColor(Brand.purple).multilineTextAlignment(.center)
                    .minimumScaleFactor(0.5)
                Text(word.spanish).font(.system(size: 24, weight: .semibold))
                    .foregroundColor(Brand.deepPurple).multilineTextAlignment(.center)
                if let n = word.note, !n.isEmpty {
                    Text(n).font(.footnote).foregroundColor(.gray).multilineTextAlignment(.center)
                }
                Button(action: { audioMissing = !AudioPlayer.shared.play(word.id) }) {
                    Image(systemName: "speaker.wave.3.fill").font(.system(size: 30)).foregroundColor(.white)
                        .frame(width: 70, height: 70).background(Brand.gold).clipShape(Circle())
                }
                if audioMissing {
                    Text("Audio pendiente de grabación").font(.caption).foregroundColor(.gray)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 280).card()
            Spacer()
            HStack(spacing: 12) {
                if index > 0 {
                    Button("Atrás") { index -= 1; audioMissing = false }
                        .buttonStyle(PrimaryButtonStyle(color: .gray))
                }
                Button(index == lesson.words.count - 1 ? "Practicar" : "Siguiente") {
                    if index == lesson.words.count - 1 {
                        questions = content.makeQuestions(from: lesson.words, count: min(8, lesson.words.count))
                        quizStarted = true
                    } else {
                        index += 1; audioMissing = false
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding()
        .background(Brand.cream.ignoresSafeArea())
        .navigationBarTitle(lesson.title, displayMode: .inline)
    }
}
