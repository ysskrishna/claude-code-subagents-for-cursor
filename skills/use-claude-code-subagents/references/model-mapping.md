---
title: Model mapping evidence and edge cases
impact: HIGH
tags: model, alias, suffix, claude-code, cursor, effort, cost
---

## Model mapping evidence and edge cases

The table in `SKILL.md` step 2 is the rule. This file holds the suffix list, records why, and says what was not tested.

**Suffixes to strip** from a `claude-` ID before passing it as `--model`. This is the only copy of the list:

- Effort: `-low`, `-medium`, `-high`, `-xhigh`, `-max`. Also pass `--effort` with that level.
- Speed: `-fast`. Drop it; do not pass a flag.
- Thinking: `-thinking`, drop it. `-thinking` followed by an effort (`-thinking-low`, `-thinking-high`, `-thinking-max`): drop the thinking part and pass `--effort` with the level.
- Bracket form: `[effort=...]` is stripped and passed as `--effort`; any other `[...]` option is stripped and not passed.

If Cursor adds a new suffix, add it here. Until then an unknown suffix still passes the name check, `claude` rejects the ID with `is_error: true`, and the skill reports that error.

`scripts/effort_map.py` implements this mapping. `scripts/test_effort_receipt.py` tests it. The suffix list above stays authoritative.

**Tested** (Claude Code 2.1.310, `claude -p ... --output-format json`):

| Input to Claude Code | Result |
|---|---|
| `claude-haiku-5-5` | Runs on `claude-haiku-5-5`. |
| `claude-haiku-5-5-medium` (Cursor effort suffix, passed as `--model` with the suffix still on) | Fails: exit 1, `is_error: true`, error text in `result`, empty `modelUsage`. |
| `claude-haiku-5-5[effort=high]` | Fails the same way. |
| `haiku` (alias) | Resolves to `claude-haiku-5-5`. |
| `composer-2` (non-Anthropic) | Fails with `unrecognized_model`. |

So strip every Cursor suffix before passing `--model`, pass a recognized effort level as `--effort`, and only pass `haiku`, `sonnet`, `opus` or a `claude-` ID. Anything else uses the Task tool.

Claude Code's [CLI reference](https://code.claude.com/docs/en/cli-reference) lists `--effort` values `low`, `medium`, `high`, `xhigh`, `max`, and `ultracode`. This skill maps the first five from Cursor suffixes. `ultracode` is a Claude Code session option, not a Cursor model suffix, so it is not mapped from a model ID.

**Live effort and receipt check:** two `claude -p --agent scout --agents <file> --model haiku --permission-prompts none --output-format json` runs, one with `--effort high` and one without, both returned the requested `VERIFY_OK` with `is_error: false` and no permission denials. Tools were disabled. Both resolved to `claude-haiku-5-5`; the JSON contained every field listed in [Cost receipt](#cost-receipt), and the sum of per-model costs matched `total_cost_usd`.

The formatter produced these lines from the live JSON:

```text
scout ran on claude-haiku-5-5 | claude-haiku-5-5: 1368 in / 10 out, $0.0003 | total $0.0003 (Claude Code client-side estimate)
scout ran on claude-haiku-5-5 | claude-haiku-5-5: 1368 in / 10 out, $0.0001 | total $0.0001 (Claude Code client-side estimate)
```

This confirms `--effort high` is accepted with `--agent` and the receipt parses live output. A trivial prompt does not establish an effect on reasoning.

**Cursor UI check:** an Agent chat read a project-local copy of this skill (renamed only for test isolation) and routed three custom agents whose model IDs ended in `-high`, `-low`, and no suffix. The terminal commands passed the base model ID, with `--effort high`, `--effort low`, and no effort flag respectively. All returned `UI_OK` on `claude-haiku-5-5`, with no permission denials. Saved JSON token counts matched the independent Claude session transcripts, and the receipt formatter parsed all three payloads.

The first plain command hit a 401 from an inherited invalid `ANTHROPIC_API_KEY`. Successful invocations used the explicitly authorized test exception `env -u ANTHROPIC_API_KEY` to use the existing Claude login; the plain-command flow remains blocked in that local environment until its authentication setup is corrected. Resumed effort was not tested live. See the documentation's verification table for the versions used.

**Cursor and Claude Code resolve aliases differently.** Cursor maps `haiku` to `claude-haiku-4-5` (often disabled on a plan) and `sonnet` to a Sonnet 4.x model. Claude Code maps them to its latest, so an agent with `model: haiku` runs on a newer model through this skill than it would in Cursor. This is intended. The Cursor models `claude-haiku-5-5` and `claude-sonnet-5-5` have no Cursor alias, so agents that name them need the full ID.

**Not tested** (treat as unknown, and report the `is_error` text if a run fails):

- Dated IDs such as `claude-sonnet-4-5-20250929`.
- A `[1m]` context suffix.
- Aliases beyond `haiku`, `sonnet`, `opus` (for example `opusplan`, `default`).

**Avoid:** guessing a mapping for an ID not in the table.

**Prefer:** pass the stripped ID, with `--effort` when mapping produced a level, and if `is_error` is `true`, report the error and offer to run that agent with the Task tool.

## Cost receipt

After a successful run, print one line from the JSON. Field names follow the TypeScript result shape documented in [Track cost and usage](https://code.claude.com/docs/en/agent-sdk/cost-tracking) and the `--output-format json` description in [Run Claude Code programmatically](https://code.claude.com/docs/en/headless):

- `modelUsage`: map of model id to usage
- per model: `inputTokens`, `outputTokens`, `cacheReadInputTokens`, `cacheCreationInputTokens`, `costUSD` (optional `costBasis` is ignored)
- top-level `total_cost_usd`

Input tokens in the receipt are `inputTokens + cacheReadInputTokens + cacheCreationInputTokens`. `total_cost_usd` and `costUSD` are client-side estimates, not a bill.

Example (synthetic numbers):

```text
scout ran on claude-haiku-5-5 | claude-haiku-5-5: 2000 in / 300 out, $0.0123 | total $0.0123 (Claude Code client-side estimate)
```

`scripts/receipt.py` formats this line from a JSON object on stdin. Do not pipe `claude` through it in the skill: the `claude` command must stay a single plain command, and the parent agent builds the line from the command's JSON output.
