# Cursor plugin

## Install

1. In Cursor, open **Customize, Plugins, Add, From GitHub Repository**.
2. Enter `github.com/ysskrishna/claude-code-subagents-for-cursor`.
3. Choose **user scope** to get the skill in every project, or project scope to commit it for a team.

You also need Claude Code installed and signed in. See [Requirements](README.md#requirements).

## Verify

Open **Customize, Skills**. `use-claude-code-subagents` is listed. Then follow [Verify it works](usage.md#verify-it-works).

## Update and remove

Update: remove the plugin and add it again. Remove: **Customize, Plugins**, then remove it.

## Notes

- Cursor reads `.cursor-plugin/plugin.json` and `.cursor-plugin/marketplace.json` from the repo. Both validate against Cursor's published JSON schemas, vendored in [`schemas/`](../schemas/).
- This route is checked by hand before each release. CI cannot run the Cursor app.
