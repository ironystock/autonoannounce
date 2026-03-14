# autonoannounce

Automation-first workspace for Autonoannounce skill development.

## What this repo includes
- Base project scaffold for remote skill work
- Standard open-source metadata (MIT license, contribution guide, gitignore)
- Ready-to-extend structure for skill authoring and testing

## Install

### Option A: clone repository (recommended for contributors)
```bash
git clone https://github.com/snowcrab-dev/autonoannounce.git
cd autonoannounce
```

### Option B: skill-only usage
Use the `skills/autonoannounce/` folder directly inside an OpenClaw workspace.

## Credential and transmission clarity

### Required credentials
- `ELEVENLABS_API_KEY` (required for TTS/SFX API calls)
- `ELEVENLABS_VOICE_ID` (recommended)
- `ELEVENLABS_MODEL_ID` (optional override)

### Where credentials are read
- Environment variables only (runtime process env)
- Never committed to git by design

### What is transmitted off-machine
- Text prompts sent to ElevenLabs endpoints when running synthesis/preflight/SFX generation.
- No automatic upload of local files unless explicitly generated and sent via selected API path.

### What stays local
- Queue files/logs under `.openclaw/`
- Earcon audio assets under `audio/earcons/`
- Playback occurs on local machine via selected backend

### Security posture notes
- Local playback policy can avoid Discord/media attachment fallback for protected users.
- Concurrency controls + atomic writes are implemented for config/earcon metadata updates.
- Preflight returns explicit fallback guidance when SFX permissions/rate limits fail.

## Development
- Add skills under `skills/`
- Add docs under `docs/`
- Keep scripts in `scripts/`

## Current plan
- See `docs/PLAN.md` for active scope and milestones.

## Quickstart (autonoannounce)
```bash
cd skills/autonoannounce
./scripts/benchmark-autonoannounce.sh 5
```

## First-run setup examples
Python CLI (recommended):
```bash
python3 skills/autonoannounce/scripts/setup_first_run.py
```

Noninteractive (CI/bootstrap):
```bash
python3 skills/autonoannounce/scripts/setup_first_run.py \
  --noninteractive \
  --earcons y \
  --style "subtle chime" \
  --backend auto \
  --device "" \
  --generate-starters n
```

Shell wrapper (compatibility):
```bash
skills/autonoannounce/scripts/setup-first-run.sh --noninteractive --dry-run
```

## Validation commands
```bash
skills/autonoannounce/scripts/test-v0.2.sh
skills/autonoannounce/scripts/elevenlabs-preflight.sh
skills/autonoannounce/scripts/race-stress.sh
```

## Security review reference
- See `docs/SECURITY.md` for credential handling, transmission model, and safeguards.

## License
MIT
