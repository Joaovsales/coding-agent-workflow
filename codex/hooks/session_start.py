#!/usr/bin/env python3
"""Adapt the shared text SessionStart hook to Codex hook JSON."""

from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path


def main() -> int:
    hook = Path(__file__).with_name("coding-agent-workflow-session-start.sh")
    # Codex registers this hook exactly once, so the shared script's
    # double-invocation guard has nothing to de-duplicate here. Leaving it on is
    # not merely redundant: the guard keys on the working directory whenever the
    # payload carries no session_id, and Codex's payload is not known to carry
    # one -- so a second Codex session in the same repo inside the guard's
    # freshness window would be silently suppressed and emit no banner at all.
    env = {**os.environ, "CCW_SESSION_GUARD": "0"}
    result = subprocess.run(
        ["bash", str(hook)],
        input=sys.stdin.buffer.read(),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        env=env,
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
