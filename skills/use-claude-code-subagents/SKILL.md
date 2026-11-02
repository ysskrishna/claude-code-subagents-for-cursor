---
name: use-claude-code-subagents
description: Run this chat's custom subagents through Claude Code so each runs on the model in its own agent file instead of the parent model
---

# use-claude-code-subagents

From now on, run the project's *custom* subagents through Claude Code (headless `claude -p`) so each one runs on the `model:` declared in its own agent file. Cursor's Task tool pins custom subagents to the parent model when a personal Anthropic API key is on, or when the agent's model is not enabled in Cursor. Built-in Cursor subagents (`explore`, `generalPurpose`, …) keep using the Task tool.

When the user says "use cursor subagents", switch back to the Task tool for everything and confirm in one line.

## 0. First use in a chat

1. Reply exactly: `Subagent mode: claude code`.
2. Preflight once: run `claude --version` from the Shell tool with `required_permissions: ["all"]`. If it fails, tell the user to install Claude Code (`curl -fsSL https://claude.ai/install.sh | bash`, then run `claude` once to sign in) and stay in Cursor native mode until they do.
3. If the user's message included a task, do it (steps below); otherwise wait.

## 1. Resolve the agent

For each agent named, find its file — first match wins (this is Cursor's documented precedence: project beats user; `.cursor/` beats `.claude/` beats `.codex/`):

1. `<project>/.cursor/agents/<name>.md`
2. `<project>/.claude/agents/<name>.md`
3. `<project>/.codex/agents/<name>.md`
4. `~/.cursor/agents/<name>.md`
5. `~/.claude/agents/<name>.md`
6. `~/.codex/agents/<name>.md`

Not found → not a custom agent: use the Task tool as usual and say one line why. From the file read the frontmatter `description`, the body (`prompt`), and `model`, `tools`, `readonly` if present.

## 2. Map the model

| `model:` in the file | Action |
|---|---|
| missing, `inherit`, or non-Anthropic (`composer-*`, `gpt-*`, `grok-*`, `gemini-*`, …) | Do not use Claude Code. Run it with the Task tool and say one line why. |
| ends with `-low` `-medium` `-high` `-xhigh` `-max` (e.g. `claude-haiku-5-5-medium`) | Strip the suffix; pass the base ID. |
| ends with `-fast`, `-thinking`, `-thinking-low`/`-high`/`-max`, or a bracket suffix like `[effort=…]` | Strip the suffix; pass the base ID. |
| `haiku`, `sonnet`, `opus` | Pass as is — Claude Code resolves the alias to its latest (tested: `haiku` → `claude-haiku-5-5`). |
| full Anthropic ID (e.g. `claude-haiku-5-5`) | Pass as is. |

## 3. Brief the agent

The brief has: goal, absolute paths, constraints, and the exact return format. Never paste file contents into the brief — name the files to read instead.

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
- Editing agent → add `--permission-mode acceptEdits`. Read-only agent (`readonly: true`, or a `tools:` list without Edit/Write) → omit it. Read-only agents: file writes and edits are denied, though some harmless read-only shell commands may still be auto-allowed.
- Never use `--dangerously-skip-permissions`. With `--permission-prompts none`, anything that would prompt is denied automatically and reported in `permission_denials`.
- If the user names a model for one run ("<agent> on sonnet"), pass their model instead — full ID if they gave one, else the alias.

## 5. Report

- If `is_error` is `true`, `result` holds an error message, not the agent's answer (e.g. an inaccessible model), and `modelUsage` is empty. Report the error and do not treat it as the agent's output.
- Otherwise, answer from `result`, then one short line naming the model from `modelUsage` (e.g. "test-ro ran on claude-haiku-5-5"). Never report cost.
- `permission_denials` non-empty → say what was blocked and ask before rerunning with `--allowedTools "<tool>"` added. Otherwise say nothing about it.
- The agent asked a question → ask the user, then continue the same agent with the answer in the same heredoc form: `claude -p "$(cat <<'BRIEF' ... BRIEF)" --resume <session_id> --permission-prompts none --output-format json`. Use `--resume` for any follow-up to the same agent.
- Parallel work: start up to 3 runs in the background (`block_until_ms: 0`) and await them.
- Edits made this way bypass Cursor's review/undo — list changed files in the summary.
