# Security and Data Flow (autonoannounce)

This document is intended to make installation and credential handling explicit for security review.

## 1) Credential handling

Credentials are consumed from environment variables:
- `ELEVENLABS_API_KEY`
- `ELEVENLABS_VOICE_ID` (optional but recommended)
- `ELEVENLABS_MODEL_ID` (optional)

The project does not require storing secrets in repository files.

## 2) Network transmission

Outbound network calls are made only when invoking ElevenLabs operations:
- text-to-speech generation
- sound effect generation
- preflight capability probes

Transmitted payloads are prompt text and request metadata required by ElevenLabs API.

## 3) Local data persistence

Local artifacts are written to workspace paths:
- queue/locks/logs: `.openclaw/`
- generated earcons: `audio/earcons/`
- config: `config/tts-queue.json`

No background sync or external exfiltration is performed by default.

## 4) Operational safeguards

- Atomic JSON writes for config/library updates.
- Locking for category-level earcon updates and shared library metadata updates.
- Bounded retry with backoff/jitter for transient API failures.
- Explicit terminal states in preflight output (`ok`, `rate_limited`, `forbidden_or_missing_permission`, `upstream_error`, `unavailable`).

## 5) Recommended install hygiene

- Set credentials in shell profile or secrets manager, not repo files.
- Restrict API key scope to required capabilities.
- Rotate keys periodically.
- Validate setup with:
  - `skills/autonoannounce/scripts/test-v0.2.sh`
  - `skills/autonoannounce/scripts/elevenlabs-preflight.sh`
