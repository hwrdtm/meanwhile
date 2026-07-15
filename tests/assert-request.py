#!/usr/bin/env python3
import json
import sys
from pathlib import Path


capture_path = Path(sys.argv[1])
expected_hook = sys.argv[2]
expected_session = sys.argv[3]

payload = json.loads(capture_path.read_text())
assert payload == {
    "hook_event_name": expected_hook,
    "session_id": expected_session,
    "source": {
        "app_name": "Claude Desktop",
        "bundle_id": "com.anthropic.claudefordesktop",
    },
}
