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
    send-hook.sh
```

## Configuration

The hook helper resolves each value through a tiered fallback, first match wins:

| Tier | `broker_url` | `producer_token` |
| --- | --- | --- |
| 1. Claude plugin `userConfig` | `CLAUDE_PLUGIN_OPTION_BROKER_URL` | `CLAUDE_PLUGIN_OPTION_PRODUCER_TOKEN` |
| 2. Environment variable | `MEANWHILE_BROKER_URL` | `MEANWHILE_PRODUCER_TOKEN` |
| 3. Meanwhile-provisioned file | — | `${XDG_CONFIG_HOME:-~/.config}/meanwhile/producer-token` |
| 4. Default | `http://127.0.0.1:47683` | none (hook exits silently) |

Tier 3 is the primary path: Meanwhile writes the producer token to the
well-known path above (mode 600) whenever it generates or regenerates the token,
so installing the plugin is the only user action required. Regenerating the
token in Meanwhile rewrites the file.

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
| `Stop` | `completed` |
| `StopFailure` | `completed` |

All hooks post raw Claude hook payloads to `/v1/adapters/claude/hooks`. The
adapter maps each hook name to a canonical Meanwhile event, keeps only allowed
metadata, and discards the raw hook body. Requests require:

```text
Authorization: Bearer <producer_token>
Content-Type: application/json
```

## Verification

1. Launch Meanwhile and confirm Broker Status is Running.
2. Confirm the token file exists: `ls -l ~/.config/meanwhile/producer-token`
   (regenerate the token in the Integrations tab if missing).
3. Install the `meanwhile-claude` plugin in Claude and restart Claude.
4. Submit a Claude prompt or trigger a tool use.
5. Open Meanwhile Diagnostics and confirm accepted events with state
   transitions such as `idle -> pending`.

If `UserPromptSubmit` never appears in Diagnostics, the hook layer is not
executing or is missing configuration. If it appears with `missing_token`,
`invalid_token`, or `bundle_mismatch`, the hook is running and the issue is
broker authentication.

## Privacy

The hook helper forwards Claude's raw hook JSON to the local adapter endpoint.
The broker adapter is the privacy boundary: it may use lifecycle fields such as
hook name, session ID, tool name, duration, and error code, but must not persist
prompt text, response text, tool input or output, file paths or contents, URLs,
screenshots, clipboard data, window titles, conversation titles, or assistant
messages.
