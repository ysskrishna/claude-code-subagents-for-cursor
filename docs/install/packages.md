# Claude Code, npm, and OpenClaw

The [Cursor install routes](../../README.md#installation) are unchanged. These files let other registries load the same repo.

## Claude Code

`.claude-plugin/plugin.json` names the plugin `cursor-subagent-models`. `.claude-plugin/marketplace.json` lists that one entry, `source` `./`. The skill stays at `skills/use-claude-code-subagents/`. Cursor still reads `.cursor-plugin/`, whose name stays `claude-code-subagents-for-cursor`.

Claude Code rejects a third-party plugin name that starts with `claude-`, and `--strict` also warns when the name reads as Anthropic's own. `cursor-subagent-models` is the name that passes `claude plugin validate --strict .`. The Cursor plugin name is unchanged.

In Claude Code, after this repo is on a marketplace:

```text
/plugin install cursor-subagent-models --marketplace ysskrishna/claude-code-subagents-for-cursor
```

buildwithclaude closed the earlier listing because this repo only had the Cursor manifest. A later entry has to use the plugin id `cursor-subagent-models`, because that is the name in `.claude-plugin/plugin.json`. The product name on Cursor and ClawHub stays Claude Code Subagents for Cursor.

## npm

Package name: `@ysskrishna/claude-code-subagents-for-cursor`.

Claude Code can fetch a marketplace plugin from npm. This package is that artifact. It does not install the Cursor plugin, and npm downloads are not Cursor Directory views.

`package.json` `files` publishes `skills/`, `assets/`, `.claude-plugin/`, `.cursor-plugin/`, `openclaw.plugin.json`, `README.md`, `LICENSE`, and `CHANGELOG.md`.

## OpenClaw

`openclaw.plugin.json` is the ClawHub bundle. The id is `claude-code-subagents-for-cursor`. The display name is Claude Code Subagents for Cursor, the same as `.cursor-plugin/plugin.json` `displayName`. `package.json` carries `openclaw.compat` and `openclaw.build.openclawVersion`, the same pins as `@ysskrishna/ai-agent-skills`. This repo has not been run against an OpenClaw gateway.

ClawHub shows `assets/icon.png` as the plugin image. An icon URL in the manifest is ignored. The category in `openclaw.plugin.json` is `developer-tools`. Topics are not manifest fields. Skill publish uses ClawHub browse categories `development` and `agents`; the bundle keeps `developer-tools` in `openclaw.plugin.json`. `scripts/publish_clawhub.py` passes topics `cursor`, `subagents`, `claude-code`, `model-routing`, `byok` on skill and package publish (clawhub CLI ≥ 0.26.0).

Install the skill alone with ClawHub, for example `clawhub install use-claude-code-subagents` (after `python3 scripts/publish_clawhub.py publish`). The OpenClaw bundle is `@ysskrishna/claude-code-subagents-for-cursor` via `package publish`. Maintainer sync: `plan` / `publish` for the skill, `package plan` / `package publish` for the bundle.

ClawHub rejects an upload of the whole repo, because that contains more than one bundle manifest, and it rejects a tarball that only has `openclaw.plugin.json`. The bundle script stages one host manifest (`.cursor-plugin/plugin.json`) plus `openclaw.plugin.json`, including `assets/icon.png`. Legacy `python3 scripts/publish_clawhub.py` (no subcommand) is a bundle dry run. CI does not run publish.
