# Example: two custom subagents

A tiny project to try the skill on. It has two agents on different models, and a few files for them to work on.

| Agent | `model:` | Access | Does |
|---|---|---|---|
| [`scout`](.cursor/agents/scout.md) | `haiku` | read-only | Finds files and code, returns paths and a short summary |
| [`proofreader`](.cursor/agents/proofreader.md) | `sonnet` | edits files | Fixes spelling and grammar in the Markdown files you name |

## How an agent file is built

A custom subagent is one Markdown file in `.cursor/agents/` (`.claude/agents/` and `.codex/agents/` also work). The frontmatter sets the agent up and the body is its instructions:

```markdown
---
name: scout
description: Finds files and code in the project and summarizes them. Read-only.
model: haiku
readonly: true
---

You find things in this project and report back. You never edit files.
```

- `name`: what you type to call it. Letters, digits, `.`, `_` and `-`.
- `description`: when to use it. Cursor and the skill read this.
- `model`: which model runs it. `haiku`, `sonnet`, `opus` or a full `claude-...` ID go through Claude Code. A missing or non-Anthropic model stays on Cursor's Task tool. See [how it works](../../docs/reference/how-it-works.md).
- `readonly: true`: the agent cannot edit files. Leave it out for an editing agent.

## Try it

1. Install the skill ([README](../../README.md#installation)) and make sure `claude` is installed and signed in.
2. Open this folder (`examples/subagents`) as the project in Cursor, so Cursor finds `.cursor/agents`. To use the agents in your own project, copy `.cursor/agents/*.md` into that project's `.cursor/agents/`, or into `~/.cursor/agents/` for every project.
3. In a chat, run `/use-claude-code-subagents`, then ask:
   - `use scout to find where retries are configured`. It should return `config/retry.yaml` and `notes/retry-plan.md`, and the reply ends with a line such as `scout ran on claude-haiku-5-5`.
   - `use proofreader to fix typos in notes/retry-plan.md`. It fixes the typos (`erors`, `Teh`) and lists the file it changed. Review the change: edits made this way bypass Cursor's review and undo. Run `git diff` to see it, and `git checkout -- notes/retry-plan.md` to put the typos back.

Each run is a terminal command, not a Cursor subagent card. [Usage](../../docs/guides/usage.md) says what to expect.
