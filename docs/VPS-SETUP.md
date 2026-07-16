# Working from the VPS — what runs where

**Hard rule:** macOS and iOS apps cannot be compiled on Linux (Apple toolchain). So the *builds*
always run on a cloud Mac — you just **trigger** them from the VPS with `git` / `gh` / `eas`.

| Task | Runs on | Trigger from the VPS |
|---|---|---|
| Website (Next.js/Convex) | Linux / Vercel | `npm run build`, `vercel --prod --token=$VERCEL_TOKEN`, `npx convex deploy` |
| **Desktop app** build+release | **GitHub Actions macOS runner** | `git tag v0.9.94 && git push origin v0.9.94` |
| **Mobile app** build (iOS+Android) | **EAS cloud (Expo)** | `eas build …` or `git tag mobile-v1.2.0 && git push` |
| Code edit / git / orchestration | Linux | normal |

## Fresh VPS bootstrap (Linux)

```bash
# tools (no Swift/Xcode — builds are in the cloud)
sudo apt-get update && sudo apt-get install -y git git-lfs
# node (for website + eas)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && sudo apt-get install -y nodejs
npm i -g eas-cli vercel
# gh CLI
type gh >/dev/null || (curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list && \
  sudo apt-get update && sudo apt-get install -y gh)
gh auth login            # once
export EXPO_TOKEN=…      # for mobile (expo.dev → Access tokens)

git clone https://github.com/agentik-os/Verba.git          # desktop + website
git clone https://github.com/agentik-os/VerbaMobile.git    # mobile
```

Then everything works from the VPS:
- **Desktop release:** `cd Verba && git tag v0.9.94 && git push origin v0.9.94` → watch `gh run watch --repo agentik-os/Verba`. All signing secrets are already GitHub Secrets (see `docs/CI-SETUP.md`).
- **Mobile release:** `cd VerbaMobile && eas build --platform all --profile production --non-interactive` (or push a `mobile-v*` tag). See `VerbaMobile/docs/MOBILE-CI.md`.
- **Website:** `cd Verba/website && npx convex deploy && vercel --prod --token=$VERCEL_TOKEN`.

## What secrets live where (nothing on the Mac is required anymore)

- **Desktop signing** (Developer ID cert, App Store Connect notary key, Sparkle key, Verba-releases token): **GitHub Secrets** on `agentik-os/Verba` — already set.
- **Mobile signing**: **EAS** (managed iOS creds) + `EXPO_TOKEN`.
- **Website**: Vercel env + Convex env (already configured).

The only Apple-account-level things you must keep valid: the Developer ID cert (renew before expiry)
and the App Store Connect API key. Rotation commands are in `docs/CI-SETUP.md`.
