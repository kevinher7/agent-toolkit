# Agent toolkit

Personal skills for Claude Code, Codex, and OpenCode, plus a Claude-only work plugin.

## Nix integration

This repository is intended to be consumed as a pinned, non-flake input by
`nixos-config`. Home Manager installs the shared skills and commands for enabled
tools, and the work plugin for Claude Code on the macbook only.

Content lives here; packages, settings, hooks, and host enablement belong in
`nixos-config`. Update its input lock and rebuild to deploy toolkit changes.

## Work plugin

Load the plugin for a Claude session from your project directory:

```sh
claude --plugin-dir /absolute/path/to/agent-toolkit/plugins/work
```

Use `/work:bee-review` or `/work:honeycomb-review` for a combined domain and type
review, and `/work:rereview` to check previously reported findings. `/work:gh`
handles PR operations and posting selected findings; `/work:fetch-review` reads
and translates a PR review. Posting requires your selection or request.

Install Bash, Git, `gh`, and `jq`, then authenticate with `gh auth login`.
Bee type checks need Poetry with `ty`, or `ty` on PATH. Honeycomb needs Node.js
and TypeScript installed in the project. Review commands expect `origin/develop`.
