# Build & run

## Prereqs

| Tool | Version | Notes |
|------|---------|-------|
| Visual Studio 2022 | 17.10+ | "Desktop development with C++" + ".NET desktop development" + "Windows App SDK C# Templates" workloads |
| .NET SDK | 8.0 | Bundled with VS, or `winget install Microsoft.DotNet.SDK.8` |
| Windows App SDK | 1.6+ | Auto-restored by the NuGet reference |
| Inno Setup | 6.2+ | <https://jrsoftware.org/isinfo.php> for the installer |
| Xcode | 15+ (macOS) | iOS client |
| ImageMagick | 7+ | Optional, to regenerate `skhoflow.ico` from the SVG |

## Windows host

The Windows App SDK 1.6 NuGet package depends on MSBuild tasks that ship
inside Visual Studio's *AppxPackage* folder, not in the .NET CLI SDK. So the
canonical build is **VS MSBuild**, not `dotnet build`. From PowerShell at the
repo root:

```powershell
# Use VS MSBuild (works because the AppxPackage tasks live next to it)
& "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe" `
    src\SkhoFlow.Host\SkhoFlow.Host.csproj `
    -t:Build -p:Configuration=Debug -p:Platform=x64 -restore

# Run the produced exe
.\src\SkhoFlow.Host\bin\x64\Debug\net8.0-windows10.0.22621.0\win-x64\SkhoFlow.exe
```

Easiest workflow: open `SkhoFlow.sln` in Visual Studio 2022 and hit **F5**.

To publish a redistributable, self-contained build (used by the installer):

```powershell
& "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe" `
    src\SkhoFlow.Host\SkhoFlow.Host.csproj `
    -t:Publish -p:Configuration=Release -p:Platform=x64 `
    -p:RuntimeIdentifier=win-x64 -p:SelfContained=true -restore
```

> `dotnet build` only works if you copy
> `Microsoft.Build.Packaging.Pri.Tasks.dll` from your VS install
> (`...\MSBuild\Microsoft\VisualStudio\v17.0\AppxPackage\`) into
> `C:\Program Files\dotnet\sdk\<ver>\Microsoft\VisualStudio\v17.0\AppxPackage\`.
> Using VS MSBuild side-steps the issue entirely.

### First run

- Settings live in `%LOCALAPPDATA%\SkhoFlow\`.
- The first launch starts:
  - UDP discovery responder on `:47988`
  - HTTP pairing/control server on `:47990`
  - Streaming pipeline (stubbed) on demand on `:47989` / `:47991`
- If you didn't run the installer, the HTTP listener may fall back to localhost only. Either run as Administrator once, or:
  ```powershell
  netsh http add urlacl url=http://+:47990/ user=Everyone
  netsh advfirewall firewall add rule name="SkhoFlow Control" dir=in action=allow protocol=TCP localport=47990
  netsh advfirewall firewall add rule name="SkhoFlow Probe"   dir=in action=allow protocol=UDP localport=47988
  netsh advfirewall firewall add rule name="SkhoFlow Video"   dir=in action=allow protocol=UDP localport=47989
  ```

## Installer

```powershell
# After dotnet publish:
iscc installer\SkhoFlow.iss
```

Output: `installer\Output\SkhoFlow-Setup-2.0.0.exe`.

## iOS client

On macOS:

```bash
cd ios
# Generate the Xcode project from scratch (one-time):
#   File → New → Project → iOS App → name SkhoFlow → drop the existing Swift files in
# or use XcodeGen / Tuist if you prefer config-driven projects.
open .
```

Run on simulator for UI; deploy to a physical iPhone (sign with your Apple ID) for real Wi-Fi discovery + VideoToolbox decode (once wired).

## What's stubbed vs real

| Area | Real | Stub |
|------|------|------|
| LAN discovery (UDP probe) | ✓ |  |
| HTTP pairing + PIN flow | ✓ |  |
| Settings persistence | ✓ |  |
| WinUI 3 glass UI / iOS glass UI | ✓ |  |
| Installer with firewall + URL ACL | ✓ |  |
| Video capture (Windows.Graphics.Capture) |  | stub — `StreamingHost.cs` emits synthetic stats |
| H.264/H.265 encode (Media Foundation) |  | stub |
| Audio loopback (WASAPI) |  | stub |
| Input forwarding (SendInput) |  | stub |
| VideoToolbox decode + Metal render |  | stub — `StreamingClient.swift` emits synthetic stats |

See `docs/protocol.md` for the wire format you're targeting when filling in those stubs.
