import SwiftUI

@main
struct SkhoFlowApp: App {
    @StateObject private var hub = AppHub()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(hub)
                .preferredColorScheme(.dark)
                .tint(SkhoFlowTheme.crimson)
        }
    }
}

/// Composition root — one place to grab the shared services from any view.
@MainActor
final class AppHub: ObservableObject {
    let discovery = DiscoveryService()
    let pairing = PairingService()
    let streaming = StreamingClient()
    @Published var settings = StreamSettings()
    @Published var pairedHosts: [SkhoHost] = []

    init() {
        load()
    }

    private func load() {
        guard let url = Self.storeURL(), let data = try? Data(contentsOf: url) else { return }
        if let hosts = try? JSONDecoder().decode([SkhoHost].self, from: data) {
            pairedHosts = hosts
        }
    }

    func savePaired() {
        guard let url = Self.storeURL(),
              let data = try? JSONEncoder().encode(pairedHosts) else { return }
        try? data.write(to: url, options: .atomic)
    }

    private static func storeURL() -> URL? {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("skhoflow-hosts.json")
    }
}
