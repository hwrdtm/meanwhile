# Meanwhile Claude Desktop Plugin

Sends Claude Desktop lifecycle events to a locally running Meanwhile broker via
Claude command hooks.

## Layout

```text
claude-desktop/
  .claude-plugin/
    plugin.json
  hooks/
    hooks.json
    sanitize-hook.js
    send-hook.sh
```

## Configuration

The hook helper resolves each value through a tiered fallback, first match wins:

| Tier | `broker_url` | `producer_token` |
| --- | --- | --- |
| 1. Claude plugin `userConfig` | `CLAUDE_PLUGIN_OPTION_BROKER_URL` | `CLAUDE_PLUGIN_OPTION_PRODUCER_TOKEN` |
| 2. Environment variable | `MEANWHILE_BROKER_URL` | `MEANWHILE_PRODUCER_TOKEN` |
| 3. Meanwhile-provisioned file | none | `${XDG_CONFIG_HOME:-~/.config}/meanwhile/producer-token` |
| 4. Default | `http://127.0.0.1:47683` | none (hook exits silently) |

Tier 3 is the primary path: Meanwhile writes the producer token to the
well-known path above (mode 600) whenever it generates or regenerates the token,
so installing the plugin is the only user action required. Regenerating the
token in Meanwhile rewrites the file.

Set `MEANWHILE_PRODUCER_TOKEN_FILE` to override the token file path. This is
useful for isolated development profiles and tests. An explicit producer token
in Claude plugin configuration remains available as an optional override, but
is not required for normal installation.

Hook calls are best-effort. If no token resolves or the broker is unavailable,
hooks exit without blocking Claude Desktop.

## Hook Mapping

| Claude hook | Meanwhile event |
| --- | --- |
| `UserPromptSubmit` | `work_started` |
| `PreToolUse` | `work_started` |
| `PostToolUse` | `heartbeat` |
| `PostToolUseFailure` | `heartbeat` |
| `PermissionRequest` | `needs_user` |
| `Notification` (`permission_prompt`, `idle_prompt`, `elicitation_dialog`) | `needs_user` |
| `Stop` | `completed` |
| `StopFailure` | `completed` |
| `SessionEnd` | `completed` |

All hooks except `SessionEnd` run asynchronously so Claude does not wait for the
local broker. `SessionEnd` stays synchronous so its final completion signal can
finish before Claude exits the session.

The helper constructs a new payload containing only `hook_event_name`,
`session_id` when present, and a fixed Claude Desktop source identity. It posts
that sanitized payload to `/v1/adapters/claude/hooks`. Requests require:

```text
Authorization: Bearer <producer_token>
Content-Type: application/json
```

## Installation

1. Add this marketplace in Claude: `/plugin marketplace add hwrdtm/meanwhile`
2. Install the plugin: `/plugin install meanwhile-claude@meanwhile`
3. Restart Claude.

## Verification

1. Launch Meanwhile and confirm Broker Status is Running.
2. Confirm the token file exists: `ls -l ~/.config/meanwhile/producer-token`
   (regenerate the token in the Integrations tab if missing).
3. Submit a Claude prompt or trigger a tool use.
4. Open Meanwhile Diagnostics and confirm accepted events with state
   transitions such as `idle -> pending`.

If `UserPromptSubmit` never appears in Diagnostics, the hook layer is not
executing or is missing configuration. If it appears with `missing_token`,
`invalid_token`, or `bundle_mismatch`, the hook is running and the issue is
broker authentication.

## Privacy

The hook helper extracts only `session_id` from Claude's input. It uses the
stock macOS JavaScript runtime to build correctly escaped JSON in memory. It
never writes the raw input to disk and never forwards it. Prompt text, response
text, tool input or output, file paths or contents, URLs, screenshots, clipboard
data, window titles, conversation titles, assistant messages, and all other
hook fields are discarded inside the hook process.
