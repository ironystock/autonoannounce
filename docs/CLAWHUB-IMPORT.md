# ClawHub Import Mapping (autonoannounce)

Use this file as a quick reference during manual import.

## Canonical files
- Skill entrypoint: `skills/autonoannounce/SKILL.md`
- Registry metadata helper: `.clawhub/registry-metadata.json`

## Suggested field mapping
- Name: `autonoannounce`
- Description: from `.clawhub/registry-metadata.json` or SKILL frontmatter
- Env vars (preferred shape): `env.required` / `env.optional`
  - Required env vars: `ELEVENLABS_API_KEY`
  - Optional env vars: `ELEVENLABS_VOICE_ID`, `ELEVENLABS_MODEL_ID`
- Legacy compatibility keys also present: `requiredEnv` / `optionalEnv`
- Outbound domains: `api.elevenlabs.io`
- Local writes:
  - `config/tts-queue.json`
  - `.openclaw/*`
  - `audio/earcons/*`

## Security disclosure summary
- Credentials are read from environment variables.
- Network calls are made to ElevenLabs API for synthesis/preflight.
- Queue/config/audio artifacts remain local by default.

## Notes
- Some ClawHub import flows still require manual confirmation of registry fields.
- Keep SKILL frontmatter and `.clawhub/registry-metadata.json` synchronized when updating requirements.
