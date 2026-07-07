import StatusCore
import StatusUI
import SwiftUI

@main
struct StatusiOSApp: App {
    var body: some Scene {
        WindowGroup {
            IOSRootView()
        }
    }
}

private struct IOSRootView: View {
    private let snapshot = MockDashboard.snapshot

    var body: some View {
        TabView {
            NavigationStack {
                DashboardView(snapshot: snapshot)
                    .navigationTitle("Overview")
            }
            .tabItem {
                Label("Overview", systemImage: "rectangle.grid.2x2")
            }

            NavigationStack {
                DashboardView(snapshot: snapshot)
                    .navigationTitle("Alerts")
            }
            .tabItem {
                Label("Alerts", systemImage: "bell")
            }

            NavigationStack {
                DashboardView(snapshot: snapshot)
                    .navigationTitle("Integrations")
            }
            .tabItem {
                Label("Integrations", systemImage: "puzzlepiece.extension")
            }

            NavigationStack {
                Text("Settings")
                    .navigationTitle("Settings")
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
    }
}
