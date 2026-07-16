# CI / cloud-macOS release setup

macOS **and** iOS apps can only be built, signed and notarized on **macOS with Xcode** — never on
Linux (Apple toolchain). To release without this Mac, the build runs on a **cloud macOS runner**:

- **Desktop** (this repo) → GitHub Actions macOS runner (`.github/workflows/release.yml`).
- **Mobile** (`VerbaMobile`) → EAS Build (Expo's macOS cloud). See `docs/MOBILE-CI.md` there.

From your VPS you only ever run `git` / `gh` / `eas` — the actual compile happens on a cloud Mac.

## Desktop release — how to trigger

Push a version tag from anywhere (VPS included):

```bash
git tag v0.9.94
git push origin v0.9.94
```

That fires the `Release (macOS desktop)` workflow: `swift build` → `bundle.sh` → codesign (hardened
runtime, App Group) → notarize → Sparkle appcast → GitHub release on `agentik-os/Verba-releases`.
Watch it: `gh run watch --repo agentik-os/Verba` (or the Actions tab).

You can also run it manually: **Actions → Release (macOS desktop) → Run workflow** (enter a version).

## GitHub Secrets (repo `agentik-os/Verba`) — ALL ALREADY SET

| Secret | What | Source |
|---|---|---|
| `APPLE_CERT_P12_BASE64` | Developer ID Application cert + private key, `.p12`, base64 | exported from the Mac login keychain |
| `APPLE_CERT_PASSWORD` | password for that `.p12` | random, stored alongside |
| `APPLE_DEVID` | `Developer ID Application: Gareth Moison (975755H4ZC)` | the signing identity name |
| `NOTARY_KEY_BASE64` | App Store Connect API key `.p8`, base64 | `~/.omega/appstore/AuthKey_J9GPQFGN66.p8` |
| `NOTARY_KEY_ID` | `J9GPQFGN66` | the key id |
| `NOTARY_ISSUER_ID` | `8943ce0e-1693-4846-87d8-cb26e08f5e52` | App Store Connect issuer |
| `SPARKLE_ED_PRIVATE_KEY` | Sparkle EdDSA private key (matches `SUPublicEDKey` in `bundle.sh`) | `generate_keys -x` from the keychain |
| `RELEASES_TOKEN` | token with `contents:write` on `agentik-os/Verba-releases` | currently the operator's `gh` token |

### Re-creating a secret (if you ever rotate the Mac / keys)

```bash
REPO=agentik-os/Verba
# Developer ID cert → .p12 → secret
P12PASS=$(uuidgen)
security export -k login.keychain-db -t identities -f pkcs12 -P "$P12PASS" -o /tmp/devid.p12
base64 -i /tmp/devid.p12 | gh secret set APPLE_CERT_P12_BASE64 --repo $REPO
gh secret set APPLE_CERT_PASSWORD --repo $REPO --body "$P12PASS"; rm /tmp/devid.p12
# App Store Connect API key → secret
base64 -i ~/.omega/appstore/AuthKey_J9GPQFGN66.p8 | gh secret set NOTARY_KEY_BASE64 --repo $REPO
# Sparkle EdDSA private key → secret (public key must equal SUPublicEDKey in bundle.sh)
.build/artifacts/sparkle/Sparkle/bin/generate_keys -x /tmp/sk && gh secret set SPARKLE_ED_PRIVATE_KEY --repo $REPO < /tmp/sk && rm /tmp/sk
```

## Security note on `RELEASES_TOKEN`

It's currently the operator's broad `gh` token (works, turnkey). For tighter scope, replace it with a
**fine-grained PAT** limited to `agentik-os/Verba-releases` → `Contents: Read and write`, then
`gh secret set RELEASES_TOKEN --repo agentik-os/Verba --body <pat>`.

## The Parakeet model in CI

The bundled on-device speech model (`parakeet-tdt-0.6b-v3`, ~461 MB) isn't committed; the workflow
`git lfs clone`s it from `https://huggingface.co/FluidInference/parakeet-tdt-0.6b-v3-coreml` and points
`PARAKEET_SRC` at it so `bundle.sh` embeds it. The Whisper tokenizer IS committed (`WhisperTokenizer/`).
