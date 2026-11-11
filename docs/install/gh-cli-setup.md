# GitHub CLI (gh skill)

## Install

Needs a GitHub CLI version that has `gh skill`.

```bash
gh skill install ysskrishna/claude-code-subagents-for-cursor --all --agent cursor --scope user
```

This installs to `~/.cursor/skills/`. Without `--agent cursor`, `gh` installs for GitHub Copilot. Use `--scope project` to install into the current git repository instead. `--all` installs every skill in the repo (today that is one), so the command keeps working if a second skill is added.

You also need Claude Code installed and signed in. See [Requirements](../README.md#requirements).

## Verify

Open **Customize, Skills** in Cursor. Then follow [Verify it works](../guides/usage.md#verify-it-works).

## Update and remove

```bash
gh skill update
rm -rf ~/.cursor/skills/use-claude-code-subagents
```

## Notes

- This route is run in CI (Linux) and by hand (macOS) with a throwaway `HOME`.
