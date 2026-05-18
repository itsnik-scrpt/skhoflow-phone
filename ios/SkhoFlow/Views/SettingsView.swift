import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var hub: AppHub

    var body: some View {
        ZStack {
            SkhoFlowBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    GlassCard {
                        VStack(alignment: .leading, spacing: 16) {
                            settingRow(label: "Resolution", icon: "rectangle.dashed") {
                                Picker("", selection: $hub.settings.resolution) {
                                    ForEach(StreamSettings.Resolution.allCases) { r in
                                        Text(r.label).tag(r)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(SkhoFlowTheme.crimson)
                            }

                            divider

                            settingRow(label: "Frame rate", icon: "gauge.with.dots.needle.67percent") {
                                Picker("", selection: $hub.settings.fps) {
                                    ForEach([30, 60, 90, 120], id: \.self) { v in
                                        Text("\(v) fps").tag(v)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(SkhoFlowTheme.crimson)
                            }

                            divider

                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "speedometer").foregroundStyle(SkhoFlowTheme.crimson)
                                    Text("Target bitrate")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundStyle(SkhoFlowTheme.textPrimary)
                                    Spacer()
                                    Text("\(hub.settings.bitrateMbps) Mbps")
                                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(SkhoFlowTheme.crimson)
                                }
                                Slider(value: Binding(
                                    get: { Double(hub.settings.bitrateMbps) },
                                    set: { hub.settings.bitrateMbps = Int($0) }
                                ), in: 3...60, step: 1)
                                .tint(SkhoFlowTheme.crimson)
                            }
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            toggleRow(label: "Prefer HEVC", icon: "film.fill",
                                      isOn: $hub.settings.preferHEVC,
                                      hint: "Smoother quality at the same bitrate where supported.")
                            divider
                            toggleRow(label: "Low-latency mode", icon: "bolt.fill",
                                      isOn: $hub.settings.lowLatencyMode,
                                      hint: "Smaller buffers — better feel, slightly less smooth.")
                            divider
                            toggleRow(label: "Touch as mouse", icon: "hand.point.up.left.fill",
                                      isOn: $hub.settings.touchAsMouse,
                                      hint: "Treat single touches as a virtual mouse pointer.")
                            divider
                            toggleRow(label: "Show stats overlay", icon: "chart.bar.fill",
                                      isOn: $hub.settings.showStatsOverlay,
                                      hint: "fps, ms and Mbps pinned in the corner during streaming.")
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "info.circle.fill").foregroundStyle(SkhoFlowTheme.crimson)
                                Text("About")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundStyle(SkhoFlowTheme.textPrimary)
                            }
                            Text("SkhoFlow 2.0 · iOS client")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(SkhoFlowTheme.textSecondary)
                            Text("Made with native SwiftUI, VideoToolbox and Metal.")
                                .font(.system(size: 12, design: .rounded))
                                .foregroundStyle(SkhoFlowTheme.textTertiary)
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(20)
            }
        }
        .navigationTitle("Settings")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Stream settings")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(SkhoFlowTheme.textPrimary)
            Text("Tune the negotiation your iPhone asks for. The host picks the closest match it can encode.")
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(SkhoFlowTheme.textSecondary)
        }
    }

    private func settingRow<Content: View>(
        label: String, icon: String,
        @ViewBuilder trailing: () -> Content
    ) -> some View {
        HStack {
            Image(systemName: icon).foregroundStyle(SkhoFlowTheme.crimson)
            Text(label)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(SkhoFlowTheme.textPrimary)
            Spacer()
            trailing()
        }
    }

    private func toggleRow(label: String, icon: String, isOn: Binding<Bool>, hint: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon).foregroundStyle(SkhoFlowTheme.crimson)
                Text(label)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(SkhoFlowTheme.textPrimary)
                Spacer()
                Toggle("", isOn: isOn)
                    .labelsHidden()
                    .tint(SkhoFlowTheme.crimson)
            }
            Text(hint)
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(SkhoFlowTheme.textTertiary)
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(SkhoFlowTheme.strokeFaint)
            .frame(height: 1)
    }
}
