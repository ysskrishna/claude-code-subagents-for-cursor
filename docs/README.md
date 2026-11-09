# Documentation

The short version is in the [README](../README.md).

| Guide | What is in it |
|---|---|
| [cursor-setup.md](cursor-setup.md) | Install as a Cursor plugin |
| [skills-sh-setup.md](skills-sh-setup.md) | Install with `npx skills` |
| [gh-cli-setup.md](gh-cli-setup.md) | Install with `gh skill` |
| [manual-setup.md](manual-setup.md) | Copy the folder yourself |
| [usage.md](usage.md) | Using the skill, verifying it, what to expect |
| [how-it-works.md](how-it-works.md) | Agent lookup, model mapping, how the `claude` command is built |
| [permissions.md](permissions.md) | Run without approval prompts |
| [troubleshooting.md](troubleshooting.md) | Symptoms and fixes |
| [security.md](security.md) | What the skill can do and how it is limited |
| [development.md](development.md) | Check scripts, CI, releases |

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
| 2026-11-09 | 3.29.9 | 2.1.318 | `--agent` resolved from the Shell tool's `working_directory` and from a subfolder of it; brief read through stdin from a file in Cursor's project folder; the three check scripts. Whether Cursor prompts was not tested by script |

These versions will age. If something behaves differently on yours, [open an issue](https://github.com/ysskrishna/claude-code-subagents-for-cursor/issues/new/choose) with your versions.

## When you do not need this

- If you turn BYOK off, Cursor's native subagents may honor their `model:` again (reported by Cursor staff; verify on your setup).
- If Cursor fixes the pinning natively, this skill becomes unnecessary. Check the release notes before installing.
