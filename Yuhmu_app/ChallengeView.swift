import SwiftUI

struct ChallengeResult {
    var correct: Int
    var total: Int
    var points: Int
    var livesLeft: Int
    var bestCombo: Int
    var ratio: Double { total == 0 ? 0 : Double(correct) / Double(total) }
    var stars: Int { ratio >= 0.9 ? 3 : ratio >= 0.7 ? 2 : ratio >= 0.5 ? 1 : 0 }
}

/// Motor de preguntas reutilizado por: quiz de lecciones, Retos de Vocabulario y Reto del día.
struct ChallengeView: View {
    let title: String
    let questions: [Question]
    var maxLives = 3
    let onComplete: (ChallengeResult) -> Void
    let onClose: () -> Void

    @State private var current = 0
    @State private var lives = 3
    @State private var correct = 0
    @State private var combo = 0
    @State private var bestCombo = 0
    @State private var points = 0
    @State private var selected: String?
    @State private var result: ChallengeResult?

    var body: some View {
        Group {
            if let r = result {
                ResultView(title: title, result: r, onClose: onClose)
            } else if questions.isEmpty {
                Text("No hay preguntas disponibles.").padding()
            } else {
                questionView
            }
        }
        .background(Brand.cream.ignoresSafeArea())
        .navigationBarTitle(title, displayMode: .inline)
        .onAppear { lives = maxLives }
    }

    private var question: Question { questions[current] }

    private var questionView: some View {
        VStack(spacing: 18) {
            HStack {
                ProgressView(value: Double(current), total: Double(questions.count))
                    .accentColor(Brand.purple)
                HStack(spacing: 3) {
                    ForEach(0..<maxLives, id: \.self) { i in
                        Image(systemName: i < lives ? "heart.fill" : "heart")
                            .foregroundColor(Brand.red)
                    }
                }
            }

            VStack(spacing: 10) {
                if question.kind == .listen {
                    Button(action: { AudioPlayer.shared.play(question.wordId) }) {
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 44)).foregroundColor(.white)
                            .frame(width: 100, height: 100)
                            .background(Brand.gold).clipShape(Circle())
                    }
                    Text(question.prompt).font(.system(size: 18, weight: .bold))
                        .foregroundColor(Brand.deepPurple)
                } else {
                    Text(question.kind == .yuhmuToSpanish ? "¿Qué significa?" : "¿Cómo se dice en Yuhmu?")
                        .font(.system(size: 15)).foregroundColor(.gray)
                    Text(question.prompt)
                        .font(.system(size: 32, weight: .heavy)).foregroundColor(Brand.deepPurple)
                        .multilineTextAlignment(.center).minimumScaleFactor(0.6)
                    if question.kind == .yuhmuToSpanish && AudioPlayer.shared.hasAudio(question.wordId) {
                        Button(action: { AudioPlayer.shared.play(question.wordId) }) {
                            Label("Escuchar", systemImage: "speaker.wave.2.fill")
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 150)
            .card()

            ForEach(question.options, id: \.self) { opt in
                Button(action: { choose(opt) }) {
                    Text(opt)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(color(for: opt)).cornerRadius(14)
                }
                .disabled(selected != nil)
            }

            Spacer()

            if selected != nil {
                Button(action: next) {
                    Text(isLast ? "Terminar" : "Continuar")
                }
                .buttonStyle(PrimaryButtonStyle(color: Brand.green))
            }
        }
        .padding()
        .id(current)
        .onAppear { if question.kind == .listen { AudioPlayer.shared.play(question.wordId) } }
    }

    private var isLast: Bool { current + 1 >= questions.count || lives == 0 }

    private func color(for opt: String) -> Color {
        guard let s = selected else { return Brand.purple }
        if opt == question.answer { return Brand.green }
        if opt == s { return Brand.red }
        return Color.gray.opacity(0.5)
    }

    private func choose(_ opt: String) {
        guard selected == nil else { return }
        selected = opt
        if opt == question.answer {
            correct += 1; combo += 1; bestCombo = max(bestCombo, combo)
            points += 10 + min(combo - 1, 5) * 2
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            lives -= 1; combo = 0
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }

    private func next() {
        if isLast {
            let r = ChallengeResult(correct: correct, total: questions.count, points: points,
                                    livesLeft: lives, bestCombo: bestCombo)
            result = r
            onComplete(r)
        } else {
            current += 1
            selected = nil
        }
    }
}

struct ResultView: View {
    let title: String
    let result: ChallengeResult
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            MascotView(size: 110)
            Text(result.stars > 0 ? "¡Muy bien!" : "¡Sigue practicando!")
                .font(.system(size: 30, weight: .heavy)).foregroundColor(Brand.purple)
            HStack {
                ForEach(1...3, id: \.self) { i in
                    Image(systemName: i <= result.stars ? "star.fill" : "star")
                        .font(.system(size: 36)).foregroundColor(Brand.gold)
                }
            }
            Text("\(result.correct) de \(result.total) correctas")
                .font(.system(size: 18)).foregroundColor(.gray)
            Label("+\(result.points) puntos", systemImage: "star.circle.fill")
                .font(.system(size: 20, weight: .bold)).foregroundColor(Brand.deepPurple)
                .padding().background(Brand.softPurple).cornerRadius(14)
            Spacer()
            Button("Continuar", action: onClose).buttonStyle(PrimaryButtonStyle(color: Brand.green))
        }
        .padding()
    }
}
