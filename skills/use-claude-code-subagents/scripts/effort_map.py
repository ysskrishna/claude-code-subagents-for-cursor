#!/usr/bin/env python3
"""Map a Cursor-style model ID to (claude_model, effort) for `claude -p`.

Today the skill strips Cursor effort/thinking suffixes (Claude Code rejects
suffixed IDs). This keeps the effort instead of dropping it, so
`claude-haiku-5-5-high` runs as `--model claude-haiku-5-5 --effort high`.

The suffix list in ../references/model-mapping.md is authoritative. Claude
Code's CLI reference also lists `--effort ultracode`; that is a session option,
not a Cursor model suffix, so it is not mapped from a model ID.
"""
import re, sys

LEVELS = ("low", "medium", "high", "xhigh", "max")
_BRACKET = re.compile(r"\[(?:[^\]]*?)effort=(\w+)[^\]]*\]$")
_SUFFIX = re.compile(r"-(?:thinking-)?(low|medium|high|xhigh|max)$")
_THINK = re.compile(r"-thinking$")
_FAST = re.compile(r"-fast$")

def map_model(model: str):
    """Return (model_for_claude, effort_or_None)."""
    m = model.strip()
    effort = None
    b = _BRACKET.search(m)
    if b:
        effort = b.group(1).lower(); m = m[: b.start()]
    m = re.sub(r"\[[^\]]*\]$", "", m)          # any other bracket option
    m = _FAST.sub("", m)                       # speed suffix: dropped, as today
    s = _SUFFIX.search(m)
    if s:
        effort = effort or s.group(1); m = m[: s.start()]
    m = _THINK.sub("", m)
    if effort and effort not in LEVELS:
        effort = None
    return m, effort

def claude_flags(model: str):
    m, e = map_model(model)
    flags = ["--model", m]
    if e: flags += ["--effort", e]
    return flags

if __name__ == "__main__":
    for a in sys.argv[1:]:
        print(a, "->", " ".join(claude_flags(a)))
