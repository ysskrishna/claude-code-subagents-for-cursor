# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-11-02

First stable release.

### Added

- **`use-claude-code-subagents` skill.** Runs your custom Cursor subagents through headless Claude Code so each one runs on the `model:` in its own agent file instead of the parent chat's model. Invoke it with `/use-claude-code-subagents`, or let it load when you describe the symptom. When it loads on its own, it asks for confirmation before the first run.
- **Agent resolution** across `.cursor/agents`, `.claude/agents` and `.codex/agents` at project and user level, using Cursor's documented precedence (project beats user; `.cursor/` beats `.claude/` beats `.codex/`).
- **Model mapping.** Full Anthropic IDs pass through; Cursor effort suffixes (`-low`, `-medium`, `-high`, `-xhigh`, `-max`, `-fast`, `-thinking*`, `[effort=...]`) are stripped; the aliases `haiku`, `sonnet` and `opus` pass through; `inherit`, missing and non-Anthropic models fall back to Cursor's Task tool. Evidence and untested edge cases are in `references/model-mapping.md`.
- **Safe defaults.** `--permission-prompts none` on every run, `--permission-mode acceptEdits` only for editing agents, and a Claude Code version check (2.1.281 or later) before the first run.
- **Shell-safe briefs.** Briefs go through a single-quoted heredoc, so `$VAR`, backticks and `$(...)` in a brief reach the agent unchanged. Cursor-format agents are passed through a randomized temp file that works on macOS and Linux and is removed after each run.
- **Worked example and trigger evals** (`references/example.md`, `evals/use-claude-code-subagents.json`).
- **Install routes:** the Cursor plugin marketplace, `npx skills add`, `gh skill install`, and a manual copy.
- **Logo and listing metadata:** mark and lockup (SVG and PNG), display name, category and tags in `.cursor-plugin/plugin.json`.
- **CI:** manifest and skill validation, install tests for the `skills` and `gh` routes, and a GitHub Release created from each `v*` tag.
- `LICENSE`, `CODEOWNERS` and `FUNDING.yml`.

[1.0.0]: https://github.com/ysskrishna/claude-code-subagents-for-cursor/releases/tag/v1.0.0
