import SwiftUI
import UIKit

struct PairingView: View {
    @EnvironmentObject var hub: AppHub
    @Environment(\.dismiss) var dismiss

    let host: SkhoHost
    let completion: (SkhoHost?) -> Void

    @State private var digits: [String] = Array(repeating: "", count: 6)
    @FocusState private var focusedIndex: Int?
    @State private var pairing: Bool = false
    @State private var errorText: String?
    @State private var deviceName: String = UIDevice.current.name

    var body: some View {
        ZStack {
            SkhoFlowBackground()

            VStack(alignment: .leading, spacing: 20) {
                header

                HeroGlassCard {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("ENTER PIN")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(2)
                            .foregroundStyle(SkhoFlowTheme.hotRed)

                        Text("Read the 6-digit code shown on your PC.")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundStyle(SkhoFlowTheme.textSecondary)

                        pinRow

                        if let errorText {
                            Text(errorText)
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(SkhoFlowTheme.hotRed)
                        }

                        Button {
                            Task { await submit() }
                        } label: {
                            if pairing {
                                ProgressView().tint(.white)
                            } else {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.shield.fill")
                                    Text("Pair this iPhone")
                                }
                            }
                        }
                        .buttonStyle(AccentButtonStyle())
                        .disabled(pin.count < 6 || pairing)
                    }
                }

                GlassCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("DEVICE NAME")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .tracking(1.5)
                                .foregroundStyle(SkhoFlowTheme.textTertiary)
                            TextField("iPhone", text: $deviceName)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(SkhoFlowTheme.textPrimary)
                        }
                        Spacer()
                    }
                }

                Spacer()
            }
            .padding(20)
        }
        .preferredColorScheme(.dark)
        .onAppear { focusedIndex = 0 }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Button { completion(nil); dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(SkhoFlowTheme.textTertiary)
                }
                Spacer()
            }
            Text("Pair with")
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(SkhoFlowTheme.textSecondary)
            Text(host.name)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(SkhoFlowTheme.textPrimary)
        }
    }

    private var pinRow: some View {
        HStack(spacing: 10) {
            ForEach(0..<6, id: \.self) { i in
                TextField("", text: $digits[i])
                    .focused($focusedIndex, equals: i)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundStyle(SkhoFlowTheme.textPrimary)
                    .frame(width: 44, height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(SkhoFlowTheme.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(
                                        focusedIndex == i ? SkhoFlowTheme.crimson : SkhoFlowTheme.strokeFaint,
                                        lineWidth: focusedIndex == i ? 2 : 1
                                    )
                            )
                    )
                    .onChange(of: digits[i]) { _, new in
                        let filtered = String(new.filter(\.isNumber).prefix(1))
                        if filtered != new { digits[i] = filtered }
                        if !filtered.isEmpty && i < 5 { focusedIndex = i + 1 }
                        if filtered.isEmpty && i > 0 { focusedIndex = i - 1 }
                    }
            }
        }
    }

    private var pin: String { digits.joined() }

    @MainActor
    private func submit() async {
        guard pin.count == 6 else { return }
        pairing = true
        errorText = nil
        do {
            let deviceId = try await hub.pairing.pair(
                with: host, pin: pin,
                deviceName: deviceName,
                model: UIDevice.current.model
            )
            var saved = host
            saved.deviceId = deviceId
            completion(saved)
            dismiss()
        } catch {
            errorText = error.localizedDescription
            pairing = false
        }
    }
}
