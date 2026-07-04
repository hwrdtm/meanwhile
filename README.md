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

## Installing the plugins

Add this repository as a plugin marketplace in Claude, then install the
`meanwhile-claude` plugin. See [`plugins/claude-desktop/README.md`](plugins/claude-desktop/README.md)
for configuration and verification steps.

## License

[MIT](LICENSE)
