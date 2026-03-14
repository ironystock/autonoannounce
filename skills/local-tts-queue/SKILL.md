---
name: local-tts-queue
description: Build, operate, and troubleshoot local speaker text-to-speech using the queued pipeline (enqueue to worker to ElevenLabs to mpv). Use when creating or improving low-latency fire-and-forget TTS flows, tuning burst behavior, validating queue performance, enforcing local-only speech policy, or debugging queue/worker playback failures.
---

# Local TTS Queue

## Overview
Use this skill to keep local speech fast, reliable, and policy-compliant by treating enqueue as fire-and-forget and isolating synthesis/playback inside the queue worker.

## Quick start workflow
1. Confirm queue health with `scripts/tts-queue-status.sh`.
2. Enqueue speech with `scripts/speak-local-queued.sh "text"`.
3. If audio does not play, inspect worker logs and runbook steps in `references/runbook.md`.
4. For latency tuning, run `scripts/benchmark-local-tts-queue.sh` and compare against SLOs in `references/perf-slos.md`.

## Operating rules
- Keep the producer path non-blocking: enqueue then return immediately.
- Keep synthesis/playback in worker-only execution paths.
- Prefer fewer larger writes to the queue (coalesce bursty traffic when possible).
- Use policy-safe output lanes: local speaker for protected users; no Discord voice-file fallback.
- Treat one failed item as isolated: retry with bounds, then dead-letter; do not stall entire queue.

## Commands
- Enqueue: `scripts/speak-local-queued.sh "<text>"`
- Worker (foreground): `scripts/tts-queue-worker.sh`
- Worker daemon: `scripts/tts-queue-daemon.sh`
- Status: `scripts/tts-queue-status.sh`
- Benchmark harness: `scripts/benchmark-local-tts-queue.sh`
  - Fast foreground benchmark: `scripts/benchmark-local-tts-queue.sh 5`
  - Full diagnostic benchmark: `scripts/benchmark-local-tts-queue.sh 5 --status both --output full`
- First-run interactive setup: `skills/local-tts-queue/scripts/setup-first-run.sh`
- Backend detection (OS-aware): `skills/local-tts-queue/scripts/backend-detect.sh`
- ElevenLabs capability preflight: `skills/local-tts-queue/scripts/elevenlabs-preflight.sh`

## References map
- Runbook: `references/runbook.md`
- Config contract: `references/config-contract.md`
- Performance SLOs and interpretation: `references/perf-slos.md`
- Foreground-latency optimization: `references/front-path-optimization.md`

## Execution checklist
- Verify prerequisites (`ELEVENLABS_API_KEY`, `ELEVENLABS_VOICE_ID`, `mpv`).
- Validate queue paths and lock behavior before tuning performance.
- Measure baseline before making queue/worker changes.
- Re-run benchmark after each material change.
- Record final p50/p95 latency and queue-wait deltas in the task summary.
