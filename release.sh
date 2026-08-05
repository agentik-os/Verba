#!/bin/bash
# Cut a notarized release + Sparkle appcast + GitHub release.
#
#   DEVID="Developer ID Application: Gareth Moison (975755H4ZC)" \
#   VERSION=0.1.0 ./release.sh
#
# Prereqs: notary profile stored (see sign-and-notarize.sh), `gh` logged in,
# and the Sparkle EdDSA private key in your keychain (already set — public key
# tUNn6q4… is in bundle.sh's Info.plist).
#
# NOTE: for auto-update to reach end users, the release assets (Verba.dmg +
# appcast.xml) must be publicly downloadable. The repo is private — either make
# it public, or host the appcast/DMG on a public repo/CDN and update SUFeedURL.
# NOTE on `set -u` + bash 3.2 (the /bin/bash on macOS runners): expanding an EMPTY array as
# "${arr[@]}" is an unbound-variable error there. Every array expansion below therefore uses
# the portable ${arr[@]+"${arr[@]}"} guard.
set -euo pipefail
cd "$(dirname "$0")"

VERSION="${VERSION:?Set VERSION, e.g. VERSION=0.1.0 ./release.sh}"
: "${DEVID:?Set DEVID to your Developer ID Application identity}"
# Releases (DMG + appcast) go to the PUBLIC repo: it backs both the website
# download (/releases/latest/download/Verba.dmg) and the Sparkle feed (SUFeedURL).
REPO="agentik-os/Verba-releases"
GENAPPCAST=".build/artifacts/sparkle/Sparkle/bin/generate_appcast"

# ─────────────────────────────────────────────────────────────────────────────
# APPCAST INTROSPECTION — used by the gate on the LOCAL appcast before upload,
# and again on the PUBLISHED feed after it.
#
# `generate_appcast` (Sparkle 2) emits the version as an ELEMENT inside <item>:
#     <sparkle:version>0.9.98</sparkle:version>
# Sparkle 1 put it on the enclosure instead (sparkle:version="0.9.98"), and the
# app's own feed parser accepts both (Tests/UpdaterContractTests.swift). A gate
# that greps for the attribute form therefore matches NOTHING against the feed
# we actually generate — it fails every release after the ~40-minute build, and
# it would have gone on failing until someone read the XML. So: parse the
# document with a real parser rather than pattern-matching its serialization,
# and accept BOTH shapes so a Sparkle up- or downgrade cannot blind this again.
# xmllint first (always present on macOS), python3 as the fallback — the same
# two-backend pattern the well-formedness gate below already uses.
# ─────────────────────────────────────────────────────────────────────────────
SPARKLE_NS="http://www.andymatuschak.org/xml-namespaces/sparkle"

# appcast_facts <file> — print, one fact per line:
#   items <count>     how many <item> entries the feed carries
#   version <value>   once per sparkle:version found, element form or attribute form
# Returns non-zero when the file cannot be parsed at all.
appcast_facts() {
  local file="$1"
  local xp_item xp_ver n i v
  xp_item="//*[local-name()='item']"
  xp_ver="//*[local-name()='version' and namespace-uri()='$SPARKLE_NS']"
  xp_ver="$xp_ver | //@*[local-name()='version' and namespace-uri()='$SPARKLE_NS']"
  if command -v xmllint >/dev/null 2>&1; then
    n="$(xmllint --xpath "count($xp_item)" "$file" 2>/dev/null)" || return 1
    printf 'items %s\n' "${n%%.*}"
    n="$(xmllint --xpath "count($xp_ver)" "$file" 2>/dev/null)" || return 1
    n="${n%%.*}"
    i=1
    while [ "$i" -le "$n" ]; do
      # string() of a single-node filter expression is that node's text; normalize-space
      # strips the indentation generate_appcast wraps element content in.
      v="$(xmllint --xpath "normalize-space(string(($xp_ver)[$i]))" "$file" 2>/dev/null)" || return 1
      [ -n "$v" ] && printf 'version %s\n' "$v"
      i=$((i + 1))
    done
  else
    python3 - "$file" "$SPARKLE_NS" <<'PY' || return 1
import sys, xml.etree.ElementTree as ET
path, ns = sys.argv[1], sys.argv[2]
nodes = list(ET.parse(path).getroot().iter())
print("items %d" % sum(1 for e in nodes if e.tag.rsplit("}", 1)[-1] == "item"))
tag = "{%s}version" % ns
for e in nodes:
    for raw in (e.text if e.tag == tag else None, e.attrib.get(tag)):
        if raw and raw.strip():
            print("version %s" % " ".join(raw.split()))
PY
  fi
}

# assert_appcast_advertises <file> <expected-version> <label> — refuse anything but a feed
# carrying exactly one <item> whose sparkle:version is exactly <expected-version>.
# MISSING (a feed no client can act on), MULTIPLE (a stale DMG left in dist/ — its enclosure
# would 404 under this release's tag, which the enclosure gate below also refuses) and
# MISMATCHED (we would publish a build the feed does not advertise) all abort the release.
assert_appcast_advertises() {
  local file="$1" want="$2" label="$3"
  local facts items="" versions="" distinct="" ndistinct=0 kind val

  facts="$(appcast_facts "$file")" || {
    echo "❌ $label: could not be parsed for sparkle:version." >&2
    echo "   Either the XML is unreadable, or neither xmllint nor python3 is available here." >&2
    exit 1; }

  while read -r kind val; do
    case "$kind" in
      items)   items="$val" ;;
      version) versions="$versions$val
" ;;
    esac
  done <<< "$facts"

  case "$items" in
    1) ;;
    0|"")
      echo "❌ $label carries no <item> — every client would see an empty feed." >&2
      exit 1 ;;
    *)
      echo "❌ $label carries $items <item> entries; exactly one (v$want) is expected." >&2
      echo "   A leftover DMG in dist/ gets its own item, and its enclosure would 404 under" >&2
      echo "   this release's tag. Fix: rm -rf dist && re-run." >&2
      exit 1 ;;
  esac

  distinct="$(printf '%s' "$versions" | sed '/^[[:space:]]*$/d' | sort -u)"
  [ -n "$distinct" ] && ndistinct="$(printf '%s\n' "$distinct" | wc -l | tr -d '[:space:]')"
  if [ "$ndistinct" -eq 0 ]; then
    echo "❌ $label carries no sparkle:version (neither a <sparkle:version> element nor an" >&2
    echo "   enclosure attribute). Sparkle cannot compare it against an installed build." >&2
    exit 1
  fi
  if [ "$ndistinct" -gt 1 ]; then
    echo "❌ $label advertises conflicting sparkle:version values:" \
         "$(printf '%s' "$distinct" | tr '\n' ' ')" >&2
    exit 1
  fi
  [ "$distinct" = "$want" ] || {
    echo "❌ $label advertises sparkle:version='$distinct', expected '$want'." >&2
    exit 1; }
  echo "▸ $label advertises sparkle:version $want (one item, one version)."
}

# ─────────────────────────────────────────────────────────────────────────────
# PREFLIGHT — everything below runs in seconds, BEFORE the ~40-minute build +
# notarization round trip, and before anything is published. A release that
# cannot be valid must die here, not in the field.
# ─────────────────────────────────────────────────────────────────────────────

# 1. Version shape. Sparkle's SUStandardVersionComparator ranks a component that starts with a
#    letter BELOW every numeric one, so "main" or "v0.9.98" would read as OLDER than the published
#    0.9.97 and no installed client would ever update. Digits and dots only.
if ! printf '%s' "$VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  echo "❌ VERSION='$VERSION' is not MAJOR.MINOR.PATCH (digits only, e.g. 0.9.98)." >&2
  exit 1
fi

# 2. Sparkle EdDSA key, when the CI path supplies one as a file. `printf '%s' "$SECRET" > file`
#    writes a 0-byte file and exits 0 when the secret is unset, so test the FILE, not the path.
if [ -n "${SPARKLE_ED_KEY_FILE:-}" ] && [ ! -s "$SPARKLE_ED_KEY_FILE" ]; then
  echo "❌ SPARKLE_ED_KEY_FILE='$SPARKLE_ED_KEY_FILE' is missing or empty." >&2
  echo "   The SPARKLE_ED_PRIVATE_KEY secret is unset — the appcast could not be signed." >&2
  exit 1
fi

# 3. MONOTONICITY. Nothing else in the pipeline compares this release to what is already
#    published, and GitHub marks the most recently created release as `latest` — which is
#    exactly what SUFeedURL (/releases/latest/download/appcast.xml) and the website download
#    link resolve through. Publishing a LOWER version therefore repoints every installed
#    client's feed at an older build: they compare it against what they already run, find
#    nothing newer, and report "up to date" silently and permanently.
#    Equal is allowed on purpose: re-running the same version is the retry path, and it is
#    non-destructive now (see the publish step — the release is never deleted).
version_le() {  # version_le A B -> true when A <= B, comparing each dotted field numerically
  local a b i; IFS=. read -r -a a <<< "$1"; IFS=. read -r -a b <<< "$2"
  for i in 0 1 2; do
    (( 10#${a[i]:-0} < 10#${b[i]:-0} )) && return 0
    (( 10#${a[i]:-0} > 10#${b[i]:-0} )) && return 1
  done
  return 0
}
if [ "${ALLOW_NON_MONOTONIC:-0}" = "1" ]; then
  echo "⚠︎ ALLOW_NON_MONOTONIC=1 — skipping the published-version comparison (deliberate override)."
else
  echo "▸ Checking $VERSION against the currently published release on $REPO…"
  LATEST_TAG=""
  if LATEST_TAG="$(gh release view --repo "$REPO" --json tagName -q .tagName 2>/dev/null)"; then
    LATEST_VER="${LATEST_TAG#v}"
    if printf '%s' "$LATEST_VER" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
      if [ "$LATEST_VER" != "$VERSION" ] && version_le "$VERSION" "$LATEST_VER"; then
        echo "❌ $VERSION is NOT newer than the published $LATEST_VER." >&2
        echo "   Publishing it would make GitHub's 'latest' — and therefore the Sparkle feed and" >&2
        echo "   the website download — point at an OLDER build. Every client would go silent." >&2
        echo "   Cut a higher version, or set ALLOW_NON_MONOTONIC=1 if this is deliberate." >&2
        exit 1
      fi
      [ "$LATEST_VER" = "$VERSION" ] \
        && echo "▸ v$VERSION is already published — re-cutting it (assets overwritten in place, release NOT deleted)." \
        || echo "▸ $VERSION > $LATEST_VER — monotone."
    else
      echo "⚠︎ Published latest tag '$LATEST_TAG' is not MAJOR.MINOR.PATCH; cannot compare. Continuing."
    fi
  else
    # `gh release view` (no tag) reads /releases/latest, which EXCLUDES drafts and prereleases.
    # It therefore returns nothing in three very different situations, and only one of them is
    # safe to continue from. Distinguish them explicitly — a broken token must never silently
    # disable the only guard against a downgrade, and "the repo only holds prereleases" must not
    # be mistaken for "the repo is empty".
    COUNT="$(gh api "repos/$REPO/releases?per_page=100" -q 'length' 2>/dev/null || echo ERR)"
    case "$COUNT" in
      0)
        echo "▸ No release on $REPO yet — first release, nothing to compare." ;;
      ERR|"")
        echo "❌ Cannot read releases from $REPO (auth, network, or RELEASES_TOKEN scope)." >&2
        echo "   Refusing to publish blind: the downgrade guard could not run." >&2
        echo "   Fix the token, or set ALLOW_NON_MONOTONIC=1 to publish without the check." >&2
        exit 1 ;;
      *)
        echo "❌ $REPO holds $COUNT release(s) but none is published as 'latest'" >&2
        echo "   (all draft or prerelease?). SUFeedURL resolves through 'latest', so the guard" >&2
        echo "   cannot tell what users are actually running. Refusing to publish blind." >&2
        echo "   Set ALLOW_NON_MONOTONIC=1 to publish without the check." >&2
        exit 1 ;;
    esac
  fi
fi

# Stamp the version into the bundle, then sign + notarize (builds app + dmg).
VERSION="$VERSION" DEVID="$DEVID" ./sign-and-notarize.sh

# ── Gate: the built bundle really carries the version we were asked to ship ──
# bundle.sh asserts this too, but release.sh is what PUBLISHES, so it re-checks the artifact
# it is about to hand to users rather than trusting an upstream script's word for it.
for KEY in CFBundleVersion CFBundleShortVersionString; do
  GOT="$(/usr/libexec/PlistBuddy -c "Print :$KEY" Verba.app/Contents/Info.plist 2>/dev/null || true)"
  [ "$GOT" = "$VERSION" ] || {
    echo "❌ Verba.app Info.plist $KEY is '$GOT', expected '$VERSION' — refusing to publish." >&2
    exit 1; }
done

[ -x "$GENAPPCAST" ] || {
  echo "❌ generate_appcast not found at $GENAPPCAST (Sparkle artifact layout changed?)." >&2
  exit 1; }

# Collect this build into dist/ and (re)generate the signed appcast.
# dist/ is KEPT across releases (versioned DMG names) so generate_appcast can
# emit Sparkle delta updates between consecutive versions. The stable asset
# name (Verba.dmg) is still uploaded alongside, so the website's
# /releases/latest/download/Verba.dmg link keeps resolving.
mkdir -p dist
DMG_VERSIONED="dist/Verba-$VERSION.dmg"
cp Verba.dmg "$DMG_VERSIONED"
# generate_appcast signs the appcast with the Sparkle EdDSA PRIVATE key. Locally it reads it from
# the login keychain; in CI there's no keychain, so pass it as a file via SPARKLE_ED_KEY_FILE
# (the workflow writes the SPARKLE_ED_PRIVATE_KEY secret to a temp file).
DOWNLOAD_PREFIX="https://github.com/$REPO/releases/download/v$VERSION/"
GENAPPCAST_ARGS=(dist --download-url-prefix "$DOWNLOAD_PREFIX")
if [ -n "${SPARKLE_ED_KEY_FILE:-}" ]; then
  GENAPPCAST_ARGS+=(--ed-key-file "$SPARKLE_ED_KEY_FILE")
fi
"$GENAPPCAST" "${GENAPPCAST_ARGS[@]}"

[ -f dist/appcast.xml ] || { echo "❌ generate_appcast produced no dist/appcast.xml" >&2; exit 1; }

# Sparkle deltas this run produced (none in CI: the runner is ephemeral, so dist/ holds a
# single DMG and there is nothing to diff against). Computed here because the enclosure gate
# below needs to know which files are actually going to be uploaded.
DELTAS=(dist/*.delta)
[ -e "${DELTAS[0]}" ] || DELTAS=()

# ── Gate: the appcast is well-formed XML ──
# CRITICAL=1 rewrites this file with an in-place regex further down, and a malformed feed
# breaks auto-update for the ENTIRE installed base. Parse it, do not eyeball it.
if command -v xmllint >/dev/null 2>&1; then
  xmllint --noout dist/appcast.xml \
    || { echo "❌ dist/appcast.xml is not well-formed XML" >&2; exit 1; }
else
  python3 -c 'import sys,xml.dom.minidom as m; m.parse(sys.argv[1])' dist/appcast.xml \
    || { echo "❌ dist/appcast.xml is not well-formed XML" >&2; exit 1; }
fi

# ── Gate: the appcast advertises OUR version, once ──
# generate_appcast reads sparkle:version back out of the DMG's own Info.plist, so this is an
# independent check on the artifact — unlike the filename, which we built from $VERSION.
assert_appcast_advertises dist/appcast.xml "$VERSION" "dist/appcast.xml"

# ── Gate: every enclosure URL points at a file this run actually uploads ──
# --download-url-prefix is per-RELEASE but applies to the whole dist/ DIRECTORY. A leftover
# DMG from an earlier version (possible on a local run; dist/ is gitignored and never pruned)
# gets an enclosure under THIS release's tag, where that file was never uploaded — a 404 for
# any client the feed sends there. Refuse rather than ship a dangling URL.
while read -r URL; do
  [ -n "$URL" ] || continue
  case "$URL" in
    "$DOWNLOAD_PREFIX"*) ;;
    *) echo "❌ appcast enclosure '$URL' is not under $DOWNLOAD_PREFIX" >&2; exit 1 ;;
  esac
  BASE="${URL##*/}"
  OK=0
  [ "$BASE" = "Verba-$VERSION.dmg" ] && OK=1
  for D in ${DELTAS[@]+"${DELTAS[@]}"}; do [ "$BASE" = "$(basename "$D")" ] && OK=1; done
  [ "$OK" = "1" ] || {
    echo "❌ appcast enclosure '$BASE' is not among the assets this run uploads." >&2
    echo "   Stale artifact in dist/? Its URL would 404 for every client the feed sends there." >&2
    echo "   Fix: rm -rf dist && re-run." >&2
    exit 1; }
done <<< "$(grep -o '<enclosure[^>]*url="[^"]*"' dist/appcast.xml | grep -o 'url="[^"]*"' | cut -d'"' -f2)"

# ── Gate: verify the appcast's EdDSA signature against the SUPublicEDKey that
# actually SHIPS in the app bundle. A keychain/bundle key mismatch would make
# every installed client reject the update — fail here, not in the field.
# (`|| true` on the extractions so a miss reaches the explicit message below instead of
# aborting bare under `set -e` / `pipefail`.)
SHIPPED_KEY="$(/usr/libexec/PlistBuddy -c 'Print :SUPublicEDKey' Verba.app/Contents/Info.plist 2>/dev/null || true)"
[ -n "$SHIPPED_KEY" ] || { echo "❌ No SUPublicEDKey in Verba.app/Contents/Info.plist" >&2; exit 1; }
ED_SIG="$(grep -o "<enclosure[^>]*Verba-$VERSION\.dmg[^>]*" dist/appcast.xml \
  | grep -o 'sparkle:edSignature="[^"]*"' | head -1 | cut -d'"' -f2 || true)"
[ -n "$ED_SIG" ] || { echo "❌ dist/appcast.xml has no sparkle:edSignature for Verba-$VERSION.dmg" >&2; exit 1; }
echo "▸ Verifying appcast EdDSA signature against shipped SUPublicEDKey…"
swift - "$SHIPPED_KEY" "$DMG_VERSIONED" "$ED_SIG" <<'SWIFT'
import CryptoKit
import Foundation
let a = CommandLine.arguments
guard a.count == 4,
      let pub = Data(base64Encoded: a[1]),
      let sig = Data(base64Encoded: a[3]),
      let data = try? Data(contentsOf: URL(fileURLWithPath: a[2])),
      let key = try? Curve25519.Signing.PublicKey(rawRepresentation: pub),
      key.isValidSignature(sig, for: data)
else {
    FileHandle.standardError.write(Data("❌ Appcast EdDSA signature does NOT verify against the shipped SUPublicEDKey — the signing key and the bundled public key disagree. Aborting release.\n".utf8))
    exit(1)
}
print("✓ Appcast EdDSA signature verifies against the shipped SUPublicEDKey")
SWIFT

# Optional: mark THIS version's appcast item as a critical update. Sparkle then surfaces it more
# insistently (skips the phased-rollout wait, harder to defer) so a reliability fix reaches everyone
# fast. Opt-in per release via CRITICAL=1 so ordinary releases stay non-critical. Inserted AFTER the
# signature gate and BEFORE upload, into this version's <item> only (before its enclosure) — the
# enclosure line the gate verifies is untouched.
if [ "${CRITICAL:-0}" = "1" ]; then
  echo "▸ Marking v$VERSION as a CRITICAL update in the appcast…"
  perl -0pi -e "s{(\n\s*)(<enclosure[^>]*Verba-\Q$VERSION\E\.dmg)}{\$1<sparkle:criticalUpdate></sparkle:criticalUpdate>\$1\$2}" dist/appcast.xml
  grep -q "sparkle:criticalUpdate" dist/appcast.xml \
    || { echo "❌ CRITICAL requested but the <sparkle:criticalUpdate/> tag was not inserted (appcast layout changed?)" >&2; exit 1; }
  # The rewrite above is a regex edit on the file the whole installed base will parse. Re-check it.
  if command -v xmllint >/dev/null 2>&1; then
    xmllint --noout dist/appcast.xml \
      || { echo "❌ the CRITICAL rewrite produced malformed XML — refusing to publish." >&2; exit 1; }
  else
    python3 -c 'import sys,xml.dom.minidom as m; m.parse(sys.argv[1])' dist/appcast.xml \
      || { echo "❌ the CRITICAL rewrite produced malformed XML — refusing to publish." >&2; exit 1; }
  fi
fi

echo "▸ Publishing GitHub release v$VERSION on $REPO…"
# Upload: versioned DMG (referenced by the appcast), stable-named Verba.dmg
# (website latest-link), the appcast, and any Sparkle deltas this run produced.
#
# NEVER DELETE. The previous implementation ran `gh release delete --yes --cleanup-tag` first,
# "for idempotency". That destroyed a LIVE release users were downloading — irreversibly losing
# its download counts, its publication date, its notes and its tag — and it opened a window in
# which v$VERSION did not exist at all. Since SUFeedURL and the website both resolve through
# /releases/latest/download/, a failure inside that window (an expired token, a >2 GB asset 422,
# an evicted runner) left BOTH the update feed and every download button 404ing, permanently.
# `gh release upload --clobber` already gives full idempotency without deleting anything.
#
# New releases are staged as a DRAFT, so the assets are in place BEFORE the release becomes
# visible and before `latest` moves. There is no window in which `latest` points at a release
# with no appcast and no DMG.
PUBLISHED_STATE="$(gh release view "v$VERSION" --repo "$REPO" --json isDraft -q .isDraft 2>/dev/null || true)"
if [ -z "$PUBLISHED_STATE" ]; then
  echo "▸ Creating v$VERSION as a draft (assets first, publish last)…"
  gh release create "v$VERSION" --repo "$REPO" --title "Verba $VERSION" --generate-notes --draft
  WAS_DRAFT="true"
else
  echo "▸ v$VERSION already exists on $REPO (draft=$PUBLISHED_STATE) — reusing it, assets overwritten in place."
  WAS_DRAFT="$PUBLISHED_STATE"
fi

gh release upload "v$VERSION" \
  "Verba.dmg" "$DMG_VERSIONED" "dist/appcast.xml" ${DELTAS[@]+"${DELTAS[@]}"} \
  --repo "$REPO" --clobber

# ── Gate: every asset a user or a Sparkle client will ask for is actually attached ──
ASSETS="$(gh release view "v$VERSION" --repo "$REPO" --json assets -q '.assets[].name')"
for WANT in "Verba.dmg" "Verba-$VERSION.dmg" "appcast.xml"; do
  printf '%s\n' "$ASSETS" | grep -qx "$WANT" \
    || { echo "❌ asset '$WANT' is missing from release v$VERSION — refusing to publish it." >&2; exit 1; }
done
echo "▸ All required assets attached: Verba.dmg, Verba-$VERSION.dmg, appcast.xml"

if [ "$WAS_DRAFT" = "true" ]; then
  echo "▸ Assets verified — publishing the draft…"
  gh release edit "v$VERSION" --repo "$REPO" --draft=false
fi

# ── Gate: the URLs real users and real clients hit actually resolve, right now ──
# Everything above verified LOCAL artifacts. This verifies the PUBLISHED ones, through the exact
# /releases/latest/download/ paths that SUFeedURL (bundle.sh) and the website download button use.
# Without it, "✅ Released" was printed unconditionally and a half-published release looked green.
echo "▸ Verifying the published download URLs…"
LATEST_PUBLISHED="$(gh api "repos/$REPO/releases/latest" -q .tag_name 2>/dev/null || true)"
[ "$LATEST_PUBLISHED" = "v$VERSION" ] || {
  echo "❌ GitHub's 'latest' on $REPO is '$LATEST_PUBLISHED', not 'v$VERSION'." >&2
  echo "   SUFeedURL and the website download resolve through 'latest' — they would serve the wrong build." >&2
  exit 1; }

BASE_LATEST="https://github.com/$REPO/releases/latest/download"
for URL in "$BASE_LATEST/appcast.xml" "$BASE_LATEST/Verba.dmg" "${DOWNLOAD_PREFIX}Verba-$VERSION.dmg"; do
  curl -fsSL --retry 3 --retry-delay 5 -o /dev/null "$URL" \
    || { echo "❌ published URL is not downloadable: $URL" >&2; exit 1; }
  echo "   ✓ $URL"
done

# The feed clients will actually parse must advertise this version — same parser-based check as
# the local gate, run against the bytes GitHub actually serves through /releases/latest/.
PUBLISHED_APPCAST="$(mktemp "${TMPDIR:-/tmp}/verba-appcast.XXXXXX")"
trap 'rm -f "$PUBLISHED_APPCAST"' EXIT
curl -fsSL --retry 3 -o "$PUBLISHED_APPCAST" "$BASE_LATEST/appcast.xml" \
  || { echo "❌ could not re-download the published appcast for verification." >&2; exit 1; }
assert_appcast_advertises "$PUBLISHED_APPCAST" "$VERSION" "the published appcast ($BASE_LATEST/appcast.xml)"

echo "✅ Released v$VERSION — assets attached, 'latest' points here, and every public URL verified downloadable."
