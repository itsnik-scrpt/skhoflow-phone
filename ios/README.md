# SkhoFlow — iOS client

SwiftUI app that discovers SkhoFlow hosts on the LAN, pairs over a 6-digit PIN, and (in the next pass) decodes the H.264/H.265 stream via VideoToolbox into a `Metal` layer.

## Build

1. Open Xcode 15+ on macOS.
2. **File → Open** → choose this `ios/` folder. When prompted, "Create New Xcode Project from Source" — Xcode will scaffold the project around the existing Swift files, or generate the project manually with the layout below.
3. Set the bundle id to something like `com.skhoflow.client` and your Apple Developer team.
4. Run on an iPhone (simulator works for the UI; real device required for VideoToolbox hardware decode).

## Layout

```
ios/SkhoFlow/
├── SkhoFlowApp.swift           Entry point + scene
├── ContentView.swift           Root tab / navigation
├── Theme/
│   ├── SkhoFlowTheme.swift     Red/black palette, fonts
│   └── GlassBackground.swift   .ultraThinMaterial helpers
├── Models/
│   ├── SkhoHost.swift
│   └── StreamSettings.swift
├── Views/
│   ├── WelcomeView.swift
│   ├── HostListView.swift
│   ├── PairingView.swift
│   ├── StreamView.swift
│   └── SettingsView.swift
└── Services/
    ├── DiscoveryService.swift  UDP probe → reply
    ├── PairingService.swift    HTTP /pair, /session/start
    └── StreamingClient.swift   stub VideoToolbox decoder
```

## Required Info.plist keys (for the production build)

- `NSLocalNetworkUsageDescription` — "SkhoFlow discovers your PC on the local network to stream games."
- `NSBonjourServices` — `_skhoflow._tcp` (when mDNS is wired)
- Background mode: `audio` (so streams keep running with screen off / lock disabled)

## Status

UI and discovery are done. Pairing is fully wired against the Windows host. Streaming pulls a session from the host but the decoded picture is a placeholder until VideoToolbox is wired up.
