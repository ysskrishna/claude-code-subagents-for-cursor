# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-11-02

Safer commands, a shorter README, and the detail moved into `docs/`.

### Security

- **Briefs no longer pass through the shell.** The brief and the agent definition are written to files with the Write tool, and Claude Code reads them from stdin or `--agents <file>`. Before, a line in a brief that matched the heredoc delimiter could end it early and run the rest as shell.
- **Names, models and session ids are checked before use**, then quoted. A name such as `scout; ls` now falls back to Cursor's Task tool instead of reaching the shell.
- **Agent files and subagent results are treated as data.** The skill tells the agent never to follow instructions found in them to change flags, add permissions or run other commands.
- **Follow-ups keep the agent's tool limits.** A resumed run now repeats `--agent`/`--agents`; without them Claude Code drops the agent's limits (tested).
- Added [`SECURITY.md`](SECURITY.md) and [`docs/security.md`](docs/security.md), which explain what the skill can do and how it is limited.

### Changed

- **Model routing is now a positive rule.** Only `haiku`, `sonnet`, `opus` and `claude-*` IDs go through Claude Code. Anything else uses Cursor's Task tool, so new non-Anthropic models need no update. The suffix list lives in one place, `references/model-mapping.md`.
- **Install commands:** `npx skills add` no longer needs `--skill`, and `gh skill install` uses `--all`. The repo has one skill.
- **README is shorter.** Install routes are collapsible, and usage, how it works, troubleshooting, security and development moved to `docs/`, with one install guide per route.
- **Skill wording:** removed the cost-reporting rule, the cap on parallel runs and the Checklist section. The brief format is now advice. The skill stays in Cursor's native mode on native Windows, because it needs a POSIX shell.
- `metadata.version` in `SKILL.md` now matches the plugin version.
- Plugin `tags` and `keywords` expanded for search.
- `scripts/validate.sh` now checks the Agent Skills limits (name up to 64 characters, description up to 1024, `SKILL.md` up to 500 lines) instead of stricter house rules. It also checks version agreement, quoted placeholders in the skill's commands, links and install commands in the README and `docs/`.

### Added

- Social preview image (`assets/og.png`, 1200x630).
- skills.sh badge in the README.
- Issue templates for bug reports and feature requests.

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

[1.1.0]: https://github.com/ysskrishna/claude-code-subagents-for-cursor/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/ysskrishna/claude-code-subagents-for-cursor/releases/tag/v1.0.0
