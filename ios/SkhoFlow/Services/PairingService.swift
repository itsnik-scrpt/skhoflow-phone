import Foundation

@MainActor
final class PairingService: ObservableObject {
    enum PairError: LocalizedError {
        case badURL, badResponse, wrongPin, noPinPending, network(Error)

        var errorDescription: String? {
            switch self {
            case .badURL: return "Couldn't reach the host."
            case .badResponse: return "Host returned an unexpected response."
            case .wrongPin: return "That PIN didn't match. Try again."
            case .noPinPending: return "The host isn't expecting a pairing right now. Tap 'Pair device' on the PC."
            case .network(let e): return e.localizedDescription
            }
        }
    }

    func info(for host: SkhoHost) async throws -> HostInfo {
        guard let url = host.baseURL?.appendingPathComponent("info") else { throw PairError.badURL }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(HostInfo.self, from: data)
    }

    func pair(with host: SkhoHost, pin: String, deviceName: String, model: String) async throws -> String {
        guard let url = host.baseURL?.appendingPathComponent("pair") else { throw PairError.badURL }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode([
            "name": deviceName,
            "model": model,
            "publicKey": "",   // TODO: generate ECDSA P-256 keypair and send pubKey
            "pin": pin,
        ])

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw PairError.badResponse }

        if http.statusCode == 200 {
            struct OK: Codable { let deviceId: String }
            return try JSONDecoder().decode(OK.self, from: data).deviceId
        } else if http.statusCode == 403 {
            struct Err: Codable { let error: String }
            let e = (try? JSONDecoder().decode(Err.self, from: data))?.error
            throw e == "no_pin_pending" ? PairError.noPinPending : PairError.wrongPin
        } else {
            throw PairError.badResponse
        }
    }

    func startSession(host: SkhoHost) async throws -> SessionDescriptor {
        guard let url = host.baseURL?.appendingPathComponent("session/start"),
              let deviceId = host.deviceId else { throw PairError.badURL }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(["deviceId": deviceId])

        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(SessionDescriptor.self, from: data)
    }
}

struct HostInfo: Codable {
    let id: String
    let name: String
    let version: Int
    let requirePin: Bool
    let protocolName: String?

    enum CodingKeys: String, CodingKey {
        case id, name, version, requirePin
        case protocolName = "protocol"
    }
}

struct SessionDescriptor: Codable {
    struct Stream: Codable {
        let width: Int
        let height: Int
        let fps: Int
        let bitrateKbps: Int
        let codec: String
        let audioBitrateKbps: Int
    }
    let videoPort: Int
    let controlPort: Int
    let stream: Stream
}
