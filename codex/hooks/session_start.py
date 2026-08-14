#!/usr/bin/env python3
"""Adapt the shared text SessionStart hook to Codex hook JSON."""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path


def main() -> int:
    hook = Path(__file__).with_name("coding-agent-workflow-session-start.sh")
    result = subprocess.run(
        ["bash", str(hook)],
        input=sys.stdin.buffer.read(),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if result.stderr:
        sys.stderr.buffer.write(result.stderr)
    output = result.stdout.decode("utf-8", errors="replace").strip()
    if output:
        payload = {
            "hookSpecificOutput": {
                "hookEventName": "SessionStart",
                "additionalContext": output,
            }
        }
        print(json.dumps(payload, ensure_ascii=False))
    return result.returncode


if __name__ == "__main__":
    raise SystemExit(main())
