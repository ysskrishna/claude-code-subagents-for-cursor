# Changelog

## 0.1.0 - 2026-10-31

Initial release.

- `/use-claude-code-subagents` command: runs your custom Cursor subagents through Claude Code so each one runs on the `model:` in its own agent file.
- Agent resolution across `.cursor/agents`, `.claude/agents` and `.codex/agents` at project and user level, using Cursor's documented precedence (project beats user; `.cursor/` beats `.claude/` beats `.codex/`).
- Model mapping: full Anthropic IDs pass through; Cursor effort suffixes (`-low`/`-medium`/`-high`/`-xhigh`/`-max`, `-fast`, `-thinking*`, `[effort=…]`) are stripped; Claude Code aliases (`haiku`, `sonnet`, `opus`) pass through; `inherit` and non-Anthropic models fall back to Cursor's Task tool.
- Cursor-format agents (`.cursor/agents`, `.codex/agents`) are passed to Claude Code inline via `--agents`.
- Safe permissions: `--permission-prompts none` by default, `--permission-mode acceptEdits` only for editing agents.
- CI validates both manifests against Cursor's vendored plugin schemas.
