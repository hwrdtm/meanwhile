#!/bin/sh
set -eu

repo_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
fixture_bin="$repo_root/tests/fixtures/bin"
work_dir="$(mktemp -d "${TMPDIR:-/tmp}/meanwhile-send-hook-test.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT

capture="$work_dir/request-body"
token_file="$work_dir/custom-token"
printf '%s\n' "test-token" > "$token_file"

session_id='session-"quoted"\backslash/雪'
input='{"hook_event_name":"InjectedEvent","session_id":"session-\"quoted\"\\backslash/雪","prompt":"do not forward","tool_input":{"path":"/private/secret"},"url":"https://private.example"}'
printf '%s' "$input" |
  PATH="$fixture_bin:$PATH" \
  TMPDIR="$work_dir" \
  MEANWHILE_TEST_CAPTURE="$capture" \
  MEANWHILE_PRODUCER_TOKEN_FILE="$token_file" \
  sh "$repo_root/plugins/claude-desktop/hooks/send-hook.sh" UserPromptSubmit

actual="$(cat "$capture")"
python3 "$repo_root/tests/assert-request.py" \
  "$capture" UserPromptSubmit "$session_id"

authorization="$(cat "$capture.authorization")"
if [ "$authorization" != "Authorization: Bearer test-token" ]; then
  printf 'unexpected authorization header: %s\n' "$authorization" >&2
  exit 1
fi

case "$actual" in
  *"do not forward"*|*"/private/secret"*|*"private.example"*)
    printf '%s\n' "private hook fields were forwarded" >&2
    exit 1
    ;;
esac

if grep -R -q "do not forward" "$work_dir"; then
  printf '%s\n' "private hook fields were written to disk" >&2
  exit 1
fi

printf '%s\n' "send-hook privacy test passed"
