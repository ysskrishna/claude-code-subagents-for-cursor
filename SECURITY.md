# Security policy

## Reporting a vulnerability

Please do not open a public issue for a security problem.

Report it privately through GitHub: open the [Security tab](https://github.com/ysskrishna/claude-code-subagents-for-cursor/security) and choose **Report a vulnerability**. Include what you found, how to reproduce it, and the Cursor and Claude Code versions you used.

You can expect a first reply within 7 days. If the report is confirmed, the fix ships in a new release and the CHANGELOG credits you unless you ask not to be named.

## Supported versions

Only the latest release gets fixes.

## What counts

This repo ships a skill (instructions for an AI agent) and some scripts. Examples of in-scope reports:

- Text in an agent file, brief or subagent result that makes the skill run a command or use a permission it should not.
- A way around the name, model or session id checks.
- A script in `scripts/` or a workflow in `.github/` that can be abused.

How the skill is limited, and what it cannot limit, is described in [docs/security.md](docs/security.md). Behavior listed there as by design (the elevated Shell permission, the skipped trust dialog, edits that bypass Cursor's review) is not a vulnerability, but suggestions to narrow it are welcome as normal issues.
