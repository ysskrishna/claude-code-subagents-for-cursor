# Claude Code Subagents for Cursor

<img src="assets/logo-lockup.png" alt="Claude Code Subagents for Cursor" width="520">

[![Validate](https://github.com/ysskrishna/claude-code-subagents-for-cursor/actions/workflows/validate.yml/badge.svg)](https://github.com/ysskrishna/claude-code-subagents-for-cursor/actions/workflows/validate.yml) [![Test installs](https://github.com/ysskrishna/claude-code-subagents-for-cursor/actions/workflows/test-installs.yml/badge.svg)](https://github.com/ysskrishna/claude-code-subagents-for-cursor/actions/workflows/test-installs.yml) [![License: MIT](https://img.shields.io/github/license/ysskrishna/claude-code-subagents-for-cursor)](https://github.com/ysskrishna/claude-code-subagents-for-cursor/blob/main/LICENSE) [![GitHub release](https://img.shields.io/github/v/release/ysskrishna/claude-code-subagents-for-cursor?label=release)](https://github.com/ysskrishna/claude-code-subagents-for-cursor/releases) [![Author site](https://img.shields.io/badge/author-ysskrishna.space-informational)](https://ysskrishna.space)

[![skills.sh](https://skills.sh/b/ysskrishna/claude-code-subagents-for-cursor)](https://skills.sh/ysskrishna/claude-code-subagents-for-cursor)

A Cursor skill that runs your **custom subagents through Claude Code**, so each one runs on the `model:` written in its own agent file instead of the parent chat's model. Invoke it with `/use-claude-code-subagents`.

## Overview

In Cursor, custom subagents (`.cursor/agents/*.md`, `.claude/agents/*.md`, `.codex/agents/*.md`) declare a `model:` in their frontmatter, but the Task tool runs them on the **parent chat's model** in two cases:

- a **personal Anthropic API key (BYOK)** is on ([confirmed by Cursor staff](https://forum.cursor.com/t/opus-spawns-only-opus-subagents-despite-different-instructions/166870)), or
- the agent's model is not enabled in Cursor.

An agent you set up for Haiku then bills at Opus rates. Claude Code, run headlessly from Cursor's Shell tool, does honor the `model:` in agent files. This skill routes custom subagents through `claude -p` for the rest of the chat, and every run reports the model it actually ran on.

**You need:** Cursor desktop running locally (Cloud Agents have no `claude` CLI), Claude Code installed and signed in ([setup guide](https://code.claude.com/docs/en/setup)), and a POSIX shell (macOS, Linux). Runs bill your Claude Code account. The skill checks the Claude Code version for you.

## Installation

Pick one route. All of them install the same skill.

<a id="cursor-plugin"></a>

<details open>
<summary><b>Cursor plugin (recommended)</b></summary>

In Cursor, open **Customize, Plugins, Add, From GitHub Repository** and enter:

```text
github.com/ysskrishna/claude-code-subagents-for-cursor
```

Choose **user scope** to get the skill in every project, or project scope to commit it for a team. More in [docs/cursor-setup.md](docs/cursor-setup.md).

</details>

<a id="skillssh-npx-skills"></a>

<details>
<summary><b>skills.sh (npx skills)</b></summary>

```bash
npx skills add ysskrishna/claude-code-subagents-for-cursor -a cursor -g
```

Installs to `~/.agents/skills/`, which Cursor loads. Drop `-g` to install into the current project. Update with `npx skills update`. Remove with `npx skills remove use-claude-code-subagents`. More in [docs/skills-sh-setup.md](docs/skills-sh-setup.md).

</details>

<a id="github-cli-gh-skill"></a>

<details>
<summary><b>GitHub CLI (gh skill)</b></summary>

```bash
gh skill install ysskrishna/claude-code-subagents-for-cursor --all --agent cursor --scope user
```

Installs to `~/.cursor/skills/`. Without `--agent cursor`, `gh` installs for GitHub Copilot. Update with `gh skill update`. More in [docs/gh-cli-setup.md](docs/gh-cli-setup.md).

</details>

<a id="manual"></a>

<details>
<summary><b>Manual</b></summary>

Copy the [`skills/use-claude-code-subagents`](skills/use-claude-code-subagents) folder, including `references/`, to `~/.cursor/skills/` (user) or `<project>/.cursor/skills/` (project). More in [docs/manual-setup.md](docs/manual-setup.md).

</details>

## Usage

```text
/use-claude-code-subagents
```

The agent replies `Subagent mode: claude code`. From then on, each custom subagent you ask for runs through Claude Code on its own model, and the reply ends with a line like `scout ran on claude-haiku-5-5`. Say **"use cursor subagents"** to switch back to Cursor's Task tool.

More in [docs/usage.md](docs/usage.md): how the skill loads on its own, what to expect, and how to check it works.

<a id="run-without-approval-prompts"></a>

<details>
<summary><b>Run without approval prompts</b></summary>

Use Cursor's **Auto-review** run mode (with the sandbox on) and allow two commands in Cursor Settings, Agents, Approvals & Execution, Command Allowlist:

```text
claude -p
claude --version
```

Cursor's allowlist matches the start of a command, so the skill keeps `claude` first (no `cd` or `export` in front) and writes briefs inside Cursor's project folder, not `$TMPDIR`. In **Allowlist** mode the same two entries work; the `autoRun` instructions only apply to Auto-review. If you use a `terminalAllowlist` key in `permissions.json`, it replaces the list in Settings, so copy your other entries into it. Details, other prompts (MCP tools, fetch) and trade-offs: [docs/permissions.md](docs/permissions.md).

</details>

## Documentation

| Guide | What is in it |
|---|---|
| [docs/README.md](docs/README.md) | Requirements, platforms, what is tested, when you do not need this |
| [docs/usage.md](docs/usage.md) | Using the skill, verifying it, what to expect |
| [docs/how-it-works.md](docs/how-it-works.md) | Agent lookup, model mapping, how the `claude` command is built |
| [docs/permissions.md](docs/permissions.md) | Run without approval prompts: Cursor run modes, allowlists, Claude Code settings |
| [docs/troubleshooting.md](docs/troubleshooting.md) | Symptoms and fixes |
| [docs/security.md](docs/security.md) | What the skill can do, how it is limited, what to watch for |
| [docs/development.md](docs/development.md) | Check scripts, CI, releases |

Reporting a vulnerability: see [SECURITY.md](SECURITY.md).

## Built and maintained by

Claude Code Subagents for Cursor is built and maintained by:

| | Name | GitHub | Role |
|---|------|--------|------|
| <img src="https://github.com/ysskrishna.png?size=120" width="60" height="60" alt="Y. Siva Sai Krishna"> | **Y. Siva Sai Krishna** | [@ysskrishna](https://github.com/ysskrishna) | Creator |


## Changelog

See [CHANGELOG](https://github.com/ysskrishna/claude-code-subagents-for-cursor/blob/main/CHANGELOG.md) for release history.

## Support

If you find this library helpful:

- ⭐ Star the repository
- 🐛 Report issues
- 🔀 Submit pull requests
- 💝 [Sponsor on GitHub](https://github.com/sponsors/ysskrishna)

## License

MIT © [Y. Siva Sai Krishna](https://github.com/ysskrishna) — see [LICENSE](https://github.com/ysskrishna/claude-code-subagents-for-cursor/blob/main/LICENSE) for details.

---

<p align="left">
  <a href="https://github.com/ysskrishna">Author's GitHub</a> •
  <a href="https://linkedin.com/in/ysskrishna">Author's LinkedIn</a> •
  <a href="https://ysskrishna.space">Author's site</a> •
  <a href="https://github.com/ysskrishna/claude-code-subagents-for-cursor/issues">Report Issues</a>
</p>
