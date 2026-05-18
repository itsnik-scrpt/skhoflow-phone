import Foundation

struct StreamSettings: Codable, Equatable {
    var resolution: Resolution = .r1080p
    var fps: Int = 60
    var bitrateMbps: Int = 20
    var preferHEVC: Bool = false
    var lowLatencyMode: Bool = true
    var touchAsMouse: Bool = true
    var showStatsOverlay: Bool = false

    enum Resolution: String, Codable, CaseIterable, Identifiable {
        case r720p, r1080p, r1440p
        var id: String { rawValue }
        var label: String {
            switch self {
            case .r720p:  return "720p"
            case .r1080p: return "1080p"
            case .r1440p: return "1440p"
            }
        }
    }
}
