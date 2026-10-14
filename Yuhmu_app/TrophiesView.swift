import SwiftUI

/// Panel visual de progreso: nivel, puntos, racha, avance y logros.
struct TrophiesView: View {
    @EnvironmentObject var content: ContentStore
    @EnvironmentObject var progress: ProgressStore

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text("Nivel \(progress.level) · \(progress.levelTitle)")
                        .font(.system(size: 22, weight: .heavy)).foregroundColor(Brand.deepPurple)
                    ProgressView(value: progress.levelProgress).accentColor(Brand.gold)
                    Text("\(progress.pointsToNextLevel) puntos para el siguiente nivel")
                        .font(.caption).foregroundColor(.gray)
                }
                .card()

                HStack(spacing: 12) {
                    stat("flame.fill", "\(progress.currentStreak)", "Racha", Brand.red)
                    stat("star.fill", "\(progress.data.points)", "Puntos", Brand.gold)
                    stat("trophy.fill", "\(progress.data.bestStreak)", "Mejor racha", Brand.purple)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Tu avance").font(.system(size: 18, weight: .heavy)).foregroundColor(Brand.deepPurple)
                    bar("Palabras aprendidas", progress.wordsLearned, content.allWords.count, Brand.purple)
                    bar("Lecciones completadas", progress.lessonsCompleted, content.lessons.count, Brand.green)
                }
                .card()

                DailyChallengeCard()

                VStack(alignment: .leading, spacing: 10) {
                    Text("Logros").font(.system(size: 18, weight: .heavy)).foregroundColor(Brand.deepPurple)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                        ForEach(ProgressStore.badges) { b in
                            let got = progress.data.badges.contains(b.id)
                            VStack(spacing: 6) {
                                Image(systemName: b.icon).font(.system(size: 26))
                                    .foregroundColor(got ? Brand.gold : .gray.opacity(0.5))
                                Text(b.title).font(.system(size: 12, weight: .bold))
                                    .foregroundColor(got ? Brand.deepPurple : .gray)
                                Text(b.detail).font(.system(size: 10)).foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, minHeight: 100)
                            .padding(6).background(got ? Brand.softPurple : Color.gray.opacity(0.08))
                            .cornerRadius(12)
                        }
                    }
                }
                .card()
            }
            .padding()
        }
        .background(Brand.cream.ignoresSafeArea())
        .navigationBarTitle("Trofeos", displayMode: .inline)
    }

    private func stat(_ icon: String, _ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).foregroundColor(color)
            Text(value).font(.system(size: 20, weight: .heavy)).foregroundColor(Brand.deepPurple)
            Text(label).font(.caption).foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity).card()
    }

    private func bar(_ label: String, _ value: Int, _ total: Int, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack { Text(label).font(.footnote); Spacer(); Text("\(value)/\(total)").font(.footnote).bold() }
            ProgressView(value: Double(value), total: Double(max(total, 1))).accentColor(color)
        }
    }
}
