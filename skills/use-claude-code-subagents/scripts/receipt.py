#!/usr/bin/env python3
"""Print a one-line cost receipt from `claude -p --output-format json` output.

Usage: python3 receipt.py < result.json

Reads `modelUsage` (the field the skill already uses to report the model) and
`total_cost_usd`. Field names match Anthropic's docs for the TypeScript result
shape (`inputTokens`, `outputTokens`, `cacheReadInputTokens`,
`cacheCreationInputTokens`, `costUSD`) and the CLI `--output-format json`
payload (`total_cost_usd`), and were confirmed against live agent runs (see
../references/model-mapping.md). `total_cost_usd` and `costUSD` are client-side
estimates, not a bill.
"""
import json, sys

def receipt(d: dict) -> str:
    mu = d.get("modelUsage") or {}
    parts = []
    for model, u in mu.items():
        tok_in = (u.get("inputTokens") or 0) + (u.get("cacheReadInputTokens") or 0) + (u.get("cacheCreationInputTokens") or 0)
        tok_out = u.get("outputTokens") or 0
        cost = u.get("costUSD")
        parts.append(f"{model}: {tok_in} in / {tok_out} out" + (f", ${cost:.4f}" if isinstance(cost, (int, float)) else ""))
    total = d.get("total_cost_usd")
    head = f"ran on {', '.join(mu) or 'unknown'}"
    tail = f" | total ${total:.4f} (Claude Code client-side estimate)" if isinstance(total, (int, float)) else ""
    return head + " | " + "; ".join(parts) + tail

if __name__ == "__main__":
    print(receipt(json.load(sys.stdin)))
