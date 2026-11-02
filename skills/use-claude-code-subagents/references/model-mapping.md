---
title: Model mapping evidence and edge cases
impact: HIGH
tags: model, alias, suffix, claude-code, cursor
---

## Model mapping evidence and edge cases

The table in `SKILL.md` step 2 is the rule. This file records why, and what was not tested.

**Tested** (Claude Code 2.1.310, `claude -p ... --output-format json`):

| Input to Claude Code | Result |
|---|---|
| `claude-haiku-5-5` | Runs on `claude-haiku-5-5`. |
| `claude-haiku-5-5-medium` (Cursor effort suffix) | Fails: exit 1, `is_error: true`, error text in `result`, empty `modelUsage`. |
| `claude-haiku-5-5[effort=high]` | Fails the same way. |
| `haiku` (alias) | Resolves to `claude-haiku-5-5`. |
| `composer-2` (non-Anthropic) | Fails with `unrecognized_model`. |

So strip every Cursor suffix before passing a model, and never pass a non-Anthropic ID.

**Cursor and Claude Code resolve aliases differently.** Cursor maps `haiku` to `claude-haiku-4-5` (often disabled on a plan) and `sonnet` to a Sonnet 4.x model. Claude Code maps them to its latest, so an agent with `model: haiku` runs on a newer model through this skill than it would in Cursor. This is intended. The Cursor models `claude-haiku-5-5` and `claude-sonnet-5-5` have no Cursor alias, so agents that name them need the full ID.

**Not tested** (treat as unknown, and report the `is_error` text if a run fails):

- Dated IDs such as `claude-sonnet-4-5-20250929`.
- A `[1m]` context suffix.
- Aliases beyond `haiku`, `sonnet`, `opus` (for example `opusplan`, `default`).

**Avoid:** guessing a mapping for an ID not in the table.

**Prefer:** pass the stripped ID, and if `is_error` is `true`, report the error and offer to run that agent with the Task tool.
