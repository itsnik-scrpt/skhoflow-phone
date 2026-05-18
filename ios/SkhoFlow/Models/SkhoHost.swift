import Foundation

struct SkhoHost: Codable, Identifiable, Hashable {
    let id: String          // host UUID from /info
    var name: String
    var ipAddress: String
    var port: Int
    var deviceId: String?   // assigned after a successful /pair
    var lastSeen: Date

    var baseURL: URL? {
        URL(string: "http://\(ipAddress):\(port)")
    }
}
