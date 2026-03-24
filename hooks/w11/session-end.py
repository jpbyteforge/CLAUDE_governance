"""session-end — Log session end to token-economy.log.
Runs on Stop hook. Records session closure for token economy reporting.
"""
import sys
import json
from datetime import datetime
from pathlib import Path


def main() -> None:
    try:
        data = json.loads(sys.stdin.read())
    except Exception:
        sys.exit(0)

    try:
        log_path = Path.home() / ".claude" / "token-economy.log"
        ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        stop_active = data.get("stop_hook_active", False)
        entry = f"{ts} | SESSION_END | stop_hook_active={stop_active}\n"
        with log_path.open("a", encoding="utf-8") as f:
            f.write(entry)
    except Exception:
        pass

    sys.exit(0)


if __name__ == "__main__":
    main()
