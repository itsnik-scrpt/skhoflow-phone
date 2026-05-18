# Sideload SkhoFlow on your iPhone (Windows + Sideloadly)

You don't need a Mac. GitHub Actions builds the `.ipa` for you, then **Sideloadly** on Windows signs and installs it with your free Apple ID.

> Free-Apple-ID limitations: the app stops working after **7 days** and you can only have **3 sideloaded apps** at a time. To remove these limits, pay $99/yr for an Apple Developer account.

---

## One-time setup (Windows)

1. **iTunes** — install from the Microsoft Store. Sideloadly needs the Apple drivers it bundles.
2. **iCloud** — install from the Microsoft Store. Also needed for the Apple network components.
3. **Sideloadly** — download and install from <https://sideloadly.io>.
4. **App-specific password** — generate one at <https://account.apple.com> → *Sign-In & Security* → *App-Specific Passwords*. You'll paste this into Sideloadly later (your normal Apple ID password won't work because 2FA is on).
5. **Trust this computer** — plug in your iPhone via USB, unlock it, and tap *Trust*.

---

## Each time you want a fresh build (every 7 days, or when you change code)

### 1. Build the `.ipa` on GitHub Actions

1. Push this repo to GitHub.
2. Go to **Actions → "Build iOS .ipa (unsigned)" → Run workflow**.
3. Wait ~6 minutes. When the run is green, scroll to **Artifacts → SkhoFlow-ipa** and download it.
4. Unzip the artifact. Inside you'll find `SkhoFlow.ipa`.

### 2. Install on iPhone

The easy way:

```powershell
.\ios\sideload\sideload.ps1 -Ipa "C:\path\to\SkhoFlow.ipa"
```

That script finds Sideloadly, verifies the `.ipa`, and launches Sideloadly with the file pre-loaded.

Or manually:

1. Open Sideloadly.
2. Drag `SkhoFlow.ipa` onto the Sideloadly window.
3. Enter your Apple ID.
4. Click **Start**.
5. When prompted, paste the app-specific password.
6. On the iPhone, open **Settings → General → VPN & Device Management → \<your Apple ID\>** and tap **Trust**.
7. Launch SkhoFlow from the home screen.

### 3. Allow local-network access

iOS prompts the first time SkhoFlow tries to find your PC. Tap **Allow**. (Free-developer sideloads can't ship the `multicast` entitlement, so the manual "type my PC's IP" path in the Hosts tab is the most reliable.)

---

## When the 7 days expire

The app icon goes grey and tapping it fails. Re-run the workflow (or reuse the same `.ipa` if nothing changed) and sideload again with the same Apple ID. Sideloadly has a **Refresh** option that re-signs the existing install without redownloading.

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Sideloadly says "ITunesMobileDevice.dll not found" | Reinstall iTunes from the Microsoft Store (not the Apple website — the MS Store version installs drivers in the right place). |
| "Could not pair with device" | Unlock iPhone, tap *Trust* on the popup. Reconnect cable. Switch USB ports. |
| Build fails in GitHub Actions | Check the run log. Most common cause is a Swift compile error after you've edited code — open the Xcode project locally on a Mac (or in `ios/` with XcodeGen) to see it. |
| App crashes on launch | Run `Console.app` on a Mac with the iPhone attached, or use `idevicesyslog` on Windows (part of `libimobiledevice`). |
