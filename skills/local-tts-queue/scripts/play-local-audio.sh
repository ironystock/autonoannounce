#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
CFG="$ROOT/config/tts-queue.json"
BACKEND=""
FILE=""

usage() {
  echo "Usage: play-local-audio.sh <audio-file> [--backend name]"
}

[[ $# -ge 1 ]] || { usage; exit 2; }
FILE="$1"; shift

while [[ $# -gt 0 ]]; do
  case "$1" in
    --backend) BACKEND="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ -f "$FILE" ]] || { echo "missing audio file: $FILE" >&2; exit 1; }

if [[ -z "$BACKEND" && -f "$CFG" ]]; then
  BACKEND=$(python3 - "$CFG" <<'PY'
import json,sys
try:
  c=json.load(open(sys.argv[1]))
  print(c.get('playback',{}).get('backend',''))
except Exception:
  print('')
PY
)
fi

if [[ -z "$BACKEND" || "$BACKEND" == "auto" ]]; then
  BACKEND="$($ROOT/skills/local-tts-queue/scripts/backend-detect.sh || echo none)"
fi

case "$BACKEND" in
  mpv)
    exec mpv --no-terminal --really-quiet "$FILE"
    ;;
  ffplay)
    exec ffplay -nodisp -autoexit -loglevel error "$FILE"
    ;;
  paplay)
    exec paplay "$FILE"
    ;;
  afplay)
    exec afplay "$FILE"
    ;;
  powershell-soundplayer)
    exec powershell -NoProfile -Command "(New-Object Media.SoundPlayer '$FILE').PlaySync();"
    ;;
  none|"")
    echo "no playback backend available" >&2
    exit 1
    ;;
  *)
    if command -v "$BACKEND" >/dev/null 2>&1; then
      exec "$BACKEND" "$FILE"
    fi
    echo "unknown/unavailable backend: $BACKEND" >&2
    exit 1
    ;;
esac
