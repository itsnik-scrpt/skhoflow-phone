import SwiftUI
import UIKit

struct StreamView: View {
    @EnvironmentObject var hub: AppHub
    @Environment(\.dismiss) var dismiss

    let host: SkhoHost
    let session: SessionDescriptor

    @State private var showOverlay: Bool = true
    @State private var overlayWorkItem: DispatchWorkItem?

    var body: some View {
        ZStack {
            // Stream surface — once VideoToolbox is wired, swap this for a CAMetalLayer host.
            Color.black.ignoresSafeArea()

            // Placeholder "no signal" art
            VStack(spacing: 18) {
                Image(systemName: "wave.3.right.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(SkhoFlowTheme.crimson)
                Text("Streaming \(host.name)")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(SkhoFlowTheme.textPrimary)
                Text("\(session.stream.width)×\(session.stream.height) · \(session.stream.fps) fps · \(session.stream.codec.uppercased())")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(SkhoFlowTheme.textSecondary)
            }
            .opacity(0.85)

            if showOverlay {
                overlay
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .onTapGesture { pingOverlay() }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            pingOverlay()
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            hub.streaming.stop()
        }
    }

    private var overlay: some View {
        VStack {
            HStack(spacing: 12) {
                Button {
                    hub.streaming.stop()
                    dismiss()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.circle.fill")
                        Text("End")
                    }
                }
                .buttonStyle(GlassButtonStyle())

                Spacer()

                statPill("fps", "\(hub.streaming.fps)")
                statPill("ms",  "\(hub.streaming.latencyMs)")
                statPill("Mbps", String(format: "%.1f", hub.streaming.bitrateMbps))
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            Spacer()
        }
    }

    private func statPill(_ label: String, _ value: String) -> some View {
        HStack(spacing: 6) {
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(SkhoFlowTheme.textPrimary)
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(SkhoFlowTheme.textTertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule().fill(.ultraThinMaterial)
                .overlay(Capsule().stroke(SkhoFlowTheme.strokeFaint, lineWidth: 1))
        )
    }

    private func pingOverlay() {
        withAnimation(.easeInOut(duration: 0.25)) { showOverlay = true }
        overlayWorkItem?.cancel()
        let work = DispatchWorkItem {
            withAnimation(.easeInOut(duration: 0.3)) { showOverlay = false }
        }
        overlayWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: work)
    }
}
