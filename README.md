# claude-code-subagents-for-cursor

A Cursor plugin that gives you one command, `/use-claude-code-subagents`, which runs your **custom subagents through Claude Code** so each one runs on the `model:` written in its own agent file — instead of the parent chat's model.

## The problem

In Cursor, custom subagents (`.cursor/agents/*.md`, `.claude/agents/*.md`, `.codex/agents/*.md`) declare a `model:` in their frontmatter, but the Task tool runs them on the **parent chat's model** anyway. This happens:

- when a **personal Anthropic API key (BYOK)** is on — confirmed by Cursor staff ([forum thread](https://forum.cursor.com/t/opus-spawns-only-opus-subagents-despite-different-instructions/166870), 2026-07-28), and
- when the agent's model is not reachable in Cursor (for example `model: haiku` resolves to Haiku 4.5 in Cursor, which many plans have disabled).

Either way, an agent you configured to run on Haiku bills at Opus rates.

## The fix

Cursor cannot change a subagent's model mid-flight (hooks see the model but cannot set it — tested). But Claude Code, run headlessly from Cursor's Shell tool, **does** honor the `model:` in agent files. This plugin ships a command that tells your Cursor agent to route custom subagents through `claude -p` for the rest of the chat:

```
/use-claude-code-subagents
```

Reply: `Subagent mode: claude code`. From then on, every custom subagent runs via Claude Code on its own model, and `modelUsage` in the JSON output proves it. Say **"use cursor subagents"** to switch back to Cursor's native Task tool.

## Requirements

- **Cursor** desktop, running locally (Cloud Agents have no `claude` CLI).
- **Claude Code** installed and signed in (`claude --version` works) — subscription or API key; runs bill to that account.
- Custom subagents with an Anthropic `model:`.

## Install

**From GitHub (recommended):** Cursor → Customize → Plugins → Add → From GitHub Repository → enter:

```
github.com/ysskrishna/claude-code-subagents-for-cursor
```

Choose **user scope** to get the command in every project (recommended), or project scope to commit it for a team.

**Manual fallback:** copy [`commands/use-claude-code-subagents.md`](commands/use-claude-code-subagents.md) into `~/.cursor/commands/` (user scope) or `<project>/.cursor/commands/` (project scope).

## How it works

1. **Resolution** — finds the agent file the same way Cursor does: project beats user level; within a level, `.cursor/agents` beats `.claude/agents` beats `.codex/agents`. Agents not found in those six folders (Cursor's built-ins like `explore`) keep using the Task tool.
2. **Model mapping** — the `model:` in the agent file is translated for Claude Code:

   | `model:` in the agent file | What runs |
   |---|---|
   | Full Anthropic ID (`claude-haiku-5-5`) | That model, as is |
   | Cursor effort suffix (`-low` `-medium` `-high` `-xhigh` `-max`, `-fast`, `-thinking*`, `[effort=…]`) | Base ID with the suffix stripped (Claude Code rejects suffixed IDs) |
   | Alias (`haiku`, `sonnet`, `opus`) | Claude Code's latest of that family (note: Cursor resolves `haiku` to Haiku 4.5, so this intentionally differs) |
   | `inherit`, missing, or non-Anthropic (`composer-*`, `gpt-*`, `grok-*`, `gemini-*`) | **Not routed through Claude Code** — falls back to Cursor's Task tool, with a one-line reason |

3. **Invocation** — Claude Code format agents (`.claude/agents`, `~/.claude/agents`) run via `--agent <name>`; Cursor format agents (`.cursor/agents`, `.codex/agents`) are converted to JSON and passed via `--agents <file>`. Editing agents get `--permission-mode acceptEdits`; read-only agents get none.
4. **Safety** — every run uses `--permission-prompts none`: anything Claude Code would prompt for is denied automatically and reported back to you. Nothing runs with permissions skipped.

## What to expect (trade-offs)

- Subagents show up as terminal commands, not Cursor's subagent cards.
- No mid-run steering; follow-ups go to the same agent with `--resume <session_id>`.
- A subagent cannot ask you mid-run; it returns the question and the parent asks you.
- **Edits made by a routed subagent bypass Cursor's review/undo.** The agent lists changed files in its summary — review them.
- The first run of `claude` in a session may show a Cursor approval prompt (Claude Code needs network and writes to `~/.claude`, outside Cursor's sandbox). Allow it once, or allowlist `claude` in Cursor's run settings.
- The subagent sees Claude Code's MCP config, not Cursor's — an agent relying on a Cursor-only MCP server may lack that tool.

## Platforms

macOS and Linux are tested. Windows is untested — the command only uses shell features that should port, but no Windows testing has been done. Not for Cloud Agents (no `claude` CLI there).

## When you don't need this

- If you turn BYOK off, Cursor's native subagents may honor their `model:` again (staff-reported; verify on your setup).
- If Cursor fixes the pinning natively, this plugin becomes unnecessary — check the release notes before installing.

## Development

```bash
bash scripts/validate.sh
```

Validates both manifests against Cursor's official plugin schemas (vendored in [`schemas/`](schemas/), from [cursor/plugins](https://github.com/cursor/plugins)), checks command frontmatter, and asserts manifest/repository consistency. CI runs the same check on every push.

## License

[MIT](LICENSE)
