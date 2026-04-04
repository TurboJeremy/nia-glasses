# Nia Glasses — Meta Ray-Ban Companion App

iOS app that connects to Meta Ray-Ban glasses via the Device Access Toolkit (DAT) SDK, streams video, captures photos, sends them to a backend AI vision API, and speaks the response.

## Setup Instructions (for Claude Code on Mac)

1. Open Xcode → File → New → Project → iOS App
   - Product Name: `NiaGlasses`
   - Bundle ID: `io.turbotime.nia.glasses`
   - Interface: SwiftUI
   - Language: Swift

2. Add Swift Package dependency:
   - File → Add Package Dependencies
   - URL: `https://github.com/facebook/meta-wearables-dat-ios`
   - Version: 0.5.0
   - Add products: `MWDATCore`, `MWDATCamera`, `MWDATMockDevice`

3. Copy all files from `NiaGlasses/` into the Xcode project source group

4. Set Info.plist: use the provided `NiaGlasses/Info.plist`

5. In Signing & Capabilities:
   - Set Team to Jeremy's Apple Developer Team ID (once enrollment completes)
   - Add Background Modes: Bluetooth peripheral, External accessory communication

6. Build & Run on physical iPhone (glasses won't connect to simulator, but MockDevice works)

## Architecture

```
Ray-Ban Meta glasses
    ↓ Bluetooth
Meta AI companion app (iPhone)
    ↓ DAT SDK
NiaGlasses app
    ↓ HTTPS POST
Backend vision API (Claude)
    ↓ JSON response
NiaGlasses app → AVSpeechSynthesizer → glasses speakers
```

## Key Files

| File | Purpose |
|------|---------|
| `NiaGlassesApp.swift` | Entry point, SDK initialization |
| `ViewModels/WearablesViewModel.swift` | Device discovery, registration |
| `ViewModels/GlassesSessionViewModel.swift` | Streaming, photo capture, AI analysis |
| `Services/NiaBackendService.swift` | HTTP client for vision API |
| `Views/MainView.swift` | Connection screen |
| `Views/GlassesView.swift` | Live feed + Ask Nia controls |

## Backend API

The app POSTs to a vision endpoint. Expected contract:

```
POST /api/vision
Content-Type: multipart/form-data

Fields:
- image: JPEG image data
- prompt: text prompt (e.g. "What am I looking at?")

Response:
{ "response": "I see a..." }
```

Update the URL in `NiaBackendService.swift` → `baseURL`.

## Meta Developer Dashboard

- App ID: 26301981209468778
- Bundle ID: io.turbotime.nia.glasses
- URL Scheme: niaglasses://
