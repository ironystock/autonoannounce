#!/usr/bin/env bash
set -euo pipefail

BASE="https://api.elevenlabs.io"
KEY="${ELEVENLABS_API_KEY:-}"
VOICE="${ELEVENLABS_VOICE_ID:-}"
MODEL="${ELEVENLABS_MODEL_ID:-}"

if [[ -z "$KEY" ]]; then
  echo '{"ok":false,"error":"missing ELEVENLABS_API_KEY"}'
  exit 1
fi

h=(-H "xi-api-key: $KEY" -H 'accept: application/json')

probe_get(){
  local ep="$1"
  local code
  code=$(curl -sS -o /tmp/el_preflight.json -w '%{http_code}' "${h[@]}" "$BASE$ep")
  echo "$code"
}

models_code=$(probe_get /v1/models)
user_code=$(probe_get /v1/user/subscription)
voice_code="unset"
if [[ -n "$VOICE" ]]; then
  voice_code=$(probe_get "/v1/voices/$VOICE")
fi

sfx_code=$(curl -sS -o /tmp/el_sfx_pf.json -w '%{http_code}' -X POST "$BASE/v1/sound-generation" \
  -H "xi-api-key: $KEY" -H 'Content-Type: application/json' \
  -d '{"text":"short system chime","duration_seconds":1}')

ok=true
[[ "$models_code" == "200" ]] || ok=false
[[ "$user_code" == "200" ]] || ok=false
if [[ -n "$VOICE" && "$voice_code" != "200" ]]; then ok=false; fi

cat <<EOF
{"ok":$ok,"models_http":$models_code,"subscription_http":$user_code,"voice_http":"$voice_code","sfx_http":$sfx_code,"model_env_set":$([[ -n "$MODEL" ]] && echo true || echo false)}
EOF
