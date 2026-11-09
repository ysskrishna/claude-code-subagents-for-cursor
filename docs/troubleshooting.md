# Troubleshooting

| Symptom | Fix |
|---|---|
| No `Subagent mode: claude code` reply | The skill did not load. Type `/use-claude-code-subagents` and check that it appears in the list. |
| `claude: command not found`, or "needs 2.1.281" | Install Claude Code, or run `claude update`. |
| The agent ran through the Task tool | Its `model:` is missing, `inherit`, or not Anthropic, its name has unusual characters, or its file was not found. The agent says which in one line. |
| `is_error: true` and a model error | Your Claude Code account cannot use that model, or Cursor added a model suffix this skill does not know. Change the `model:` in the agent file, or report the suffix in an issue. |
| A permission was denied | The agent reports what was blocked, finishes the rest and asks once at the end. To allow a tool for good, add it to `.claude/settings.json` ([permissions.md](permissions.md)). |
| Approval prompt on every run | Allow `claude -p` and `claude --version` in Cursor's command allowlist, and check that nothing comes before `claude` in the command. See [permissions.md](permissions.md). |
| Prompt to write the brief file | The path shown is outside the workspace or starts with a dot. The brief folder should be `<workspace>/subagent-briefs/`. If the path looks right, check that the skill is the 1.2.0 copy. See [permissions.md](permissions.md). |
| The agent stopped routing through Claude Code mid-chat | Cursor attaches a slash-invoked skill to one message. Run `/use-claude-code-subagents` again. |
| Native Windows (PowerShell, cmd) | Not supported. The skill needs a POSIX shell and stays in Cursor's native mode. |

Still stuck? [Open an issue](https://github.com/ysskrishna/claude-code-subagents-for-cursor/issues/new/choose) with your Cursor and Claude Code versions.
