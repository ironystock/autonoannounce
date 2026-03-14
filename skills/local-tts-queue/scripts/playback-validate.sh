#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
CFG="$ROOT/config/tts-queue.json"
BACKEND="${1:-}"

if [[ -z "$BACKEND" && -f "$CFG" ]]; then
  BACKEND=$(python3 - "$CFG" <<'PY'
import json,sys
try:
  c=json.load(open(sys.argv[1]))
  print(c.get('playback',{}).get('backend','auto'))
except Exception:
  print('auto')
PY
)
fi

if [[ -z "$BACKEND" || "$BACKEND" == "auto" ]]; then
  BACKEND="$($ROOT/skills/local-tts-queue/scripts/backend-detect.sh || true)"
fi

ok=true
reason=""

case "$BACKEND" in
  mpv|ffplay|paplay|afplay)
    if ! command -v "$BACKEND" >/dev/null 2>&1; then
      ok=false; reason="backend_binary_missing"
    fi
    ;;
  powershell-soundplayer)
    if ! command -v powershell >/dev/null 2>&1 && ! command -v pwsh >/dev/null 2>&1; then
      ok=false; reason="powershell_missing"
    fi
    ;;
  none|"")
    ok=false; reason="no_backend_detected"
    ;;
  *)
    if ! command -v "$BACKEND" >/dev/null 2>&1; then
      ok=false; reason="custom_backend_missing"
    fi
    ;;
esac

cat <<EOF
{"ok":$ok,"backend":"$BACKEND","reason":"$reason"}
EOF

$ok || exit 1
