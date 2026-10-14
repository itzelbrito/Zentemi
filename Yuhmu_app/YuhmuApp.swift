import SwiftUI

@main
struct YuhmuApp: App {
    @StateObject private var content = ContentStore()
    @StateObject private var progress = ProgressStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(content)
                .environmentObject(progress)
                .accentColor(Brand.purple)
        }
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            NavigationView { LearningPathView() }
                .navigationViewStyle(StackNavigationViewStyle())
                .tabItem { Label("Inicio", systemImage: "house.fill") }

            NavigationView { GamesView() }
                .navigationViewStyle(StackNavigationViewStyle())
                .tabItem { Label("Juegos", systemImage: "gamecontroller.fill") }

            NavigationView { TrophiesView() }
                .navigationViewStyle(StackNavigationViewStyle())
                .tabItem { Label("Trofeos", systemImage: "trophy.fill") }

            NavigationView { CultureView() }
                .navigationViewStyle(StackNavigationViewStyle())
                .tabItem { Label("Cultura", systemImage: "leaf.fill") }

            NavigationView { ProfileView() }
                .navigationViewStyle(StackNavigationViewStyle())
                .tabItem { Label("Perfil", systemImage: "person.fill") }
        }
    }
}
