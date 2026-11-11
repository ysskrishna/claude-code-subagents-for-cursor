# Documentation

The short version is in the [README](../README.md).

**Install** (pick one route)

| Guide | What is in it |
|---|---|
| [install/cursor-setup.md](install/cursor-setup.md) | Install as a Cursor plugin |
| [install/skills-sh-setup.md](install/skills-sh-setup.md) | Install with `npx skills` |
| [install/gh-cli-setup.md](install/gh-cli-setup.md) | Install with `gh skill` |
| [install/manual-setup.md](install/manual-setup.md) | Copy the folder yourself |

**Guides**

| Guide | What is in it |
|---|---|
| [guides/usage.md](guides/usage.md) | Using the skill, verifying it, what to expect |
| [guides/permissions.md](guides/permissions.md) | Run modes that avoid approval prompts |
| [guides/troubleshooting.md](guides/troubleshooting.md) | Symptoms and fixes |

**Reference**

| Guide | What is in it |
|---|---|
| [reference/how-it-works.md](reference/how-it-works.md) | Agent lookup, model mapping, how the `claude` command is built |
| [reference/security.md](reference/security.md) | What the skill can do and how it is limited |

**Contributing**

| Guide | What is in it |
|---|---|
| [contributing/development.md](contributing/development.md) | Check scripts, CI, releases |
| [contributing/release-state.md](contributing/release-state.md) | What is already published |

## Requirements

- Cursor desktop, running locally. Cloud Agents have no `claude` CLI.
- Claude Code 2.1.281 or later, installed and signed in. Follow Anthropic's [setup guide](https://code.claude.com/docs/en/setup), then check with `claude --version`. Runs bill your Claude Code account.
- A POSIX shell (the `<` redirect): macOS or Linux.

## Platforms and what was checked

| Platform | Status |
|---|---|
| macOS | The `claude` commands the skill runs, the `skills.sh` and `gh` install routes, and the check scripts were run. The Cursor plugin install and the slash command in the Cursor UI are checked by hand before each release. |
| Linux | The `skills.sh` and `gh` install routes and the validation run in CI. Running subagents through Claude Code on Linux is not tested. |
| Windows (native PowerShell or cmd) | Not supported. The skill needs a POSIX shell and stays in Cursor's native mode. |
| WSL | Not tested. |
| Cloud Agents | Not supported (no `claude` CLI). |

### Last verified

| Date | Cursor | Claude Code | What was run |
|---|---|---|---|
| 2026-11-02 | 3.27.22 | 2.1.310 | Briefs through stdin (shell characters and lines such as `BRIEF` arrive unchanged); `--agents <file>` with stdin; `--resume` with and without `--agent`; both install routes |
| 2026-11-09 | 3.29.9 | 2.1.318 | `--agent` resolved from the Shell tool's `working_directory` and from a subfolder of it; brief read through stdin from a file; the three check scripts. Cursor's prompts were checked by hand: a Write under `~/.cursor/projects/` still asked, so briefs now go inside the workspace (not yet re-checked) |

These versions will age. If something behaves differently on yours, [open an issue](https://github.com/ysskrishna/claude-code-subagents-for-cursor/issues/new/choose) with your versions.

## When you do not need this

- If you turn BYOK off, Cursor's native subagents may honor their `model:` again (reported by Cursor staff; verify on your setup).
- If Cursor fixes the pinning natively, this skill becomes unnecessary. Check the release notes before installing.
