#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
CFG="$ROOT/config/tts-queue.json"
EARCON_DIR="$ROOT/audio/earcons"

mkdir -p "$EARCON_DIR" "$(dirname "$CFG")"

NONINTERACTIVE=0
DRY_RUN=0
EARCONS=""
STYLE=""
VOICE_ID="${ELEVENLABS_VOICE_ID:-}"
BACKEND=""
GENERATE_STARTERS=""

usage() {
  cat <<'EOF'
Usage: setup-first-run.sh [options]

Options:
  --noninteractive            Do not prompt; use provided flags/defaults
  --dry-run                   Print resulting config JSON without writing
  --earcons y|n               Enable earcons
  --style "text"              Earcon style direction
  --voice-id "id"             ElevenLabs voice id
  --backend "name"            Playback backend (or auto)
  --generate-starters y|n     Generate starter earcons now
  -h, --help                  Show help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --noninteractive) NONINTERACTIVE=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --earcons) EARCONS="${2:-}"; shift 2 ;;
    --style) STYLE="${2:-}"; shift 2 ;;
    --voice-id) VOICE_ID="${2:-}"; shift 2 ;;
    --backend) BACKEND="${2:-}"; shift 2 ;;
    --generate-starters) GENERATE_STARTERS="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage >&2; exit 2 ;;
  esac
done

def_backend="$($ROOT/skills/local-tts-queue/scripts/backend-detect.sh || true)"
def_backend=${def_backend:-auto}

if [[ $NONINTERACTIVE -eq 0 ]]; then
  echo "== local-tts-queue first run setup =="

  if [[ -z "$EARCONS" ]]; then
    read -r -p "Enable earcons? (y/n) [y]: " EARCONS
    EARCONS=${EARCONS:-y}
  fi

  if [[ -z "$STYLE" ]]; then
    read -r -p "Earcon style direction (e.g. subtle chime, arena horn): " STYLE
    STYLE=${STYLE:-"subtle chime"}
  fi

  if [[ -z "$VOICE_ID" ]]; then
    read -r -p "Do you already have an ElevenLabs voice ID? (y/n) [n]: " has_voice
    has_voice=${has_voice:-n}
    if [[ "$has_voice" =~ ^[Yy]$ ]]; then
      read -r -p "Enter voice ID: " VOICE_ID
    fi
  fi

  if [[ -z "$BACKEND" ]]; then
    read -r -p "Playback backend [$def_backend]: " backend_in
    BACKEND=${backend_in:-$def_backend}
  fi

  if [[ -z "$GENERATE_STARTERS" && "$EARCONS" =~ ^[Yy]$ ]]; then
    read -r -p "Generate starter earcons now? (y/n) [y]: " GENERATE_STARTERS
    GENERATE_STARTERS=${GENERATE_STARTERS:-y}
  fi
else
  EARCONS=${EARCONS:-y}
  STYLE=${STYLE:-"subtle chime"}
  BACKEND=${BACKEND:-$def_backend}
  if [[ "$EARCONS" =~ ^[Yy]$ ]]; then
    GENERATE_STARTERS=${GENERATE_STARTERS:-n}
  else
    GENERATE_STARTERS=n
  fi
fi

EARCONS=${EARCONS:-y}
STYLE=${STYLE:-"subtle chime"}
BACKEND=${BACKEND:-$def_backend}
GENERATE_STARTERS=${GENERATE_STARTERS:-n}

CONFIG_JSON=$(cat <<EOF
{
  "queueFile": "$ROOT/.openclaw/tts-queue.jsonl",
  "lockFile": "$ROOT/.openclaw/tts-queue.lock",
  "logFile": "$ROOT/.openclaw/tts-queue.log",
  "voice": {
    "voiceId": "${VOICE_ID}",
    "modelId": "${ELEVENLABS_MODEL_ID:-eleven_turbo_v2_5}"
  },
  "earcons": {
    "enabled": $([[ "$EARCONS" =~ ^[Yy]$ ]] && echo true || echo false),
    "style": "${STYLE}",
    "categories": {
      "start": "",
      "end": "",
      "update": "",
      "important": "",
      "error": ""
    },
    "libraryPath": "$ROOT/.openclaw/earcon-library.json"
  },
  "playback": {
    "backend": "${BACKEND}"
  }
}
EOF
)

if [[ $DRY_RUN -eq 1 ]]; then
  echo "$CONFIG_JSON"
  exit 0
fi

printf '%s\n' "$CONFIG_JSON" > "$CFG"

echo "Wrote $CFG"
echo "Next: run skills/local-tts-queue/scripts/elevenlabs-preflight.sh"

if [[ "$EARCONS" =~ ^[Yy]$ && "$GENERATE_STARTERS" =~ ^[Yy]$ ]]; then
  for cat in start end update important error; do
    "$ROOT/skills/local-tts-queue/scripts/earcon-library.sh" generate "$cat" "${STYLE} ${cat} notification sound" 1 || true
  done
  echo "Starter earcons generated (where API/key permits)."
fi
