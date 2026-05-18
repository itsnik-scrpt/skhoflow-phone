# SkhoFlow

Low-latency PC → iPhone game streaming. Glass UI. Built on WinUI 3 (host) and SwiftUI (client).

```
+---------------------+        +---------------------+
|   Windows host      |   <-->   |    iOS client     |
|   (WinUI 3, C#)     |  Wi-Fi   |  (SwiftUI, Swift) |
|   captures + encodes|          |  decodes + input  |
+---------------------+          +---------------------+
```

## Repo layout

| Path | What lives here |
|------|-----------------|
| `src/SkhoFlow.Host/` | WinUI 3 desktop host app (the PC side). Open `SkhoFlow.sln` in Visual Studio 2022. |
| `ios/SkhoFlow/` | SwiftUI iOS client. Open the folder in Xcode on macOS. |
| `installer/` | Inno Setup script that bundles the published host into a Windows installer. |
| `docs/protocol.md` | Wire protocol design (pairing, control, video, audio, input). |
| `docs/build.md` | Build instructions for both apps + installer. |

## Brand

- **Name:** SkhoFlow
- **Palette:** matte black `#0A0A0A`, crimson accent `#E11D2A`, hot-red highlight `#FF2937`
- **Material:** Mica + Acrylic on Windows, `.ultraThinMaterial` on iOS — "liquid glass"
- **Iconography:** Segoe Fluent Icons (Windows), SF Symbols (iOS). No emoji.
- **Typography:** Segoe UI Variable (Windows), SF Pro (iOS)

## Quick start

Windows host:
```powershell
# Build with VS 2022 MSBuild (see docs/build.md for why)
& "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe" `
    src\SkhoFlow.Host\SkhoFlow.Host.csproj -t:Build -p:Configuration=Debug -p:Platform=x64 -restore

.\src\SkhoFlow.Host\bin\x64\Debug\net8.0-windows10.0.22621.0\win-x64\SkhoFlow.exe
```

iOS client (on macOS):
```bash
cd ios
open SkhoFlow.xcodeproj   # then Run on a device or simulator
```

Installer (after Release build):
```powershell
iscc installer\SkhoFlow.iss
```

See `docs/build.md` for full prerequisites.

## Status

This is the V2 scaffold. Pairing, discovery (mDNS), and the control channel are wired. The video capture / encode / decode pipeline is defined as an interface (`IStreamingHost`, `StreamingClient`) with stub implementations — wire H.264 NVENC + VideoToolbox in next pass.
