# Release state

For maintainers and coding agents. Update this file **after** each tagged release is pushed and the GitHub Release workflow succeeds.

| Field | Value |
| --- | --- |
| Last shipped version | 1.3.4 |
| Last tag | `v1.3.4` |
| Tagged from `main` at | `0f7b625` |
| GitHub Release | https://github.com/ysskrishna/claude-code-subagents-for-cursor/releases/tag/v1.3.4 |

**Next release:** bump version in `.cursor-plugin/plugin.json` and the mirrors `validate.sh` checks (`SKILL.md`, `.claude-plugin/`, `openclaw.plugin.json`, `package.json`), add a `CHANGELOG.md` section, merge to `main`, run the three check scripts, push an annotated `vX.Y.Z` tag. Full steps: [development.md#releases](development.md#releases) and [AGENTS.md](../../AGENTS.md#releases).

**Source of truth while preparing a release:** `plugin.json` / `SKILL.md` / top `CHANGELOG` section (must agree; `validate.sh` enforces this). This file records what is **already on GitHub**, not work in progress.