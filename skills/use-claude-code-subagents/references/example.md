---
title: Worked example
impact: MEDIUM
tags: example, scout, haiku, cursor-format
---

## Worked example

All inputs below are invented for illustration. The output field names (`result`, `is_error`, `modelUsage`, `permission_denials`, `session_id`) match real `claude -p --output-format json` output.

**Setup.** The parent chat runs on Opus with a personal Anthropic key on. The project has `.cursor/agents/scout.md`:

```markdown
---
name: scout
description: Finds code and summarizes it. Read-only.
model: claude-haiku-5-5-medium
readonly: true
---
You find code. Return file paths and a short summary. Never edit files.
```

**User:** `/use-claude-code-subagents` then "use scout to find where retries are configured in /work/api".

1. **Consent.** The user typed the slash name, so no confirm question.
2. **Reply and preflight.** `Subagent mode: claude code`. `claude --version` prints 2.1.310, which is at least 2.1.281.
3. **Resolve.** `/work/api/.cursor/agents/scout.md` is the first match. Cursor format, so it goes through `--agents`.
4. **Map.** `claude-haiku-5-5-medium` ends in `-medium`; strip it to `claude-haiku-5-5`. `readonly: true`, so no `--permission-mode`.
5. **Run.** Write the temp file, run, remove it:

```bash
f=$(mktemp "${TMPDIR:-/tmp}/claude-agents.XXXXXX")
cat > "$f" <<'JSON'
{ "scout": { "description": "Finds code and summarizes it. Read-only.", "prompt": "You find code. Return file paths and a short summary. Never edit files.", "model": "claude-haiku-5-5" } }
JSON
claude -p "$(cat <<'BRIEF'
Goal: find where retry settings are configured.
Search: /work/api
Return: up to 5 file paths, one line each, then a 2 line summary.
BRIEF
)" --agents "$f" --agent scout --model claude-haiku-5-5 --permission-prompts none --output-format json
rm -f "$f"
```

6. **Report.** The JSON has `is_error: false`, `permission_denials: []` and `modelUsage` with the single key `claude-haiku-5-5`. The reply is the contents of `result`, then one line: "scout ran on claude-haiku-5-5". Cost is not reported.

**If it had failed.** With `model: composer-2` the skill never calls `claude`: it runs scout through the Task tool and says "scout uses a non-Anthropic model, so it runs through Cursor's Task tool."
