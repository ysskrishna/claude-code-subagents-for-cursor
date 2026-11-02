#!/usr/bin/env bash
# Assert that every `claude` flag the skill relies on still appears in `claude --help`.
# Run it against the Claude Code you have installed, or in CI against the latest release.
# Flags that the skill only warns against are ignored.
set -uo pipefail
cd "$(dirname "$0")/.."

command -v claude >/dev/null 2>&1 || { echo "claude is not installed" >&2; exit 2; }

IGNORE="--dangerously-skip-permissions"
help="$(claude --help 2>&1)"
fail=0

flags="$(grep -ohE -- '--[a-zA-Z][a-zA-Z-]*' skills/*/SKILL.md | sort -u)"
[ -n "$flags" ] || { echo "no flags found in skills/*/SKILL.md" >&2; exit 2; }

echo "claude $(claude --version 2>&1 | head -1)"
for flag in $flags; do
  case " $IGNORE " in *" $flag "*) continue ;; esac
  # Match the whole flag, so --agent is not satisfied by --agents.
  if printf '%s\n' "$help" | grep -qE -- "${flag}([^a-zA-Z-]|$)"; then
    echo "OK   $flag"
  else
    echo "MISSING $flag"
    fail=1
  fi
done

[ "$fail" -eq 0 ] && echo "All flags present." || echo "Some flags are missing from claude --help." >&2
exit "$fail"
