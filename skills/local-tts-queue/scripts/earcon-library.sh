#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
CFG="$ROOT/config/tts-queue.json"
EARCON_DIR="$ROOT/audio/earcons"

usage() {
  cat <<'EOF'
Usage:
  earcon-library.sh init
  earcon-library.sh list
  earcon-library.sh missing
  earcon-library.sh generate <category> [prompt] [duration_seconds]

Categories: start | end | update | important | error
Notes:
- Requires config/tts-queue.json (create via setup-first-run.sh)
- Requires ELEVENLABS_API_KEY for generate
EOF
}

[[ $# -ge 1 ]] || { usage; exit 2; }
cmd="$1"; shift

[[ -f "$CFG" ]] || { echo "missing config: $CFG" >&2; exit 1; }
mkdir -p "$EARCON_DIR" "$ROOT/.openclaw"

read_cfg() {
  python3 - "$CFG" <<'PY'
import json,sys
cfg=json.load(open(sys.argv[1]))
ear=cfg.setdefault('earcons',{})
ear.setdefault('libraryPath','.openclaw/earcon-library.json')
ear.setdefault('categories',{})
print(ear['libraryPath'])
for k in ('start','end','update','important','error'):
    print(ear['categories'].get(k,''))
PY
}

mapfile -t cfgvals < <(read_cfg)
LIB_PATH_RAW="${cfgvals[0]}"
if [[ "$LIB_PATH_RAW" = /* ]]; then
  LIB_PATH="$LIB_PATH_RAW"
else
  LIB_PATH="$ROOT/$LIB_PATH_RAW"
fi

ensure_lib() {
  [[ -f "$LIB_PATH" ]] || echo '{"version":1,"earcons":{}}' > "$LIB_PATH"
}

ensure_lib

case "$cmd" in
  init)
    echo "initialized library: $LIB_PATH"
    ;;
  list)
    python3 - "$LIB_PATH" <<'PY'
import json,sys
lib=json.load(open(sys.argv[1]))
for k,v in lib.get('earcons',{}).items():
    print(f"{k}\t{v.get('path','')}\t{v.get('created_at','')}")
PY
    ;;
  missing)
    python3 - "$CFG" <<'PY'
import json,sys
cfg=json.load(open(sys.argv[1]))
cats=cfg.get('earcons',{}).get('categories',{})
need=['start','end','update','important','error']
missing=[c for c in need if not cats.get(c)]
print('\n'.join(missing))
PY
    ;;
  generate)
    [[ $# -ge 1 ]] || { usage; exit 2; }
    category="$1"; shift
    prompt="${1:-}"
    duration="${2:-1}"
    case "$category" in start|end|update|important|error) ;; *) echo "invalid category: $category" >&2; exit 2;; esac
    [[ -n "${ELEVENLABS_API_KEY:-}" ]] || { echo "missing ELEVENLABS_API_KEY" >&2; exit 1; }

    if [[ -z "$prompt" ]]; then
      case "$category" in
        start) prompt="subtle startup notification chime, short and clean";;
        end) prompt="soft completion chime, gentle resolve";;
        update) prompt="brief status update blip, modern UI sound";;
        important) prompt="attention notification tone, clear and confident";;
        error) prompt="short error alert tone, distinct but not harsh";;
      esac
    fi

    ts=$(date +%s)
    out="$EARCON_DIR/${category}-${ts}.mp3"
    code=$(curl -sS -o "$out" -w '%{http_code}' -X POST "https://api.elevenlabs.io/v1/sound-generation" \
      -H "xi-api-key: ${ELEVENLABS_API_KEY}" \
      -H 'Content-Type: application/json' \
      -d "{\"text\":\"$prompt\",\"duration_seconds\":$duration}")

    if [[ "$code" != "200" ]]; then
      echo "generation failed http=$code" >&2
      head -c 240 "$out" || true
      exit 1
    fi

    sha=$(sha256sum "$out" | awk '{print $1}')
    model="${ELEVENLABS_MODEL_ID:-eleven_text_to_sound_v2}"
    created=$(date -Iseconds)

    python3 - "$CFG" "$LIB_PATH" "$category" "$out" "$prompt" "$model" "$duration" "$sha" "$created" <<'PY'
import json,sys
cfgp,libp,cat,path,prompt,model,dur,sha,created=sys.argv[1:]
cfg=json.load(open(cfgp))
ear=cfg.setdefault('earcons',{})
ear.setdefault('categories',{})
ear['categories'][cat]=path
json.dump(cfg,open(cfgp,'w'),indent=2)

lib=json.load(open(libp))
lib.setdefault('version',1)
lib.setdefault('earcons',{})
lib['earcons'][cat]={
  'path':path,
  'prompt':prompt,
  'model':model,
  'duration_seconds':float(dur),
  'sha256':sha,
  'created_at':created
}
json.dump(lib,open(libp,'w'),indent=2)
PY
    echo "generated $category -> $out"
    ;;
  *)
    usage
    exit 2
    ;;
esac
