#!/bin/sh
set -eu

hook_name="${1:-}"
broker_url="${CLAUDE_PLUGIN_OPTION_BROKER_URL:-${MEANWHILE_BROKER_URL:-http://127.0.0.1:47683}}"
producer_token="${CLAUDE_PLUGIN_OPTION_PRODUCER_TOKEN:-${MEANWHILE_PRODUCER_TOKEN:-}}"
timeout_seconds="${MEANWHILE_HOOK_TIMEOUT_SECONDS:-2}"

# Claude hosts do not share sensitive userConfig storage (CLI keychain vs
# Desktop safeStorage), so Meanwhile.app provisions the token at a well-known
# path that every host's hook subprocess can read.
token_file="${XDG_CONFIG_HOME:-$HOME/.config}/meanwhile/producer-token"
if [ -z "$producer_token" ] && [ -r "$token_file" ]; then
  producer_token="$(cat "$token_file")"
fi

if [ -z "$producer_token" ]; then
  exit 0
fi

payload_file="$(mktemp "${TMPDIR:-/tmp}/meanwhile-claude-hook.XXXXXX")"
trap 'rm -f "$payload_file"' EXIT

cat > "$payload_file"

if [ ! -s "$payload_file" ]; then
  printf '{"hook_event_name":"%s","source":{"app_name":"Claude Desktop","bundle_id":"com.anthropic.claudefordesktop"}}' "$hook_name" > "$payload_file"
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
  --data-binary "@$payload_file" \
  "$endpoint" \
  > /dev/null 2>&1 || true
