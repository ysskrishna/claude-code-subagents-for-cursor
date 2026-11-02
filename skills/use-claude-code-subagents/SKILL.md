---
name: use-claude-code-subagents
description: >
  Use when Cursor subagents run on the parent model instead of the model in their agent file, or the user asks: "use claude code subagents", "run scout on haiku", "why are my subagents all Opus?". Runs custom subagents through headless Claude Code. Skip for Cursor's built-in subagents or Cloud Agents.
license: MIT
metadata:
  author: ysskrishna
  version: "2026.11.2"
---

# Use Claude Code subagents

## When to use

Cursor's Task tool pins custom subagents to the parent model when a personal Anthropic API key is on, or when the agent's model is not enabled in Cursor. This skill runs the project's custom subagents through Claude Code (headless `claude -p`) so each runs on the `model:` in its own agent file. The mode lasts for the rest of the chat. When the user says "use cursor subagents", switch back to the Task tool and confirm in one line.

Skip for Cursor's built-in subagents (`explore`, `generalPurpose`, ...), for Cloud Agents (no `claude` CLI there), and for any agent whose `model:` is missing, `inherit`, or not Anthropic (see step 2). Those keep using the Task tool.

## Before you start

1. **Gather first.** Read the agent file for each agent named (step 1) before you ask the user anything.
2. **Consent.** If the user typed `/use-claude-code-subagents` or asked for Claude Code subagents, continue. If this skill loaded on its own (the user only described a symptom), ask once: "Run custom subagents through Claude Code? Runs bill your Claude Code account and edits bypass Cursor's review and undo. Reply yes to switch." Wait for yes. On no, use the Task tool.
3. Reply exactly: `Subagent mode: claude code`.
4. **Preflight once.** Run `claude --version` from the Shell tool with `required_permissions: ["all"]`. This skill needs Claude Code 2.1.281 or later (`--permission-prompts` needs 2.1.259, the `--agents <file>` form needs 2.1.281). If the command fails, point the user to the [Claude Code setup guide](https://code.claude.com/docs/en/setup) and tell them to run `claude` once to sign in. If the version is older, ask them to run `claude update`. Stay in Cursor native mode until it passes.
5. **Light path.** For one agent and one task, do steps 1, 2, 4 and 5 with a single `claude` call. Skip parallel runs and `--resume` unless the agent asks a question.
6. If the user's message included a task, do it. Otherwise wait.

## 1. Resolve the agent

Find the agent's file. First match wins (Cursor's documented precedence: project beats user; `.cursor/` beats `.claude/` beats `.codex/`):

1. `<project>/.cursor/agents/<name>.md`
2. `<project>/.claude/agents/<name>.md`
3. `<project>/.codex/agents/<name>.md`
4. `~/.cursor/agents/<name>.md`
5. `~/.claude/agents/<name>.md`
6. `~/.codex/agents/<name>.md`

Not found means it is not a custom agent: use the Task tool as usual and say one line why. From the file read the frontmatter `description`, the body (`prompt`), and `model`, `tools`, `readonly` if present.

## 2. Map the model

| `model:` in the file | Action |
|---|---|
| missing, `inherit`, or non-Anthropic (`composer-*`, `gpt-*`, `grok-*`, `gemini-*`, ...) | Do not use Claude Code. Run it with the Task tool and say one line why. |
| ends with `-low` `-medium` `-high` `-xhigh` `-max` (e.g. `claude-haiku-5-5-medium`) | Strip the suffix; pass the base ID. |
| ends with `-fast`, `-thinking`, `-thinking-low`/`-high`/`-max`, or a bracket suffix like `[effort=...]` | Strip the suffix; pass the base ID. |
| `haiku`, `sonnet`, `opus` | Pass as is. Claude Code resolves the alias to its latest (tested: `haiku` -> `claude-haiku-5-5`). |
| full Anthropic ID (e.g. `claude-haiku-5-5`) | Pass as is. |

Evidence for each row and untested edge cases: [references/model-mapping.md](references/model-mapping.md).

## 3. Brief the agent

The brief has: goal, absolute paths, constraints, and the exact return format. Never paste file contents into the brief; name the files to read instead.

Pass the brief through a single-quoted heredoc, never inside double quotes. Double quotes make the shell expand `$VAR`, backticks and `$(...)` and break on an inner `"` (tested: `$HOME` and `` `date` `` in a double-quoted brief arrived expanded). The brief must not contain a line that is exactly `BRIEF`.

## 4. Run

Always from the Shell tool with `required_permissions: ["all"]` (Claude Code needs network and writes to `~/.claude`, which the sandbox blocks).

Agent from `.claude/agents` or `~/.claude/agents` (Claude Code format):

```bash
claude -p "$(cat <<'BRIEF'
<brief>
BRIEF
)" --agent <name> --model <mapped> --permission-prompts none --output-format json
```

Agent from `.cursor/agents` or `.codex/agents` (Cursor format): create a temp file with `mktemp "${TMPDIR:-/tmp}/claude-agents.XXXXXX"` (no `.json` suffix: macOS only randomizes trailing X's), write the agent into it as JSON in Claude Code format, pass it, then `rm -f` it after the run:

```json
{ "<name>": { "description": "<frontmatter description>", "prompt": "<body>", "model": "<mapped>" } }
```

```bash
claude -p "$(cat <<'BRIEF'
<brief>
BRIEF
)" --agents <temp-file> --agent <name> --model <mapped> --permission-prompts none --output-format json
```

- Add `"tools": [...]` to the JSON when the frontmatter has a `tools:` list.
- Editing agent: add `--permission-mode acceptEdits`. Read-only agent (`readonly: true`, or a `tools:` list without Edit/Write): omit it. Read-only agents have file writes and edits denied, though some harmless read-only shell commands may still be auto-allowed.
- With `--permission-prompts none`, anything that would prompt is denied automatically and reported in `permission_denials`.
- If the user names a model for one run ("<agent> on sonnet"), pass their model instead: the full ID if they gave one, else the alias.

## 5. Report

- If `is_error` is `true`, `result` holds an error message, not the agent's answer (e.g. an inaccessible model), and `modelUsage` is empty. Report the error and do not treat it as the agent's output.
- Otherwise, answer from `result`, then one short line naming the model from `modelUsage` (e.g. "test-ro ran on claude-haiku-5-5"). Never report cost.
- `permission_denials` non-empty: say what was blocked and ask before rerunning with `--allowedTools "<tool>"` added. Otherwise say nothing about it.
- The agent asked a question: ask the user, then continue the same agent with the answer in the same heredoc form: `claude -p "$(cat <<'BRIEF' ... BRIEF)" --resume <session_id> --permission-prompts none --output-format json`. Use `--resume` for any follow-up to the same agent.
- Parallel work: start up to 3 runs in the background (`block_until_ms: 0`) and await them.
- Edits made this way bypass Cursor's review/undo. List the changed files in the summary.

## Pitfalls

- `claude -p` skips Claude Code's workspace trust dialog and loads the project's Claude Code settings. Run it only in a project the user trusts.
- The `prompt` field in the agents JSON must be valid JSON: escape quotes and newlines from the agent's body.
- Never use `--dangerously-skip-permissions`.
- A subagent run is a terminal command, not a Cursor subagent card, and cannot be steered mid-run.
- The subagent sees Claude Code's MCP config, not Cursor's. An agent that depends on a Cursor-only MCP server may lack that tool.

## Checklist

- Agent file found and read before any question to the user.
- Consent given (or the user invoked the skill by name) before the first run.
- Version check passed; mapped model is an Anthropic ID or alias.
- Brief sent through the quoted heredoc; temp file removed.
- `is_error` checked; the model line comes from `modelUsage`.

A full worked run, from the slash command to the model line, is in [references/example.md](references/example.md).
