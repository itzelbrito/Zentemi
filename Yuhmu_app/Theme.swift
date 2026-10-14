import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }
}

/// Identidad visual Yuhmu (paleta morada).
enum Brand {
    static let purple     = Color(hex: 0x6B3FC4)
    static let deepPurple = Color(hex: 0x3E1F7A)
    static let magenta    = Color(hex: 0x9B1A6E)   // color de Zentemi
    static let gold       = Color(hex: 0xF2B93B)
    static let green      = Color(hex: 0x4CB782)
    static let red        = Color(hex: 0xE0524D)
    static let cream      = Color(hex: 0xFFFBF5)
    static let softPurple = Color(hex: 0xEFE8FB)
}

struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = Brand.purple
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(color.opacity(configuration.isPressed ? 0.8 : 1))
            .cornerRadius(14)
    }
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(14)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}
extension View { func card() -> some View { modifier(CardStyle()) } }

/// Mascota Yuhmu: agrega la imagen "yuhmu_mascot" a Assets.xcassets.
/// Mientras no exista, muestra un emoji de maíz.
struct MascotView: View {
    var size: CGFloat = 90
    var body: some View {
        Group {
            if UIImage(named: "yuhmu_mascot") != nil {
                Image("yuhmu_mascot").resizable().scaledToFit()
            } else {
                Text("🌽").font(.system(size: size * 0.7))
            }
        }
        .frame(width: size, height: size)
        .background(Brand.softPurple)
        .clipShape(Circle())
        .overlay(Circle().stroke(Brand.purple, lineWidth: 3))
    }
}

struct StatsBar: View {
    @EnvironmentObject var progress: ProgressStore
    var body: some View {
        HStack {
            pill("flame.fill", "\(progress.currentStreak)", Brand.red)
            Spacer()
            pill("star.fill", "\(progress.data.points)", Brand.gold)
            Spacer()
            pill("shield.fill", "Nv. \(progress.level)", Brand.purple)
        }
    }
    private func pill(_ icon: String, _ text: String, _ color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).foregroundColor(color)
            Text(text).font(.system(size: 15, weight: .bold)).foregroundColor(Brand.deepPurple)
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(Color.white).cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 3)
    }
}
