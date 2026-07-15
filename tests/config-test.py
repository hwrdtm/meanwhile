#!/usr/bin/env python3
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PLUGIN_ROOT = ROOT / "plugins" / "claude-desktop"

plugin = json.loads((PLUGIN_ROOT / ".claude-plugin" / "plugin.json").read_text())
assert plugin["version"] == "0.1.1"
assert plugin["userConfig"]["producer_token"]["required"] is False

config = json.loads((PLUGIN_ROOT / "hooks" / "hooks.json").read_text())
expected_hooks = {
    "UserPromptSubmit",
    "PreToolUse",
    "PostToolUse",
    "PostToolUseFailure",
    "PermissionRequest",
    "Notification",
    "Stop",
    "StopFailure",
    "SessionEnd",
}
assert set(config["hooks"]) == expected_hooks
notification = config["hooks"]["Notification"][0]
assert notification["matcher"] == (
    "permission_prompt|idle_prompt|elicitation_dialog"
)

for hook_name, registrations in config["hooks"].items():
    assert len(registrations) == 1
    commands = registrations[0]["hooks"]
    assert len(commands) == 1
    command = commands[0]
    assert command["type"] == "command"
    assert command["command"] == "sh"
    assert command["args"][-1] == hook_name
    assert command["timeout"] == 2
    if hook_name == "SessionEnd":
        assert command.get("async", False) is False
    else:
        assert command["async"] is True

print("plugin configuration test passed")
