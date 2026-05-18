import SwiftUI

struct HostListView: View {
    @EnvironmentObject var hub: AppHub
    @StateObject private var discovery = DiscoveryService()
    @State private var manualAddress: String = ""
    @State private var pairingTarget: SkhoHost?

    var body: some View {
        ZStack {
            SkhoFlowBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    if !hub.pairedHosts.isEmpty {
                        Text("PAIRED")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(2)
                            .foregroundStyle(SkhoFlowTheme.textTertiary)

                        VStack(spacing: 12) {
                            ForEach(hub.pairedHosts) { host in
                                pairedRow(host)
                            }
                        }
                    }

                    Text("ON THIS NETWORK")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(SkhoFlowTheme.textTertiary)
                        .padding(.top, 6)

                    discoveryPanel

                    Text("ADD MANUALLY")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(SkhoFlowTheme.textTertiary)
                        .padding(.top, 6)

                    manualPanel
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Hosts")
        .sheet(item: $pairingTarget) { host in
            PairingView(host: host) { paired in
                if let paired { hub.pairedHosts.append(paired); hub.savePaired() }
                pairingTarget = nil
            }
        }
        .onAppear { discovery.scan() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Find your PC")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(SkhoFlowTheme.textPrimary)
            Text("Discoverable hosts on this Wi-Fi network show up below.")
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(SkhoFlowTheme.textSecondary)
        }
    }

    private func pairedRow(_ host: SkhoHost) -> some View {
        GlassCard {
            HStack(spacing: 14) {
                Image(systemName: "desktopcomputer")
                    .font(.system(size: 22))
                    .foregroundStyle(SkhoFlowTheme.crimson)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(SkhoFlowTheme.surface)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(host.name)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(SkhoFlowTheme.textPrimary)
                    Text("\(host.ipAddress) · port \(host.port)")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(SkhoFlowTheme.textSecondary)
                }

                Spacer()

                Button {
                    if let idx = hub.pairedHosts.firstIndex(of: host) {
                        hub.pairedHosts.remove(at: idx); hub.savePaired()
                    }
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(SkhoFlowTheme.textTertiary)
                }
            }
        }
    }

    private var discoveryPanel: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    if discovery.isScanning {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(SkhoFlowTheme.crimson)
                        Text("Scanning…")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundStyle(SkhoFlowTheme.textSecondary)
                    } else {
                        Text("Scan complete")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundStyle(SkhoFlowTheme.textSecondary)
                    }
                    Spacer()
                    Button { discovery.scan() } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                            Text("Rescan")
                        }
                    }
                    .buttonStyle(GlassButtonStyle())
                }

                if discovery.foundHosts.isEmpty && !discovery.isScanning {
                    Text("Nothing found yet. Make sure SkhoFlow is running on your PC and both devices share the same Wi-Fi.")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(SkhoFlowTheme.textTertiary)
                } else {
                    ForEach(discovery.foundHosts) { host in
                        Button { pairingTarget = host } label: {
                            HStack {
                                Image(systemName: "desktopcomputer").foregroundStyle(SkhoFlowTheme.crimson)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(host.name)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(SkhoFlowTheme.textPrimary)
                                    Text(host.id.prefix(8))
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundStyle(SkhoFlowTheme.textTertiary)
                                }
                                Spacer()
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(SkhoFlowTheme.crimson)
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }
            }
        }
    }

    private var manualPanel: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Type your PC's IP address (you can see it on the Windows app's Home screen).")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(SkhoFlowTheme.textSecondary)

                HStack {
                    TextField("192.168.1.42", text: $manualAddress)
                        .keyboardType(.numbersAndPunctuation)
                        .autocorrectionDisabled()
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(SkhoFlowTheme.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(SkhoFlowTheme.strokeFaint, lineWidth: 1)
                                )
                        )

                    Button("Connect") { connectManual() }
                        .buttonStyle(GlassButtonStyle())
                        .disabled(manualAddress.isEmpty)
                }
            }
        }
    }

    private func connectManual() {
        let host = SkhoHost(
            id: UUID().uuidString,
            name: manualAddress,
            ipAddress: manualAddress,
            port: 47990,
            deviceId: nil,
            lastSeen: Date()
        )
        pairingTarget = host
    }
}

#Preview {
    NavigationStack { HostListView() }
        .environmentObject(AppHub())
        .preferredColorScheme(.dark)
}
