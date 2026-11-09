# How it works

Cursor cannot change a subagent's model mid-flight (hooks see the model but cannot set it; tested). Claude Code, run headlessly from Cursor's Shell tool, honors the `model:` in agent files. The skill tells the Cursor agent to route custom subagents through `claude -p` for the rest of the chat. Every run reports the model it ran on, taken from the `modelUsage` field of Claude Code's JSON output.

## 1. Agent lookup

The skill finds the agent file the way Cursor does: project beats user; within a level, `.cursor/agents` beats `.claude/agents` beats `.codex/agents`. Agents not found in those six folders (Cursor's built-ins such as `explore`) keep using the Task tool. The agent name must be letters, digits, `.`, `_` or `-`, at most 64 characters, starting with a letter or digit. Anything else uses the Task tool.

## 2. Model mapping

The `model:` in the agent file is translated for Claude Code:

| `model:` in the agent file | What runs |
|---|---|
| `haiku`, `sonnet`, `opus` | Claude Code's latest model of that family |
| starts with `claude-` | That model, with any Cursor effort, speed or thinking suffix removed (Claude Code rejects suffixed IDs) |
| anything else (missing, `inherit`, other vendors) | **Not routed through Claude Code.** It falls back to Cursor's Task tool, with a one-line reason |

The alias note: Cursor and Claude Code resolve aliases differently. When last checked (Cursor 3.27.22), Cursor mapped `haiku` to Haiku 4.5, which many plans have disabled, while Claude Code maps it to its latest Haiku. An agent with `model: haiku` can therefore run on a newer model through this skill than in Cursor. That is intended.

The suffix list, test results and untested edge cases are in [`model-mapping.md`](../skills/use-claude-code-subagents/references/model-mapping.md).

## 3. The `claude` command

- The command starts with `claude`: no `cd`, `export`, pipe or `;` around it. Cursor's allowlist matches the start of a command ([permissions.md](permissions.md)). The Shell tool's `working_directory` is the project folder, so Claude Code finds the agent file there (it also searches parent folders, tested).
- The brief is written to a file and read through stdin (`claude -p < file`), so the shell never parses it. `$VAR`, backticks, quotes and lines such as `BRIEF` reach the agent unchanged.
- The files live in `~/.cursor/projects/<workspace>/subagent-briefs/<id>/`, Cursor's own folder for the project, which counts as inside the workspace. If the skill cannot use it, it falls back to a `mktemp` folder and removes that folder afterwards.
- Claude Code format agents (`.claude/agents`, `~/.claude/agents`) run with `--agent <name>`.
- Cursor format agents (`.cursor/agents`, `.codex/agents`) are written as JSON to a file in the same run folder and passed with `--agents <file>`.
- Editing agents get `--permission-mode acceptEdits`. Read-only agents get none.
- Every run uses `--permission-prompts none`: anything Claude Code would prompt for is denied and reported back to you. Nothing runs with permissions skipped.
- A follow-up to the same agent repeats `--agent`/`--agents`/`--model` and adds `--resume <session id>`. Resuming without them drops the agent's tool limits (tested).
- The files are deleted with the Delete tool when no follow-up is pending.

See [security.md](security.md) for the checks applied before a command is built.
