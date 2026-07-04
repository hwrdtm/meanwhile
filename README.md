# Meanwhile

Meanwhile watches your AI coding agents so you don't have to. When an agent is
busy working, you can switch away and do something else; Meanwhile brings you
back when the agent needs your attention or finishes.

This repository hosts the Meanwhile Claude Code plugins — the "producer" side of
the integration that signals a locally running Meanwhile broker from Claude
lifecycle hooks.

## Layout

```text
.claude-plugin/
  marketplace.json      # Claude plugin marketplace manifest
plugins/
  claude-desktop/       # Claude Desktop hook integration
```

## Installing the plugin

1. Launch Meanwhile and keep it running. It auto-provisions the producer token
   to `~/.config/meanwhile/producer-token`, so no manual token entry is
   required. If you installed Meanwhile before this file existed, click
   Regenerate once in the Integrations tab.
2. Add this repository as a plugin marketplace in Claude:

   ```text
   /plugin marketplace add hwrdtm/meanwhile
   ```

3. Install the `meanwhile-claude` plugin:

   ```text
   /plugin install meanwhile-claude@meanwhile
   ```

4. Restart Claude, then submit a prompt or trigger a tool use.
5. Open Meanwhile Diagnostics and confirm accepted events.

See [`plugins/claude-desktop/README.md`](plugins/claude-desktop/README.md) for
configuration details, hook mapping, and troubleshooting.

## License

[MIT](LICENSE)
