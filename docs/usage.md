# Usage

## Switch it on

```text
/use-claude-code-subagents
```

The agent replies `Subagent mode: claude code`. From then on, every custom subagent you ask for runs via Claude Code on its own model. Say **"use cursor subagents"** to switch back to Cursor's native Task tool.

You can also skip the slash command and describe the problem ("why are all my subagents on Opus?"). The skill can load on its own. When it does, it asks for a yes before the first run, because runs bill your Claude Code account and edits bypass Cursor's review. Typing the slash command counts as consent.

Cursor attaches a slash-invoked skill to that one message ([docs](https://cursor.com/docs/skills)). If the agent stops routing subagents through Claude Code later in the chat, run `/use-claude-code-subagents` again.

## Verify it works

1. Pick a custom subagent whose `model:` differs from your chat's model.
2. Run `/use-claude-code-subagents`, then ask the chat to run that agent on a small task.
3. The reply ends with a line like `scout ran on claude-haiku-5-5`. That model comes from Claude Code's `modelUsage`, not from the agent file, so it shows what actually ran.

A full worked run is in [`example.md`](../skills/use-claude-code-subagents/references/example.md).

## What to expect

- Subagents show up as terminal commands, not Cursor's subagent cards.
- No mid-run steering. A follow-up goes to the same agent through `--resume`.
- A subagent cannot ask you mid-run. It returns the question and the parent asks you.
- **Edits made by a routed subagent bypass Cursor's review and undo.** The agent lists changed files in its summary. Review them.
- `claude -p` skips Claude Code's workspace trust dialog. Use this only in projects you trust.
- The first run of `claude` in a session may show a Cursor approval prompt (Claude Code needs network and writes to `~/.claude`, outside Cursor's sandbox). Allow it once, or allowlist `claude` in Cursor's run settings.
- The subagent sees Claude Code's MCP config, not Cursor's. An agent that relies on a Cursor-only MCP server may lack that tool.
- Agents whose `model:` is missing, `inherit`, or not Anthropic keep using Cursor's Task tool. The agent says so in one line.
