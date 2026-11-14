# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.2] - 2026-11-14

The product name on Cursor and ClawHub is Claude Code Subagents for Cursor. A version tag also publishes the npm package.

### Changed

- **Display name.** `.cursor-plugin/plugin.json` `displayName` and `openclaw.plugin.json` `name` are **Claude Code Subagents for Cursor**. The npm package stays `@ysskrishna/claude-code-subagents-for-cursor`. The OpenClaw id stays `claude-code-subagents-for-cursor`.
- **Claude Code plugin id stays `cursor-subagent-models`.** `claude plugin validate` rejects `claude-code-subagents-for-cursor` because a third-party plugin name cannot start with `claude-`. That id is only the Claude Code install name. It is not the package name.

### Added

- **npm trusted publishing.** Pushing a `v*` tag runs [`.github/workflows/publish-npm.yml`](.github/workflows/publish-npm.yml), separate from the GitHub Release workflow. It publishes `@ysskrishna/claude-code-subagents-for-cursor` with GitHub's OIDC token. No npm token is stored in the repo. The package's trusted publisher on npmjs.com has to name `publish-npm.yml` and the `prod` environment before the first successful publish.

## [1.3.1] - 2026-11-14

The same skill can now be loaded as a Claude Code plugin, an npm package, and an OpenClaw bundle. Cursor install routes are unchanged.

### Added

- **Claude Code plugin.** `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` name it `cursor-subagent-models` (one entry, `source` `./`). Claude Code rejects a third-party name that starts with `claude-` or reads as Anthropic's own, so this is not the Cursor plugin name. Cursor still reads `.cursor-plugin/`. The skill id stays `use-claude-code-subagents`. buildwithclaude closed the earlier listing because only the Cursor manifest existed.
- **npm package** `@ysskrishna/claude-code-subagents-for-cursor`. Claude Code can fetch a marketplace plugin from npm. The package is not a Cursor install, and npm downloads are not Cursor Directory views.
- **OpenClaw bundle.** `openclaw.plugin.json`, plus `openclaw.compat` in `package.json` (same pins as `@ysskrishna/ai-agent-skills`). `scripts/publish_clawhub.py` stages one host manifest for ClawHub. Nothing is published from CI.

## [1.3.0] - 2026-11-12

Briefs stay out of your repo, two supported run modes, a tidier `docs/` folder, and an example project.

### Changed

- **Briefs go to a temp folder, not the workspace.** The skill makes a folder with `mktemp -d` and writes the brief and agent files there, so nothing lands in your repo or your commits. The `subagent-briefs/` folder and its `.gitignore` entry from 1.2.0 are gone. The files stay in place and the operating system clears them.
- **Only two run modes are supported: Run Everything (Unsandboxed) and Auto-Review (with Sandbox).** The allowlist route is removed from the docs and the skill, because it needs an entry for every command. [`docs/guides/permissions.md`](docs/guides/permissions.md) now only says how to set the mode, plus the other prompts and Claude Code denials.
- **`docs/` is grouped into `install/`, `guides/`, `reference/` and `contributing/`.** Links to the old paths (for example `docs/permissions.md`) no longer work; use the new ones. The README, `AGENTS.md`, issue templates and `scripts/validate.sh` follow the new layout, and `validate.sh` now also checks links in `examples/`.

### Added

- [`examples/subagents`](examples/subagents): a small project with a read-only `scout` agent (`haiku`) and an editing `proofreader` agent (`sonnet`), with a README on how an agent file is built and how to try them.

## [1.2.0] - 2026-11-09

Runs without approval prompts. Cursor asked for approval on most subagent runs because of how the commands were built, not because of a missing setting.

### Fixed

- **`claude` commands start with `claude`.** Agents put `cd <dir> &&` or `export VAR=...;` in front of the command. Cursor's allowlist matches the start of a command, so those runs never matched an allowlisted `claude -p`. The skill now sets the Shell tool's `working_directory` instead of using `cd`, and keeps the command a single plain command.
- **Briefs are written to `<workspace>/subagent-briefs/<id>/`**, not `$TMPDIR`. Writing outside the workspace triggers Cursor's External-File Protection, and that includes `~/.cursor/projects/`, which counts as inside the boundary for reads only. Add `subagent-briefs/` to your `.gitignore`. The `mktemp` folder is the fallback when there is no workspace.
- **No `mktemp -d`, `rm -rf` or delete steps** in the normal path. The skill leaves its brief files in place, so there are fewer commands to approve.
- **Denied tools no longer stop the run.** When `permission_denials` is not empty, the skill lists what was blocked, finishes the work that does not depend on it, and asks once at the end.

### Security

- **No credentials in briefs or agent definitions.** The skill names the environment variable or file to read instead of copying the secret into a file.
- The skill's own commands are limited to `claude --version` and `claude -p`, with no heredoc, `cd`, `export`, pipe or `;`.

### Added

- [`docs/guides/permissions.md`](docs/guides/permissions.md): what causes approval prompts, the recommended Auto-review setup, an Allowlist-mode setup, and a Claude Code settings file for denied tools.
- A "Run without approval prompts" section in the README.
- `scripts/dev_install.sh`: copy this checkout into `~/.cursor/plugins/local/` to try changes in Cursor before they are published, with `--remove` to undo. It warns when another copy of the skill is installed.

## [1.1.0] - 2026-11-02

Safer commands, a shorter README, and the detail moved into `docs/`.

### Security

- **Briefs no longer pass through the shell.** The brief and the agent definition are written to files with the Write tool, and Claude Code reads them from stdin or `--agents <file>`. Before, a line in a brief that matched the heredoc delimiter could end it early and run the rest as shell.
- **Names, models and session ids are checked before use**, then quoted. A name such as `scout; ls` now falls back to Cursor's Task tool instead of reaching the shell.
- **Agent files and subagent results are treated as data.** The skill tells the agent never to follow instructions found in them to change flags, add permissions or run other commands.
- **Follow-ups keep the agent's tool limits.** A resumed run now repeats `--agent`/`--agents`; without them Claude Code drops the agent's limits (tested).
- Added [`SECURITY.md`](SECURITY.md) and [`docs/reference/security.md`](docs/reference/security.md), which explain what the skill can do and how it is limited.

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

[1.3.2]: https://github.com/ysskrishna/claude-code-subagents-for-cursor/compare/v1.3.1...v1.3.2
[1.3.1]: https://github.com/ysskrishna/claude-code-subagents-for-cursor/compare/v1.3.0...v1.3.1
[1.3.0]: https://github.com/ysskrishna/claude-code-subagents-for-cursor/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/ysskrishna/claude-code-subagents-for-cursor/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/ysskrishna/claude-code-subagents-for-cursor/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/ysskrishna/claude-code-subagents-for-cursor/releases/tag/v1.0.0
