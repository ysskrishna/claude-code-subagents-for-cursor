# Claude Code Subagents for Cursor

<img src="assets/logo-lockup.png" alt="Claude Code Subagents for Cursor" width="520">

[![Validate](https://github.com/ysskrishna/claude-code-subagents-for-cursor/actions/workflows/validate.yml/badge.svg)](https://github.com/ysskrishna/claude-code-subagents-for-cursor/actions/workflows/validate.yml) [![Test installs](https://github.com/ysskrishna/claude-code-subagents-for-cursor/actions/workflows/test-installs.yml/badge.svg)](https://github.com/ysskrishna/claude-code-subagents-for-cursor/actions/workflows/test-installs.yml) [![License: MIT](https://img.shields.io/github/license/ysskrishna/claude-code-subagents-for-cursor)](https://github.com/ysskrishna/claude-code-subagents-for-cursor/blob/main/LICENSE) [![GitHub release](https://img.shields.io/github/v/release/ysskrishna/claude-code-subagents-for-cursor?label=release)](https://github.com/ysskrishna/claude-code-subagents-for-cursor/releases) [![Author site](https://img.shields.io/badge/author-ysskrishna.space-informational)](https://ysskrishna.space)

A Cursor skill that runs your **custom subagents through Claude Code**, so each one runs on the `model:` written in its own agent file instead of the parent chat's model. Invoke it with `/use-claude-code-subagents`.

## Overview

In Cursor, custom subagents (`.cursor/agents/*.md`, `.claude/agents/*.md`, `.codex/agents/*.md`) declare a `model:` in their frontmatter, but the Task tool runs them on the **parent chat's model** anyway. This happens:

- when a **personal Anthropic API key (BYOK)** is on. Cursor staff confirmed it ([forum thread](https://forum.cursor.com/t/opus-spawns-only-opus-subagents-despite-different-instructions/166870), 2026-07-28), and
- when the agent's model is not reachable in Cursor (for example `model: haiku` resolves to Haiku 4.5 in Cursor, which many plans have disabled).

Either way, an agent you configured to run on Haiku bills at Opus rates.

Cursor cannot change a subagent's model mid-flight (hooks see the model but cannot set it; tested). Claude Code, run headlessly from Cursor's Shell tool, **does** honor the `model:` in agent files. This skill tells your Cursor agent to route custom subagents through `claude -p` for the rest of the chat. Every run reports the model it ran on, taken from the `modelUsage` field of Claude Code's JSON output.

## Installation

You need **Cursor** (desktop, running locally; Cloud Agents have no `claude` CLI) and **Claude Code 2.1.281 or later**, installed and signed in. Follow Anthropic's [setup guide](https://code.claude.com/docs/en/setup), then check with `claude --version`. Runs bill your Claude Code account.

Pick one route.

**Cursor plugin (recommended).** Cursor, then Customize, Plugins, Add, From GitHub Repository, and enter:

```
github.com/ysskrishna/claude-code-subagents-for-cursor
```

Choose **user scope** to get the skill in every project, or project scope to commit it for a team.

**skills.sh:**

```bash
npx skills add ysskrishna/claude-code-subagents-for-cursor --skill use-claude-code-subagents -a cursor -g
```

This installs to `~/.agents/skills/`, which Cursor loads. Drop `-g` to install into the current project instead.

**GitHub CLI** (version with `gh skill`):

```bash
gh skill install ysskrishna/claude-code-subagents-for-cursor use-claude-code-subagents --agent cursor --scope user
```

This installs to `~/.cursor/skills/`. Without `--agent cursor`, `gh` installs for GitHub Copilot.

**Manual.** Copy the [`skills/use-claude-code-subagents`](skills/use-claude-code-subagents) folder, including `references/`, to `~/.cursor/skills/` (user) or `<project>/.cursor/skills/` (project).

## Usage

```
/use-claude-code-subagents
```

The agent replies `Subagent mode: claude code`. From then on, every custom subagent you ask for runs via Claude Code on its own model. Say **"use cursor subagents"** to switch back to Cursor's native Task tool.

You can also skip the slash command and describe the problem ("why are all my subagents on Opus?"). The skill can load on its own, and when it does it asks for a yes before the first run, because runs bill your Claude Code account and edits bypass Cursor's review. Typing the slash command counts as consent.

## How it works

1. **Resolution.** It finds the agent file the way Cursor does: project beats user level; within a level, `.cursor/agents` beats `.claude/agents` beats `.codex/agents`. Agents not found in those six folders (Cursor's built-ins like `explore`) keep using the Task tool.
2. **Model mapping.** The `model:` in the agent file is translated for Claude Code:

   | `model:` in the agent file | What runs |
   |---|---|
   | Full Anthropic ID (`claude-haiku-5-5`) | That model, as is |
   | Cursor effort suffix (`-low` `-medium` `-high` `-xhigh` `-max`, `-fast`, `-thinking*`, `[effort=...]`) | Base ID with the suffix stripped (Claude Code rejects suffixed IDs) |
   | Alias (`haiku`, `sonnet`, `opus`) | Claude Code's latest of that family (Cursor resolves `haiku` to Haiku 4.5, so this intentionally differs) |
   | `inherit`, missing, or non-Anthropic (`composer-*`, `gpt-*`, `grok-*`, `gemini-*`) | **Not routed through Claude Code.** It falls back to Cursor's Task tool, with a one-line reason |

   Test results and untested edge cases: [`model-mapping.md`](skills/use-claude-code-subagents/references/model-mapping.md).
3. **Invocation.** Claude Code format agents (`.claude/agents`, `~/.claude/agents`) run via `--agent <name>`. Cursor format agents (`.cursor/agents`, `.codex/agents`) are written to a temp file as JSON and passed via `--agents <file>`; the file is removed after the run. The brief goes through a quoted heredoc, so the shell never expands it. Editing agents get `--permission-mode acceptEdits`; read-only agents get none.
4. **Safety.** Every run uses `--permission-prompts none`: anything Claude Code would prompt for is denied and reported back to you. Nothing runs with permissions skipped.

A full worked run is in [`example.md`](skills/use-claude-code-subagents/references/example.md).

## Verify it works

1. Pick a custom subagent whose `model:` differs from your chat's model.
2. Run `/use-claude-code-subagents`, then ask the chat to run that agent on a small task.
3. The reply ends with a line like `scout ran on claude-haiku-5-5`. That model comes from Claude Code's `modelUsage`, not from the agent file, so it shows what actually ran.

## Update and uninstall

| Route | Update | Uninstall |
|---|---|---|
| Cursor plugin | Remove and add the plugin again | Remove it under Customize, Plugins |
| skills.sh | `npx skills update` | `npx skills remove use-claude-code-subagents` |
| GitHub CLI | `gh skill update` | Delete `~/.cursor/skills/use-claude-code-subagents` |
| Manual | Copy the folder again | Delete the folder |

## What to expect

- Subagents show up as terminal commands, not Cursor's subagent cards.
- No mid-run steering. Follow-ups go to the same agent with `--resume <session_id>`.
- A subagent cannot ask you mid-run. It returns the question and the parent asks you.
- **Edits made by a routed subagent bypass Cursor's review and undo.** The agent lists changed files in its summary. Review them.
- **`claude -p` skips Claude Code's workspace trust dialog.** Use this only in projects you trust.
- The first run of `claude` in a session may show a Cursor approval prompt (Claude Code needs network and writes to `~/.claude`, outside Cursor's sandbox). Allow it once, or allowlist `claude` in Cursor's run settings.
- The subagent sees Claude Code's MCP config, not Cursor's. An agent that relies on a Cursor-only MCP server may lack that tool.
- A slash-invoked skill attaches to one message. The instruction stays in the chat's context, but in a very long chat run `/use-claude-code-subagents` again if the agent stops routing.

## Troubleshooting

| Symptom | Fix |
|---|---|
| No `Subagent mode: claude code` reply | The skill did not load. Type `/use-claude-code-subagents` and check that it appears in the list. |
| `claude: command not found`, or "needs 2.1.281" | Install Claude Code, or run `claude update`. |
| The agent ran through the Task tool | Its `model:` is missing, `inherit`, or not Anthropic, or its file was not found. The agent says which in one line. |
| `is_error: true` and a model error | Your Claude Code account cannot use that model. Change the `model:` in the agent file. |
| A permission was denied | The agent reports what was blocked and asks before rerunning with that tool allowed. |
| Approval prompt on every run | Allowlist `claude` in Cursor's run settings. |

## Platforms and tested versions

- **macOS:** tested end to end (Cursor 3.27.22, Claude Code 2.1.310).
- **Linux:** the install routes are tested in CI. Running subagents through Claude Code on Linux is not tested.
- **Windows:** untested.
- **Cloud Agents:** not supported (no `claude` CLI there).

## When you don't need this

- If you turn BYOK off, Cursor's native subagents may honor their `model:` again (reported by Cursor staff; verify on your setup).
- If Cursor fixes the pinning natively, this skill becomes unnecessary. Check the release notes before installing.

## Development

```bash
bash scripts/validate.sh          # manifests, skill rules, CHANGELOG, evals
bash scripts/check_claude_flags.sh # every claude flag the skill uses exists
bash scripts/test_installs.sh all  # skills.sh and gh routes, in a throwaway HOME
```

`validate.sh` checks both manifests against Cursor's official plugin schemas (vendored in [`schemas/`](schemas/), from [cursor/plugins](https://github.com/cursor/plugins)), the skill's description, size, references and trigger evals ([`evals/`](evals/)), and that the CHANGELOG matches `plugin.json`. CI runs all three, and checks weekly for schema and flag drift.

## Built and maintained by

Claude Code Subagents for Cursor is built and maintained by:

| | Name | GitHub | Role |
|---|------|--------|------|
| <img src="https://github.com/ysskrishna.png?size=120" width="60" height="60" alt="Y. Siva Sai Krishna"> | **Y. Siva Sai Krishna** | [@ysskrishna](https://github.com/ysskrishna) | Creator |


## Changelog

See [CHANGELOG](https://github.com/ysskrishna/claude-code-subagents-for-cursor/blob/main/CHANGELOG.md) for release history.

## Support

If you find this library helpful:

- ⭐ Star the repository
- 🐛 Report issues
- 🔀 Submit pull requests
- 💝 [Sponsor on GitHub](https://github.com/sponsors/ysskrishna)

## License

MIT © [Y. Siva Sai Krishna](https://github.com/ysskrishna) — see [LICENSE](https://github.com/ysskrishna/claude-code-subagents-for-cursor/blob/main/LICENSE) for details.

---

<p align="left">
  <a href="https://github.com/ysskrishna">Author's GitHub</a> •
  <a href="https://linkedin.com/in/ysskrishna">Author's LinkedIn</a> •
  <a href="https://ysskrishna.space">Author's site</a> •
  <a href="https://github.com/ysskrishna/claude-code-subagents-for-cursor/issues">Report Issues</a>
</p>
