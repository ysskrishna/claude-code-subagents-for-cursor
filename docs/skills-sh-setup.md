# skills.sh (npx skills)

## Install

```bash
npx skills add ysskrishna/claude-code-subagents-for-cursor -a cursor -g
```

This installs to `~/.agents/skills/`, which Cursor loads. Drop `-g` to install into the current project instead. The repo has one skill, so no `--skill` flag is needed. To list what the repo offers first:

```bash
npx skills add ysskrishna/claude-code-subagents-for-cursor --list
```

You also need Claude Code installed and signed in. See [Requirements](README.md#requirements).

## Verify

Open **Customize, Skills** in Cursor. Then follow [Verify it works](usage.md#verify-it-works).

## Update and remove

```bash
npx skills update
npx skills remove use-claude-code-subagents
```

## Notes

- Listing: <https://skills.sh/ysskrishna/claude-code-subagents-for-cursor>. skills.sh shows third-party security audits of the skill there. See [security.md](security.md).
- This route is run in CI (Linux) and by hand (macOS) with a throwaway `HOME`.
