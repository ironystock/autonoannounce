#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
CFG="$ROOT/config/tts-queue.json"
EARCON_DIR="$ROOT/audio/earcons"

mkdir -p "$EARCON_DIR" "$(dirname "$CFG")"

echo "== local-tts-queue first run setup =="
read -r -p "Enable earcons? (y/n) [y]: " earcons
earcons=${earcons:-y}

read -r -p "Earcon style direction (e.g. subtle chime, arena horn): " style
style=${style:-"subtle chime"}

read -r -p "Do you already have an ElevenLabs voice ID? (y/n) [n]: " has_voice
has_voice=${has_voice:-n}
voice_id="${ELEVENLABS_VOICE_ID:-}"
if [[ "$has_voice" =~ ^[Yy]$ ]]; then
  read -r -p "Enter voice ID: " voice_id
fi

backend=$("$ROOT/skills/local-tts-queue/scripts/backend-detect.sh" || true)
backend=${backend:-auto}
read -r -p "Playback backend [$backend]: " backend_in
backend=${backend_in:-$backend}

cat > "$CFG" <<EOF
{
  "queueFile": "$ROOT/.openclaw/tts-queue.jsonl",
  "lockFile": "$ROOT/.openclaw/tts-queue.lock",
  "logFile": "$ROOT/.openclaw/tts-queue.log",
  "voice": {
    "voiceId": "${voice_id}",
    "modelId": "${ELEVENLABS_MODEL_ID:-eleven_turbo_v2_5}"
  },
  "earcons": {
    "enabled": $([[ "$earcons" =~ ^[Yy]$ ]] && echo true || echo false),
    "style": "${style}",
    "categories": {
      "start": "$EARCON_DIR/start.mp3",
      "end": "$EARCON_DIR/end.mp3",
      "update": "$EARCON_DIR/update.mp3",
      "important": "$EARCON_DIR/important.mp3",
      "error": "$EARCON_DIR/error.mp3"
    },
    "libraryPath": "$ROOT/.openclaw/earcon-library.json"
  },
  "playback": {
    "backend": "${backend}"
  }
}
EOF

echo "Wrote $CFG"
echo "Next: run skills/local-tts-queue/scripts/elevenlabs-preflight.sh"
