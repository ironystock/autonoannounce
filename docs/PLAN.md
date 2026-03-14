# Autonoannounce Plan

## Goal
Ship a production-usable local TTS queue skill with measurable foreground speed, clear operations docs, and a friendly first-run setup flow.

## v0.1 (current baseline)
1. Baseline skill in repo (`skills/autonoannounce`) with benchmark harness and references.
2. Fast foreground benchmark mode (default compact/no-status).
3. Full diagnostic mode for deep troubleshooting.
4. Runbook + config contract + perf SLO docs.
5. Initial GitHub project hygiene (milestone, issues, branch protection).

## v0.2 (next: onboarding + personalization)
1. **Interactive first-run setup**
   - Launch guided setup wizard on first install/run.
   - Ask whether earcons should be enabled.
   - Ask for earcon style direction (examples + freeform prompt hints).
   - Ask whether user has a preferred voice ID; if not, guide voice discovery/preview.
2. **Durable earcon library**
   - Generate earcons once and cache to disk (no per-message regeneration).
   - Persist metadata (prompt, model, duration, created_at, category, hash).
   - Reuse existing assets unless user explicitly regenerates.
3. **Multi-earcon taxonomy (future-safe)**
   - Support categories from day one:
     - `start`
     - `end`
     - `update`
     - `important`
     - `error`
   - Keep schema extensible for custom categories.
4. **Voice selection workflow**
   - If `voiceId` missing: list available voices, preview samples, pick one.
   - Store selection durably in local config.
   - Allow per-context override later (optional).
5. **Local playback backend selection (cross-platform)**
   - Let user choose playback app/backend at setup.
   - Backend abstraction with OS-aware defaults:
     - Linux: `mpv` (fallback `ffplay`, `paplay`)
     - macOS: `afplay` (fallback `mpv`)
     - Windows: PowerShell `Media.SoundPlayer` or `ffplay`/`mpv`
   - Persist backend choice in config and validate on startup.

## v0.3 (hardening)
1. Capability preflight (`key`, `voice`, `model`, `sfx` availability) with concise status output.
2. SFX generation retries/backoff + fallback to local cached WAV/MP3 earcons.
3. Better migration flow for config schema upgrades.

## Non-goals (for now)
- Full queue architecture refactor (coalescing/priority/TTL/prefetch)
- Multi-host playback orchestration
- Rich dashboarding/observability UI

## Definition of Done (for v0.2)
- First-run wizard works end-to-end on fresh install.
- User can select earcons on/off, style direction, and voice.
- Earcons are generated once and reused durably.
- Multiple earcon categories are configurable and testable.
- Playback backend can be selected and validated on Linux/macOS/Windows paths.
