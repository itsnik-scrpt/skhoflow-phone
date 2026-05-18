import Foundation
import Network

/// Mirrors the Windows host's UDP discovery: broadcast "SKHO?" on :47988
/// and collect "SKHO!" JSON replies from any host on the LAN.
///
/// The class is `@MainActor` so `@Published` properties flow safely into SwiftUI,
/// but NWConnection callbacks fire on background queues - the receive/parse
/// helpers are therefore `nonisolated` and hop back to the main actor via
/// `Task { @MainActor in ... }` when they need to mutate published state.
@MainActor
final class DiscoveryService: ObservableObject {
    @Published private(set) var foundHosts: [SkhoHost] = []
    @Published private(set) var isScanning: Bool = false

    private var connections: [NWConnection] = []
    private let discoveryPort: NWEndpoint.Port = 47988

    func scan(durationSeconds: TimeInterval = 3.0) {
        guard !isScanning else { return }
        isScanning = true
        foundHosts = []

        let payload = "SKHO?".data(using: .utf8)!
        let endpoint = NWEndpoint.hostPort(host: "255.255.255.255", port: discoveryPort)
        let conn = NWConnection(to: endpoint, using: .udp)

        conn.stateUpdateHandler = { state in
            if case .ready = state {
                conn.send(content: payload, completion: .contentProcessed { _ in })
                Self.listenForReplies(on: conn) { host in
                    Task { @MainActor in
                        if !self.foundHosts.contains(where: { $0.id == host.id }) {
                            self.foundHosts.append(host)
                        }
                    }
                }
            }
        }
        conn.start(queue: .global(qos: .userInitiated))
        connections.append(conn)

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(durationSeconds * 1_000_000_000))
            self.stop()
        }
    }

    func stop() {
        for c in connections { c.cancel() }
        connections.removeAll()
        isScanning = false
    }

    // MARK: - Background helpers (run off the main actor)

    nonisolated private static func listenForReplies(
        on conn: NWConnection,
        onHost: @Sendable @escaping (SkhoHost) -> Void
    ) {
        conn.receiveMessage { data, _, _, error in
            if let data, let host = Self.parseReply(data) {
                onHost(host)
            }
            if error == nil {
                Self.listenForReplies(on: conn, onHost: onHost)
            }
        }
    }

    nonisolated private static func parseReply(_ data: Data) -> SkhoHost? {
        struct Reply: Codable { let type: String; let id: String; let name: String; let port: Int }
        guard let r = try? JSONDecoder().decode(Reply.self, from: data),
              r.type == "SKHO!" else { return nil }
        // The peer IP isn't in the payload; in production we'd capture it from
        // NWConnection.endpoint. For now the user picks the host and we resolve
        // via Bonjour once mDNS is wired. Use a placeholder.
        return SkhoHost(id: r.id, name: r.name, ipAddress: "0.0.0.0",
                        port: r.port, deviceId: nil, lastSeen: Date())
    }
}
