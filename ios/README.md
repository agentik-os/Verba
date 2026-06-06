# Verba iOS (separate project)

This folder is the iOS app. It is **completely separate** from the macOS app
(`../Sources/Verba`, built with Swift Package Manager). Nothing here is compiled by
the macOS build, so working on one never breaks the other.

## What it is
- **VerbaApp** — the container app: sign in (Clerk), settings, history sync (Convex),
  and the actual recording + transcription + Claude reprompting.
- **VerbaKeyboard** — a custom keyboard extension showing your modes + a record button.

## Important iOS constraint
Custom keyboard extensions **cannot access the microphone**. So the flow is:
1. In any app, switch to the Verba keyboard. It shows your modes + a mic button.
2. Tapping the mic opens the Verba app (URL scheme `verba://record?mode=polish`).
3. The app records, transcribes, reprompts, writes the result to the shared
   **App Group** (`group.com.agentik.verba`), and returns to the previous app.
4. The keyboard reads the App Group result and **inserts it** at the cursor.

## Build
This uses [XcodeGen](https://github.com/yonyz/XcodeGen) so the project is reproducible:
```
brew install xcodegen
cd ios && xcodegen generate && open Verba.xcodeproj
```
Set your team + bundle ids + the App Group capability on both targets in Xcode, then run.

## Status
Scaffold with the core pieces. Transcription on iOS can reuse the same cloud endpoints
(OpenAI + Anthropic) or on-device Speech; wire your keys via the app.
