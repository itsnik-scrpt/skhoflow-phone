# Installer

Inno Setup 6 script that produces `SkhoFlow-Setup-2.0.0.exe`.

## Build

1. Install **Inno Setup 6** from <https://jrsoftware.org/isinfo.php>.
2. From the repo root, publish a self-contained Windows build of the host:
   ```powershell
   dotnet publish src\SkhoFlow.Host\SkhoFlow.Host.csproj -c Release -r win-x64
   ```
3. Generate `Assets\skhoflow.ico` (see `src/SkhoFlow.Host/Assets/README.md`).
4. Compile the installer:
   ```powershell
   iscc installer\SkhoFlow.iss
   ```
5. The signed-ready setup binary lands in `installer\Output\`.

## What the installer does

| Step | Action |
|------|--------|
| Files | Copies the published runtime to `Program Files\SkhoFlow\` |
| Shortcut | Start menu + optional desktop icon |
| Autostart | Optional `HKCU\...\Run` entry |
| URL ACL | `netsh http add urlacl :47990` so the pairing server can bind on the LAN |
| Firewall | Opens TCP `47990` (control), UDP `47989` (video), UDP `47988` (probe) |
| Uninstall | Reverses URL ACL + firewall rules |

## Code signing (recommended before distribution)

```powershell
signtool sign /tr http://timestamp.digicert.com /td sha256 /fd sha256 /a installer\Output\SkhoFlow-Setup-2.0.0.exe
```
