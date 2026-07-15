#!/bin/sh
set -eu

hook_name="${1:-}"
broker_url="${CLAUDE_PLUGIN_OPTION_BROKER_URL:-${MEANWHILE_BROKER_URL:-http://127.0.0.1:47683}}"
producer_token="${CLAUDE_PLUGIN_OPTION_PRODUCER_TOKEN:-${MEANWHILE_PRODUCER_TOKEN:-}}"
timeout_seconds="${MEANWHILE_HOOK_TIMEOUT_SECONDS:-2}"
source_app_name="Claude Desktop"
source_bundle_id="com.anthropic.claudefordesktop"

case "$hook_name" in
  UserPromptSubmit|PreToolUse|PostToolUse|PostToolUseFailure|\
    PermissionRequest|Notification|Stop|StopFailure|SessionEnd) ;;
  *) exit 0 ;;
esac

# Claude hosts do not share sensitive userConfig storage (CLI keychain vs
# Desktop safeStorage), so Meanwhile.app provisions the token at a well-known
# path that every host's hook subprocess can read.
token_file="${MEANWHILE_PRODUCER_TOKEN_FILE:-${XDG_CONFIG_HOME:-$HOME/.config}/meanwhile/producer-token}"
if [ -z "$producer_token" ] && [ -r "$token_file" ]; then
  producer_token="$(cat "$token_file")"
fi

if [ -z "$producer_token" ]; then
  exit 0
fi

# Build a new payload in memory. JSON.stringify handles arbitrary session IDs,
# while every other field from Claude's input is discarded.
script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
if [ -x /usr/bin/osascript ]; then
  payload="$(/usr/bin/osascript -l JavaScript "$script_dir/sanitize-hook.js" \
    "$hook_name" "$source_app_name" "$source_bundle_id" 2> /dev/null || true)"
else
  cat > /dev/null
  payload=""
fi

if [ -z "$payload" ]; then
  payload="{\"hook_event_name\":\"$hook_name\",\"source\":{\"app_name\":\"$source_app_name\",\"bundle_id\":\"$source_bundle_id\"}}"
fi

endpoint="${broker_url%/}/v1/adapters/claude/hooks"

curl \
  --silent \
  --show-error \
  --fail \
  --max-time "$timeout_seconds" \
  --request POST \
  --header "Authorization: Bearer $producer_token" \
  --header "Content-Type: application/json" \
  --data-binary "$payload" \
  "$endpoint" \
  > /dev/null 2>&1 || true
