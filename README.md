# Verba

A macOS **menu-bar** dictation app — talk, and Verba transcribes you and uses
**Claude** to restructure your rambling stream-of-consciousness into a clean,
well-ordered prompt or message. Think Wispr Flow, but the cleanup is done by an
LLM you control, with your own API keys.

Built for **vibe coding** (turn a 20-minute voice feedback into a tidy spec for
a coding agent) and **messaging** — and anything in between via editable
profiles.

## How it works

1. Press the hotkey (default **⌃⌥Space**) → speak → press again to stop.
2. **Transcription** — your choice of:
   - **OpenAI** `gpt-4o-transcribe` (cloud, best accuracy), or
   - **Local** on-device (free, offline, no size limit — handles 20-minute
     monologues without the cloud's 25 MB cap) via **WhisperKit** or **NVIDIA
     Parakeet** (FluidAudio).
3. **Reprompting** — Claude (`claude-sonnet-4-6` by default; Haiku / Opus
   selectable) restructures the raw transcript using the active **profile**.
   You can also route through OpenRouter to use any model (defaults to
   `anthropic/claude-3.7-sonnet` until you pick one).
4. **Output** — auto-pastes into the active field, copies to clipboard, and
   saves the original transcript + the restructured version to **History**
   (with the audio), Wispr-Flow style. Optionally review/edit before it lands.

**BYOK** — you bring your own OpenAI + Anthropic keys (stored in the macOS
Keychain). Verba makes no API calls of its own.

## Profiles

Built-in: **Flow** (raw, no reprompting), **Intent**, **Polish** (the default
on fresh installs), **Coding**, **Casual**, and **Custom**. Each is a Claude
system prompt you can edit, plus a list of app bundle IDs it auto-matches
(e.g. Xcode/VS Code/terminal → Coding; Slack/Mail → a messaging profile). Add
your own.

## Build

```sh
swift build -c release        # or ./bundle.sh to assemble Verba.app
```

Requires macOS 14+, Swift 6 (Xcode 26). Local transcription downloads the
WhisperKit model on first use, then runs fully offline.

## Permissions

- **Microphone** — to record you.
- **Accessibility** — to auto-paste (⌘V) into other apps. Without it, Verba
  falls back to copying to the clipboard.

---

Proprietary. © 2026 Agentik / Dafnck Studio.
