# autonoannounce

Automation-first workspace for Autonoannounce skill development.

## What this repo includes
- Base project scaffold for remote skill work
- Standard open-source metadata (MIT license, contribution guide, gitignore)
- Ready-to-extend structure for skill authoring and testing

## Quick start
```bash
git clone https://github.com/snowcrab-dev/autonoannounce.git
cd autonoannounce
```

## Development
- Add skills under `skills/`
- Add docs under `docs/`
- Keep scripts in `scripts/`

## Current plan
- See `docs/PLAN.md` for active scope and milestones.

## Quickstart (local-tts-queue)
```bash
cd skills/local-tts-queue
./scripts/benchmark-local-tts-queue.sh 5
```

## First-run setup examples
Python CLI (recommended):
```bash
python3 skills/local-tts-queue/scripts/setup_first_run.py
```

Noninteractive (CI/bootstrap):
```bash
python3 skills/local-tts-queue/scripts/setup_first_run.py \
  --noninteractive \
  --earcons y \
  --style "subtle chime" \
  --backend auto \
  --device "" \
  --generate-starters n
```

Shell wrapper (compatibility):
```bash
skills/local-tts-queue/scripts/setup-first-run.sh --noninteractive --dry-run
```

## Validation commands
```bash
skills/local-tts-queue/scripts/test-v0.2.sh
skills/local-tts-queue/scripts/elevenlabs-preflight.sh
skills/local-tts-queue/scripts/race-stress.sh
```

## License
MIT
