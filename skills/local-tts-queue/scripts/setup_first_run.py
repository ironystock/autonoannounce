#!/usr/bin/env python3
import argparse
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
CFG = ROOT / "config" / "tts-queue.json"


def detect_backend() -> str:
    script = ROOT / "skills" / "local-tts-queue" / "scripts" / "backend-detect.sh"
    try:
        out = subprocess.check_output([str(script)], text=True).strip()
        return out or "auto"
    except Exception:
        return "auto"


def prompt(msg: str, default: str) -> str:
    v = input(f"{msg} [{default}]: ").strip()
    return v or default


def atomic_write_json(path: Path, data: dict):
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile("w", dir=path.parent, delete=False) as tf:
        json.dump(data, tf, indent=2)
        tf.write("\n")
        tmp = Path(tf.name)
    os.replace(tmp, path)


def main():
    p = argparse.ArgumentParser(description="local-tts-queue first run setup")
    p.add_argument("--noninteractive", action="store_true")
    p.add_argument("--dry-run", action="store_true")
    p.add_argument("--earcons", choices=["y", "n"], default=None)
    p.add_argument("--style", default=None)
    p.add_argument("--voice-id", default=os.environ.get("ELEVENLABS_VOICE_ID", ""))
    p.add_argument("--backend", default=None)
    p.add_argument("--generate-starters", choices=["y", "n"], default=None)
    args = p.parse_args()

    backend_default = detect_backend()
    earcons = args.earcons
    style = args.style
    voice_id = args.voice_id
    backend = args.backend
    generate = args.generate_starters

    if not args.noninteractive:
        print("== local-tts-queue first run setup (python) ==")
        earcons = earcons or prompt("Enable earcons? (y/n)", "y")
        style = style or prompt("Earcon style direction", "subtle chime")
        if not voice_id:
            has = prompt("Do you already have an ElevenLabs voice ID? (y/n)", "n")
            if has.lower().startswith("y"):
                voice_id = input("Enter voice ID: ").strip()
        backend = backend or prompt("Playback backend", backend_default)
        if earcons.lower().startswith("y"):
            generate = generate or prompt("Generate starter earcons now? (y/n)", "y")
    else:
        earcons = earcons or "y"
        style = style or "subtle chime"
        backend = backend or backend_default
        if earcons.lower().startswith("y"):
            generate = generate or "n"
        else:
            generate = "n"

    cfg = {
        "queueFile": str(ROOT / ".openclaw" / "tts-queue.jsonl"),
        "lockFile": str(ROOT / ".openclaw" / "tts-queue.lock"),
        "logFile": str(ROOT / ".openclaw" / "tts-queue.log"),
        "voice": {
            "voiceId": voice_id,
            "modelId": os.environ.get("ELEVENLABS_MODEL_ID", "eleven_turbo_v2_5"),
        },
        "earcons": {
            "enabled": earcons.lower().startswith("y"),
            "style": style,
            "categories": {"start": "", "end": "", "update": "", "important": "", "error": ""},
            "libraryPath": str(ROOT / ".openclaw" / "earcon-library.json"),
        },
        "playback": {"backend": backend},
    }

    if args.dry_run:
        print(json.dumps(cfg, indent=2))
        return 0

    atomic_write_json(CFG, cfg)
    print(f"Wrote {CFG}")
    print("Next: run skills/local-tts-queue/scripts/elevenlabs-preflight.sh")

    if cfg["earcons"]["enabled"] and generate and generate.lower().startswith("y"):
        gen_script = ROOT / "skills" / "local-tts-queue" / "scripts" / "earcon-library.sh"
        for cat in ["start", "end", "update", "important", "error"]:
            subprocess.call([str(gen_script), "generate", cat, f"{style} {cat} notification sound", "1"])
        print("Starter earcons generated (where API/key permits).")

    return 0


if __name__ == "__main__":
    sys.exit(main())
