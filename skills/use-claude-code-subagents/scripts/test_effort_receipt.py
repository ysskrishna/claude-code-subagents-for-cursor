#!/usr/bin/env python3
"""Unit tests for effort mapping and the cost-receipt formatter.

The receipt fixture is synthetic (made-up numbers, documented field shape only).
Run: python3 skills/use-claude-code-subagents/scripts/test_effort_receipt.py
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from effort_map import map_model
from receipt import receipt

cases = {
    "claude-haiku-5-5-medium": ("claude-haiku-5-5", "medium"),
    "claude-haiku-5-5[effort=high]": ("claude-haiku-5-5", "high"),
    "claude-opus-5-5-thinking-low": ("claude-opus-5-5", "low"),
    "claude-opus-5-5-thinking": ("claude-opus-5-5", None),
    "claude-sonnet-5-5-fast": ("claude-sonnet-5-5", None),
    "claude-opus-5-5-max": ("claude-opus-5-5", "max"),
    "haiku": ("haiku", None),
    "claude-sonnet-5-5": ("claude-sonnet-5-5", None),
}
ok = 0
for k, v in cases.items():
    got = map_model(k)
    print(("PASS" if got == v else "FAIL"), k, got)
    ok += got == v

# SYNTHETIC fixture (made-up numbers, shape only) to exercise receipt.py
fx = {
    "total_cost_usd": 0.0123,
    "modelUsage": {
        "claude-haiku-5-5": {
            "inputTokens": 1200,
            "outputTokens": 300,
            "cacheReadInputTokens": 800,
            "costUSD": 0.0123,
        }
    },
}
want = (
    "ran on claude-haiku-5-5 | claude-haiku-5-5: 2000 in / 300 out, $0.0123"
    " | total $0.0123 (Claude Code client-side estimate)"
)
r = receipt(fx)
print("RECEIPT", r)
ok += r == want
if r != want:
    print("FAIL receipt wanted:", want)

print(f"{ok}/{len(cases)+1} passed")
sys.exit(0 if ok == len(cases) + 1 else 1)
