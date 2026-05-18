import Foundation
import Combine

/// Stub iOS streaming client.
///
/// The production version will:
///   1. Open a UDP socket to host:videoPort and join the RTP session
///   2. Feed NALUs into a VideoToolbox VTDecompressionSession
///   3. Hand decoded CVPixelBuffers to a CAMetalLayer for zero-copy display
///   4. Open a WebSocket to controlPort and ship Touch / GameController events
///   5. Open a second UDP socket for Opus audio → AVAudioEngine
///
/// For the scaffold this just publishes synthetic stats so the UI can be exercised.
@MainActor
final class StreamingClient: ObservableObject {
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var fps: Int = 0
    @Published private(set) var latencyMs: Int = 0
    @Published private(set) var bitrateMbps: Double = 0

    private var timer: Timer?

    func start(with descriptor: SessionDescriptor) {
        guard !isRunning else { return }
        isRunning = true

        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.fps = descriptor.stream.fps
                self.latencyMs = Int.random(in: 8...22)
                self.bitrateMbps = Double(descriptor.stream.bitrateKbps) / 1000.0
                    + Double.random(in: -1.0...1.0)
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        fps = 0
        latencyMs = 0
        bitrateMbps = 0
    }
}
