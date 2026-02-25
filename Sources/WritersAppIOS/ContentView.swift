import SwiftUI

// MARK: - ContentView

struct ContentView: View {
    var body: some View {
        TabView {
            DocumentsView()
                .tabItem {
                    Label("Documents", systemImage: "doc.text")
                }

            TemplatesView()
                .tabItem {
                    Label("Templates", systemImage: "doc.badge.plus")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}
