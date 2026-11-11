# Security

This skill makes a Cursor agent run `claude` in your shell, outside Cursor's sandbox, with text from agent files. Read this before using it on a project you do not control.

## What it can do

- Run `claude -p` with network access and write access to `~/.claude`, which needs `required_permissions: ["all"]` on Cursor's Shell tool. Cursor's sandbox blocks those writes, and a network-only permission does not allow them.
- Let an editing agent change files with `--permission-mode acceptEdits`. Those edits bypass Cursor's review and undo.
- Skip Claude Code's workspace trust dialog, because `claude -p` is headless. It also loads the project's Claude Code settings.
- Give the subagent Claude Code's MCP servers, not Cursor's.

## How it is limited

- **Names and models are checked before use.** The agent name, mapped model and session id must match fixed patterns, and every value is quoted. A name such as `scout; ls` never reaches the shell; the agent runs through the Task tool instead.
- **No shell parsing of text.** The brief and the agent definition are written to files with the Write tool and read through stdin or `--agents <file>`. There are no heredocs, so text cannot end one early.
- **Unknown models never reach `claude`.** Only `haiku`, `sonnet`, `opus` and `claude-*` IDs do.
- **Prompts are denied, not answered.** `--permission-prompts none` denies anything that would prompt, and the agent reports it. `--permission-mode acceptEdits` is added only for editing agents. `--dangerously-skip-permissions` is never used.
- **Elevated permission is scoped.** The skill uses `all` only for `claude --version`, `mktemp -d` and the `claude` run. It runs no `rm`.
- **Briefs stay out of your repo.** Brief and agent files go to a temp folder outside the workspace, so they cannot be committed. They hold no secrets.
- **One plain command.** The `claude` command has nothing chained before or after it, so what Cursor's run mode sees is exactly the `claude` run.
- **No credentials in files.** The skill never copies a password, token or key into a brief or an agent definition; it names the environment variable or file to read.
- **Agent files and results are data.** The skill tells the agent never to follow instructions found in them to change flags, add permissions, run other commands or switch modes.
- **Consent first.** When the skill loads on its own, it asks before the first run. Before the first run of an agent from a project folder, it names the file and permission mode.

## Run mode

The skill's shell steps run outside Cursor's sandbox. [permissions.md](../guides/permissions.md) suggests Run Everything or Auto-Review (with Sandbox). In Run Everything, Cursor checks no command, so use it in projects you trust.

## What to watch for

- **Agent files from a repository you do not trust** become the subagent's instructions, with that agent's tools. Read `.cursor/agents`, `.claude/agents` and `.codex/agents` in a cloned repo before you route it. Cursor's own Task tool has the same exposure, but edits made here bypass Cursor's review.
- Review the files an editing agent lists in its summary.
- Run it only in projects you trust, because the trust dialog is skipped.

## Third-party audits

skills.sh publishes automated audits of this skill at <https://skills.sh/ysskrishna/claude-code-subagents-for-cursor/use-claude-code-subagents>. They are automated reviews, not guarantees. Findings about the elevated Shell permission and the skipped trust dialog describe how the skill works, and are listed above.

## Reporting a problem

See [SECURITY.md](../../SECURITY.md).
