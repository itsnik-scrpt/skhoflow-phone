import SwiftUI

struct ContentView: View {
    @EnvironmentObject var hub: AppHub
    @State private var selection: Int = 0

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack { HostListView() }
                .tabItem {
                    Label("Hosts", systemImage: "desktopcomputer")
                }
                .tag(0)

            NavigationStack { WelcomeView() }
                .tabItem {
                    Label("Stream", systemImage: "play.rectangle.fill")
                }
                .tag(1)

            NavigationStack { SettingsView() }
                .tabItem {
                    Label("Settings", systemImage: "slider.horizontal.3")
                }
                .tag(2)
        }
        .background(SkhoFlowTheme.background.ignoresSafeArea())
    }
}

#Preview {
    ContentView().environmentObject(AppHub())
}
