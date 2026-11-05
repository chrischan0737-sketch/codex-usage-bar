#!/usr/bin/env python3
"""Read the active Codex account's quota through the local app-server protocol."""

import json
import os
import select
import shutil
import subprocess
import sys
import time


def codex_binary():
    candidates = [
        "/Applications/ChatGPT.app/Contents/Resources/codex-cli/CodexCLI.app/Contents/MacOS/codex",
        "/opt/homebrew/bin/codex",
        "/usr/local/bin/codex",
        shutil.which("codex"),
    ]
    for candidate in candidates:
        if candidate and os.path.isfile(candidate) and os.access(candidate, os.X_OK):
            return candidate
    raise RuntimeError("找不到 Codex CLI")


def read_usage():
    process = subprocess.Popen(
        [codex_binary(), "app-server", "--stdio"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
        bufsize=1,
    )
    try:
        requests = [
            {"id": 1, "method": "initialize", "params": {
                "clientInfo": {"name": "codex-usage-bar", "title": "Codex Usage Bar", "version": "1.0"},
                "capabilities": None,
            }},
            {"method": "initialized", "params": {}},
            {"id": 2, "method": "account/rateLimits/read", "params": {
                "excludeResetCreditDetails": True,
            }},
        ]
        for request in requests:
            process.stdin.write(json.dumps(request) + "\n")
            process.stdin.flush()
        deadline = time.monotonic() + 15
        pending = b""
        while time.monotonic() < deadline:
            readable, _, _ = select.select([process.stdout], [], [], 0.5)
            if not readable:
                if process.poll() is not None:
                    break
                continue
            chunk = os.read(process.stdout.fileno(), 65536)
            if not chunk:
                break
            pending += chunk
            while b"\n" in pending:
                line, pending = pending.split(b"\n", 1)
                message = json.loads(line)
                if message.get("id") == 2:
                    if "error" in message:
                        raise RuntimeError(str(message["error"]))
                    result = message["result"]
                    limits = (result.get("rateLimitsByLimitId") or {}).get("codex") or result["rateLimits"]
                    return {
                        "allowed": result.get("ordinaryUsageAllowed"),
                        "primary": limits.get("primary"),
                        "secondary": limits.get("secondary"),
                        "checkedAt": int(time.time()),
                    }
        raise TimeoutError("读取额度超时")
    finally:
        process.terminate()
        try:
            process.wait(timeout=2)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()


try:
    print(json.dumps(read_usage()))
except Exception as error:
    print(json.dumps({"error": str(error)}))
    sys.exit(1)
