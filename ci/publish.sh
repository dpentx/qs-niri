#!/usr/bin/env bash
# Pushes ci/out to the orphan branch `ci-screenshots` (force-pushed, so it only
# ever holds the latest run). Reading the images from a git branch works from
# anywhere, including places that cannot download Actions artifacts.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$SRC/ci/out"
mkdir -p "$OUT"

AUTH="$(git -C "$SRC" config --local --get http.https://github.com/.extraheader || true)"
SHA="$(git -C "$SRC" rev-parse --short HEAD)"

TMP="$(mktemp -d)"
cp -r "$OUT"/. "$TMP"/
# Raw output of the capture step (nix errors etc. that happen before the
# script itself starts); this is how failures can be read without log access.
if [ -n "${CAPTURE_LOG:-}" ] && [ -f "$CAPTURE_LOG" ]; then
  tail -n 600 "$CAPTURE_LOG" >"$TMP/capture.log"
fi
cat >"$TMP/meta.txt" <<EOF
commit:  $(git -C "$SRC" rev-parse HEAD)
branch:  ${GITHUB_REF_NAME:-local}
run:     ${GITHUB_SERVER_URL:-}/${GITHUB_REPOSITORY:-}/actions/runs/${GITHUB_RUN_ID:-}
time:    $(date -u +%FT%TZ)
capture: ${CAPTURE_OUTCOME:-unknown}
EOF

cd "$TMP"
git init -q -b ci-screenshots
git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git add -A
git commit -q -m "UI screenshots for $SHA (${GITHUB_REF_NAME:-local})"
git -c "http.https://github.com/.extraheader=$AUTH" \
  push -q -f "https://github.com/${GITHUB_REPOSITORY}.git" ci-screenshots:ci-screenshots
echo "published to ci-screenshots"
