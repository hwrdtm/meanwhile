#!/bin/sh
set -eu

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

sh -n \
  "$repo_root/plugins/claude-desktop/hooks/send-hook.sh" \
  "$repo_root/tests/send-hook-test.sh" \
  "$repo_root/tests/fixtures/bin/curl" \
  "$repo_root/tests/fixtures/bin/mktemp"
"$repo_root/tests/send-hook-test.sh"
/usr/bin/osascript -l JavaScript -s s "$repo_root/plugins/claude-desktop/hooks/sanitize-hook.js" \
  UserPromptSubmit "Claude Desktop" "com.anthropic.claudefordesktop" <<EOF > /dev/null
{"session_id":"validation-session"}
EOF
python3 "$repo_root/tests/config-test.py"
