import SwiftUI

enum GameKind { case memorama, challenge }

struct GamesView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                StatsBar()
                gameCard(.memorama, title: "Memorama", subtitle: "Encuentra las parejas Yuhmu – Español",
                         icon: "square.grid.3x2.fill", color: Brand.purple)
                gameCard(.challenge, title: "Retos de vocabulario", subtitle: "Responde, suma combos y gana puntos",
                         icon: "bolt.fill", color: Brand.magenta)
            }
            .padding()
        }
        .background(Brand.cream.ignoresSafeArea())
        .navigationBarTitle("¡Hora de jugar!", displayMode: .inline)
    }

    private func gameCard(_ kind: GameKind, title: String, subtitle: String, icon: String, color: Color) -> some View {
        NavigationLink(destination: GameSetupView(kind: kind)) {
            HStack(spacing: 14) {
                Image(systemName: icon).font(.system(size: 30)).foregroundColor(.white)
                    .frame(width: 64, height: 64).background(color).cornerRadius(16)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.system(size: 19, weight: .heavy)).foregroundColor(Brand.deepPurple)
                    Text(subtitle).font(.footnote).foregroundColor(.gray).multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.gray)
            }
            .card()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Elegir categoría (o "Todas") antes de jugar.
struct GameSetupView: View {
    let kind: GameKind
    @EnvironmentObject var content: ContentStore

    var body: some View {
        List {
            Section(header: Text("Elige un tema")) {
                NavigationLink(destination: destination(nil)) {
                    Label("Todos los temas", systemImage: "sparkles")
                }
                ForEach(content.categories) { c in
                    NavigationLink(destination: destination(c)) {
                        Label(c.title, systemImage: c.icon)
                    }
                }
            }
        }
        .navigationBarTitle(kind == .memorama ? "Memorama" : "Retos", displayMode: .inline)
    }

    @ViewBuilder
    private func destination(_ c: WordCategory?) -> some View {
        let words = c?.words ?? content.allWords
        if kind == .memorama { MemoramaView(words: words) }
        else { VocabularyChallengeView(words: words) }
    }
}

// MARK: - Retos de vocabulario

struct VocabularyChallengeView: View {
    let words: [Word]
    @EnvironmentObject var content: ContentStore
    @EnvironmentObject var progress: ProgressStore
    @Environment(\.presentationMode) var presentation
    @State private var questions: [Question] = []

    var body: some View {
        ChallengeView(title: "Reto de vocabulario", questions: questions,
                      onComplete: { progress.recordChallenge($0) },
                      onClose: { presentation.wrappedValue.dismiss() })
            .onAppear {
                if questions.isEmpty { questions = content.makeQuestions(from: words, count: 10) }
            }
    }
}

// MARK: - Memorama

struct MemoCard: Identifiable {
    let id = UUID()
    let pairId: String
    let wordId: String
    let text: String
    let isYuhmu: Bool
    var isFaceUp = false
    var isMatched = false
}

struct MemoramaView: View {
    @EnvironmentObject var progress: ProgressStore
    @Environment(\.presentationMode) var presentation

    private let pairCount = 6
    @State private var cards: [MemoCard]
    @State private var firstIndex: Int?
    @State private var busy = false
    @State private var moves = 0
    @State private var finished = false
    @State private var earned = 0

    init(words: [Word]) {
        let chosen = Array(words.shuffled().prefix(6))
        var all: [MemoCard] = []
        for w in chosen {
            all.append(MemoCard(pairId: w.id, wordId: w.id, text: w.yuhmu, isYuhmu: true))
            all.append(MemoCard(pairId: w.id, wordId: w.id, text: w.spanish, isYuhmu: false))
        }
        _cards = State(initialValue: all.shuffled())
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    var body: some View {
        ZStack {
            VStack(spacing: 14) {
                HStack {
                    Label("Movimientos: \(moves)", systemImage: "hand.tap.fill")
                        .font(.system(size: 15, weight: .bold)).foregroundColor(Brand.deepPurple)
                    Spacer()
                    Label("\(cards.filter { $0.isMatched }.count / 2)/\(cards.count / 2)", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 15, weight: .bold)).foregroundColor(Brand.green)
                }
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(cards.indices, id: \.self) { i in
                        cardView(cards[i]).onTapGesture { tap(i) }
                    }
                }
                Spacer()
            }
            .padding()

            if finished {
                ResultView(title: "Memorama",
                           result: ChallengeResult(correct: cards.count / 2, total: cards.count / 2, points: earned,
                                                   livesLeft: 3, bestCombo: 0),
                           onClose: { presentation.wrappedValue.dismiss() })
                    .background(Brand.cream.ignoresSafeArea())
            }
        }
        .background(Brand.cream.ignoresSafeArea())
        .navigationBarTitle("Memorama", displayMode: .inline)
    }

    private func cardView(_ c: MemoCard) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(c.isMatched ? Brand.green : (c.isFaceUp ? Color.white : Brand.purple))
                .shadow(color: Color.black.opacity(0.08), radius: 3)
            if c.isFaceUp || c.isMatched {
                Text(c.text)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(c.isMatched ? .white : (c.isYuhmu ? Brand.purple : Brand.deepPurple))
                    .multilineTextAlignment(.center).minimumScaleFactor(0.5).padding(6)
            } else {
                Image(systemName: "star.fill").foregroundColor(Brand.gold).font(.system(size: 24))
            }
        }
        .frame(height: 90)
    }

    private func tap(_ i: Int) {
        guard !busy, !cards[i].isFaceUp, !cards[i].isMatched else { return }
        withAnimation(.easeInOut(duration: 0.2)) { cards[i].isFaceUp = true }
        if cards[i].isYuhmu { AudioPlayer.shared.play(cards[i].wordId) }

        guard let first = firstIndex else { firstIndex = i; return }
        moves += 1
        firstIndex = nil
        busy = true

        if cards[first].pairId == cards[i].pairId {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation { cards[first].isMatched = true; cards[i].isMatched = true }
                busy = false
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                checkFinished()
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                withAnimation { cards[first].isFaceUp = false; cards[i].isFaceUp = false }
                busy = false
            }
        }
    }

    private func checkFinished() {
        guard cards.allSatisfy({ $0.isMatched }) else { return }
        let pairs = cards.count / 2
        earned = pairs * 10 + (moves <= pairs * 2 ? 30 : moves <= pairs * 3 ? 15 : 0)
        progress.recordMemorama(points: earned, won: true)
        finished = true
    }
}
