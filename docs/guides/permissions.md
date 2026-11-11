# Run without approval prompts

Cursor asks for approval before it runs shell commands, calls MCP tools, fetches URLs and writes files outside the workspace. This guide shows how to let subagent runs proceed without a prompt each time, and why some prompts remain.

## Recommended setup

1. Use Cursor's **Auto-review** run mode, with the sandbox on. Allowlisted commands run at once; other commands run in the sandbox or go through Cursor's safety check.
2. Allow these two commands (Cursor Settings, Agents, Approvals & Execution, Command Allowlist):

   ```text
   claude -p
   claude --version
   ```

Together with skill version 1.2.0 or later, this is enough for subagent runs. The rest of this page explains the details and the optional extras.

## Why prompts happened

Cursor's allowlist matches the **start** of a command, case-sensitively. These all failed to match `claude -p`:

| Command the agent ran | Starts with |
|---|---|
| `cd /work/app && claude -p ...` | `cd` |
| `export KEY=... ; claude -p ...` | `export` |
| `mktemp -d ...`, `rm -rf ...` | `mktemp`, `rm` |

Briefs written under `$TMPDIR`, or in Cursor's own `~/.cursor/projects/` folder, are outside the workspace and triggered Cursor's External-File Protection as well. (Cursor's docs count `~/.cursor/projects/` as inside the boundary for **reads** only.)

Skill 1.2.0 fixes what the skill controls:

- The `claude` command starts with `claude`. The skill sets the Shell tool's `working_directory` instead of using `cd`, and keeps secrets out of the command.
- Briefs go to `<workspace root>/subagent-briefs/<id>/`: inside the workspace, so External-File Protection does not ask, and with no leading dot, so dot-file protection does not ask. Add `subagent-briefs/` to your `.gitignore`. The `mktemp` folder is only a fallback for when there is no workspace.
- No `mktemp` or `rm -rf` in the normal path. The skill leaves its files in place, because deleting asks when File-Deletion Protection is on.

## Auto-review mode

In Auto-review, a command that is not on the allowlist is checked by a model on Cursor's backend. `claude` cannot run in the sandbox (it needs network and writes to `~/.claude`), so it always depends on the allowlist or that check. The allowlist is the only rule that does not depend on a model's judgment, so use it.

### Allow the commands

Either add them in Settings, or put them in a `permissions.json` file. Use `<workspace>/.cursor/permissions.json` for one project, or `~/.cursor/permissions.json` for every project:

```json
{
  "terminalAllowlist": ["claude -p", "claude --version"]
}
```

A `terminalAllowlist` key in `permissions.json` **replaces** the allowlist in Settings. Entries in the user file and the project file are combined with each other, but the Settings list stops applying. Copy your existing entries into the file when you add it ([reference](https://cursor.com/docs/reference/permissions.md)).

### Without an allowlist (steering only)

If you would rather not allowlist `claude -p`, add a sentence for the safety check:

```json
{
  "autoRun": {
    "allow_instructions": [
      "Allow `claude -p` and `claude --version` when they run a custom subagent for the current project."
    ]
  }
}
```

This steers the check and does not enforce anything. An occasional prompt or block is normal.

## Allowlist mode

In **Allowlist** mode only exact allowlist entries run without approval, and `autoRun` instructions have no effect. Use the `terminalAllowlist` above. Commands outside the allowlist ask every time.

## Other prompts

These are not caused by the skill. Settings or `permissions.json` control them:

| Prompt | How to stop it |
|---|---|
| A browser or other MCP tool the main agent calls | `mcpAllowlist` in `permissions.json`, with entries such as `server:tool`. Allow only the tools you use, and not send, delete or post tools. |
| Fetching a URL | Add the domain to the fetch domain list in Settings. |
| Writing a file outside the workspace | Cursor's External-File Protection setting. The skill no longer writes outside the workspace. Turning the setting off also works, but it applies to every agent write, not only this skill's. |
| Deleting a file | Cursor's File-Deletion Protection setting. The skill does not delete. |
| Writing to a dot-folder | Cursor's dot-file protection setting. |

A team admin's Run Mode settings in the Cursor dashboard override local files.

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

- Allowing `claude -p` allows **any** command that starts with it, including flags the skill never uses. The skill never uses `--dangerously-skip-permissions`, but the allowlist cannot stop a command that does, because matching looks only at the start. If that is too broad for you, use the steering route above and accept the occasional prompt.
- Edits made by a routed subagent bypass Cursor's review and undo. See [security.md](../reference/security.md).

## Check it works

Run a subagent and look at the shell step. A command that matched shows `This command ran outside the sandbox ... because it matched the user's command allowlist`. The brief file appears under `<workspace>/subagent-briefs/`. If Cursor still asks, read the command it shows: anything before the word `claude` is the cause.
