# Run without approval prompts

Cursor asks for approval before it runs shell commands, calls MCP tools, fetches URLs and writes files outside the workspace. This guide covers the Cursor run mode to pick so subagent runs go through without a prompt each time.

## Suggested setup

Open Cursor Settings, Agents, Approvals & Execution, and choose a run mode from the dropdown:

| Run mode | What it does | When to pick it |
|---|---|---|
| **Run Everything (Unsandboxed)** | Runs every agent command without asking. | You want no prompts and accept that all agent commands run unchecked. |
| **Auto-Review (with Sandbox)** | Commands run in the sandbox, or go through a safety check by a model on Cursor's backend. | You want a safety net. This is the suggested default. |

Why these two: a `claude -p` run needs network access and writes to `~/.claude`, which the sandbox blocks. So the skill runs it outside the sandbox (`required_permissions: ["all"]`), and only these two modes handle that without a rule for each command. If Auto-Review asks anyway, approve the command, or switch to Run Everything.

The **Allowlist** and **Allowlist (with Sandbox)** modes are not supported. They run only commands you list one by one, and a subagent run uses several commands (`claude --version`, `mktemp`, `claude -p`), so they ask again and again.

## What the skill does to keep prompts down

- The `claude` command is one plain command that starts with `claude`: no `cd`, `export`, pipe or `;` around it. The skill sets the Shell tool's `working_directory` instead of using `cd`.
- Briefs and agent definitions go to a temporary folder made with `mktemp -d`, outside your workspace, so they never end up in your repo or your commits. The skill leaves them in place and the operating system clears its temp folder.
- No delete step, because deleting can make Cursor ask when File-Deletion Protection is on.
- No secrets in commands or files.

## Other prompts

These are not caused by the skill. Settings control them:

| Prompt | How to stop it |
|---|---|
| A browser or other MCP tool the main agent calls | `mcpAllowlist` in `permissions.json`, with entries such as `server:tool`. Allow only the tools you use, and not send, delete or post tools. |
| Fetching a URL | Add the domain to the fetch domain list in Settings. |
| Writing a file outside the workspace (the brief in the temp folder) | Cursor's External-File Protection setting. Turning it off applies to every agent write, not only this skill's. |
| Deleting a file | Cursor's File-Deletion Protection setting. The skill does not delete. |
| Writing to a dot-folder | Cursor's dot-file protection setting. |

A team admin's Run Mode settings in the Cursor dashboard override local settings.

## Denials inside Claude Code

The skill runs `claude -p` with `--permission-prompts none`, so anything Claude Code would ask about is denied and listed in the result. The skill reports what was blocked, finishes the rest, and asks once at the end.

To allow a tool for good, add a rule to the project's `.claude/settings.json`:

```json
{
  "permissions": {
    "allow": ["WebSearch", "WebFetch(domain:docs.example.com)"]
  }
}
```

Rule syntax is in [Claude Code's permissions guide](https://code.claude.com/docs/en/permissions).

## Trade-offs

- In **Run Everything**, no command is checked, not only this skill's. Use it in projects you trust.
- Edits made by a routed subagent bypass Cursor's review and undo. See [security.md](../reference/security.md).

## Check it works

Run a subagent and look at the shell steps. The brief appears in a folder named `claude-subagent.XXXXXX` under your temp folder (`echo "$TMPDIR"` shows where). If Cursor still asks, read the command it shows: anything before the word `claude` is the cause.
