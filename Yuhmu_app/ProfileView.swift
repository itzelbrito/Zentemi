import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var progress: ProgressStore
    @State private var confirmReset = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                MascotView(size: 110)
                TextField("Tu nombre", text: Binding(
                    get: { progress.data.name },
                    set: { progress.data.name = $0 }))
                    .multilineTextAlignment(.center)
                    .font(.system(size: 24, weight: .heavy)).foregroundColor(Brand.deepPurple)
                Text("Nivel \(progress.level) · \(progress.levelTitle)")
                    .font(.footnote).bold().foregroundColor(.white)
                    .padding(.horizontal, 12).padding(.vertical, 4)
                    .background(Brand.green).cornerRadius(10)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Tus logros").font(.system(size: 18, weight: .heavy)).foregroundColor(Brand.deepPurple)
                    row("Racha actual", "\(progress.currentStreak) días")
                    row("Lecciones completadas", "\(progress.lessonsCompleted)")
                    row("Palabras aprendidas", "\(progress.wordsLearned)")
                    row("Juegos jugados", "\(progress.data.gamesPlayed)")
                }
                .card()

                Button("Reiniciar progreso") { confirmReset = true }
                    .buttonStyle(PrimaryButtonStyle(color: Brand.red))
            }
            .padding()
        }
        .background(Brand.cream.ignoresSafeArea())
        .navigationBarTitle("Perfil", displayMode: .inline)
        .alert(isPresented: $confirmReset) {
            Alert(title: Text("¿Reiniciar progreso?"),
                  message: Text("Se borrarán tus puntos, rachas y logros."),
                  primaryButton: .destructive(Text("Reiniciar")) { progress.reset() },
                  secondaryButton: .cancel(Text("Cancelar")))
        }
    }

    private func row(_ l: String, _ v: String) -> some View {
        HStack { Text(l); Spacer(); Text(v).bold().foregroundColor(Brand.purple) }.font(.system(size: 15))
    }
}
