import Foundation
import Network

/// Mirrors the Windows host's UDP discovery: broadcast "SKHO?" on :47988
/// and collect "SKHO!" JSON replies from any host on the LAN.
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

        // Broadcast on the typical LAN subnet broadcast. iOS won't actually let us
        // address 255.255.255.255 freely, but it works on the link-local discovery
        // path used by NWConnection with .udp on the broadcast address.
        let endpoint = NWEndpoint.hostPort(host: "255.255.255.255", port: discoveryPort)
        let conn = NWConnection(to: endpoint, using: .udp)

        conn.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            if case .ready = state {
                conn.send(content: payload, completion: .contentProcessed { _ in })
                self.listenForReplies(on: conn)
            }
        }
        conn.start(queue: .global(qos: .userInitiated))
        connections.append(conn)

        DispatchQueue.main.asyncAfter(deadline: .now() + durationSeconds) { [weak self] in
            self?.stop()
        }
    }

    func stop() {
        for c in connections { c.cancel() }
        connections.removeAll()
        isScanning = false
    }

    private func listenForReplies(on conn: NWConnection) {
        conn.receiveMessage { [weak self] data, _, _, error in
            guard let self else { return }
            if let data, let host = Self.parseReply(data) {
                Task { @MainActor in
                    if !self.foundHosts.contains(where: { $0.id == host.id }) {
                        self.foundHosts.append(host)
                    }
                }
            }
            if error == nil {
                self.listenForReplies(on: conn) // keep receiving
            }
        }
    }

    private static func parseReply(_ data: Data) -> SkhoHost? {
        struct Reply: Codable { let type: String; let id: String; let name: String; let port: Int }
        guard let r = try? JSONDecoder().decode(Reply.self, from: data),
              r.type == "SKHO!" else { return nil }
        // The peer IP isn't in the payload; in a real impl we'd capture it from
        // NWConnection.endpoint. For now the user picks the host and we will
        // resolve via Bonjour once mDNS is wired. Use a placeholder.
        return SkhoHost(id: r.id, name: r.name, ipAddress: "0.0.0.0",
                        port: r.port, deviceId: nil, lastSeen: Date())
    }
}
