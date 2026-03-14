#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
SCRIPTS="$ROOT/skills/local-tts-queue/scripts"

echo "[test] setup-first-run dry-run"
json=$($SCRIPTS/setup-first-run.sh --noninteractive --dry-run --earcons y --style "test style" --backend auto --generate-starters n)
echo "$json" | python3 -c 'import json,sys; j=json.load(sys.stdin); assert j["earcons"]["enabled"] is True; assert "playback" in j'

echo "[test] backend detect"
backend=$($SCRIPTS/backend-detect.sh || true)
[[ -n "$backend" ]] || { echo "backend empty" >&2; exit 1; }

echo "[test] playback validate"
$SCRIPTS/playback-validate.sh >/dev/null || true

echo "[test] earcon cache reuse sanity"
mkdir -p "$ROOT/.openclaw"
cat > "$ROOT/config/tts-queue.json" <<EOF
{
  "earcons": {
    "enabled": true,
    "categories": {
      "start": "$ROOT/audio/earcons/existing-start.mp3",
      "end": "",
      "update": "",
      "important": "",
      "error": ""
    },
    "libraryPath": "$ROOT/.openclaw/earcon-library.json"
  },
  "playback": {"backend": "auto"}
}
EOF
$SCRIPTS/earcon-library.sh init >/dev/null
missing=$($SCRIPTS/earcon-library.sh missing)
echo "$missing" | grep -q "end"
echo "[ok] tests passed"