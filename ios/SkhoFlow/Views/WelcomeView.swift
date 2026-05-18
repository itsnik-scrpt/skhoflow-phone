import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var hub: AppHub
    @State private var session: SessionDescriptor?
    @State private var errorText: String?
    @State private var activeHost: SkhoHost?

    var body: some View {
        ZStack {
            SkhoFlowBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    if let host = hub.pairedHosts.first {
                        readyCard(host: host)
                    } else {
                        noHostCard
                    }

                    quickStats

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
        .navigationTitle("SkhoFlow")
        .navigationBarTitleDisplayMode(.large)
        .alert("Couldn't start session", isPresented: .constant(errorText != nil), actions: {
            Button("OK") { errorText = nil }
        }, message: {
            Text(errorText ?? "")
        })
        .fullScreenCover(item: $session) { descriptor in
            if let host = activeHost {
                StreamView(host: host, session: descriptor)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("HOST")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .tracking(2)
                .foregroundStyle(SkhoFlowTheme.textTertiary)
            Text("Stream from PC")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(SkhoFlowTheme.textPrimary)
            Text("Pick a paired host, tap stream, lift off.")
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(SkhoFlowTheme.textSecondary)
        }
    }

    private func readyCard(host: SkhoHost) -> some View {
        HeroGlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(SkhoFlowTheme.crimson)
                        .frame(width: 10, height: 10)
                        .shadow(color: SkhoFlowTheme.hotRed, radius: 8)
                    Text("READY")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(SkhoFlowTheme.hotRed)
                }

                Text(host.name)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(SkhoFlowTheme.textPrimary)
                Text("\(host.ipAddress) · port \(host.port)")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(SkhoFlowTheme.textSecondary)

                Button {
                    startSession(with: host)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("Stream now")
                    }
                }
                .buttonStyle(AccentButtonStyle())
            }
        }
    }

    private var noHostCard: some View {
        HeroGlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Image(systemName: "desktopcomputer.trianglebadge.exclamationmark")
                    .font(.system(size: 36))
                    .foregroundStyle(SkhoFlowTheme.crimson)
                Text("No host paired")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(SkhoFlowTheme.textPrimary)
                Text("Open the Hosts tab to find your PC on the network and pair with a one-time PIN.")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(SkhoFlowTheme.textSecondary)
            }
        }
    }

    private var quickStats: some View {
        HStack(spacing: 12) {
            statCard(icon: "wifi", label: "NETWORK", value: "Wi-Fi")
            statCard(icon: "speedometer", label: "TARGET", value: "\(hub.settings.bitrateMbps) Mbps")
            statCard(icon: "rectangle.dashed", label: "OUTPUT", value: hub.settings.resolution.label)
        }
    }

    private func statCard(icon: String, label: String, value: String) -> some View {
        GlassCard(radius: 18) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: icon).foregroundStyle(SkhoFlowTheme.crimson)
                    Text(label)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1.5)
                        .foregroundStyle(SkhoFlowTheme.textTertiary)
                }
                Text(value)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(SkhoFlowTheme.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func startSession(with host: SkhoHost) {
        activeHost = host
        Task {
            do {
                let descriptor = try await hub.pairing.startSession(host: host)
                await MainActor.run {
                    hub.streaming.start(with: descriptor)
                    session = descriptor
                }
            } catch {
                await MainActor.run { errorText = error.localizedDescription }
            }
        }
    }
}

extension SessionDescriptor: Identifiable {
    var id: String { "\(videoPort)-\(controlPort)" }
}

#Preview {
    NavigationStack { WelcomeView() }
        .environmentObject(AppHub())
        .preferredColorScheme(.dark)
}
