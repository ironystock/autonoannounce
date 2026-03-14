# local-tts-queue v0.2 architecture notes

## Objectives
- Add first-run interactive setup.
- Persist durable earcons (no per-message regeneration).
- Support multiple earcon categories.
- Support cross-platform local playback backend selection.
- Keep enqueue path fast and non-blocking.

## Config schema (draft)
```json
{
  "voice": {
    "voiceId": "${ELEVENLABS_VOICE_ID:-}",
    "modelId": "${ELEVENLABS_MODEL_ID:-eleven_turbo_v2_5}"
  },
  "earcons": {
    "enabled": true,
    "categories": {
      "start": "audio/earcons/start.mp3",
      "end": "audio/earcons/end.mp3",
      "update": "audio/earcons/update.mp3",
      "important": "audio/earcons/important.mp3",
      "error": "audio/earcons/error.mp3"
    },
    "libraryPath": ".openclaw/earcon-library.json"
  },
  "playback": {
    "backend": "auto",
    "linux": ["mpv", "ffplay", "paplay"],
    "macos": ["afplay", "mpv"],
    "windows": ["powershell-soundplayer", "ffplay", "mpv"]
  }
}
```

## Runtime components
1. setup-first-run (interactive)
2. preflight (capability checks)
3. backend-detect (OS-aware)
4. worker (synth + playback)
5. earcon library manager (cache + metadata)

## Non-negotiables
- Producer stays enqueue-only.
- Earcons are generated once and reused.
- Playback backend resolved at startup and cached in config.
- Missing optional capability (e.g., SFX permission) must degrade gracefully.
