#!/usr/bin/env bash
# Real install tests: install this repo's skill through each route and check that
# the skill and its references land where Cursor reads them. Each route runs with a
# throwaway HOME, so your own config is never touched.
#
# Usage: scripts/test_installs.sh [--source DIR] <route>... | all
#   route: skills gh
# The source is a fresh git clone of the committed HEAD, so commit before testing.
# Env: WORK (scratch dir), KEEP=1 (keep scratch dir), REQUIRE=1 (a missing tool is a failure).
# Exit code: 0 when nothing failed (skips allowed), 1 otherwise.
#
# Not covered: the Cursor plugin marketplace route (it needs the Cursor app; test it by hand).

set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="$ROOT"
ALL="skills gh"
WORK="${WORK:-$(mktemp -d "${TMPDIR:-/tmp}/ccsac-install-test.XXXXXX")}"
REPO="$WORK/claude-code-subagents-for-cursor"
SKILL="use-claude-code-subagents"
FAILED=0

pass() { printf 'PASS  %-8s %s\n' "$1" "$2"; }
skip() { printf 'SKIP  %-8s %s\n' "$1" "$2"; }
fail() {
  printf 'FAIL  %-8s %s\n' "$1" "$2"
  [ -f "$WORK/logs/$1.log" ] && tail -n 12 "$WORK/logs/$1.log" | sed 's/^/        | /'
  FAILED=1
}

# macOS has no timeout(1). perl alarm kills the command after N seconds.
to() { local s="$1"; shift; perl -e 'alarm shift; exec @ARGV' "$s" "$@"; }

log() { mkdir -p "$WORK/logs"; echo "$WORK/logs/$1.log"; }
new_home() { mkdir -p "$WORK/home/$1"; echo "$WORK/home/$1"; }

need() {
  if command -v "$1" >/dev/null 2>&1; then return 0; fi
  if [ "${REQUIRE:-0}" = "1" ]; then fail "$2" "$1 is not installed"; else skip "$2" "$1 is not installed"; fi
  return 1
}

# check_installed <route> <dir>: SKILL.md and both reference files must be there, evals must not.
check_installed() {
  local route="$1" dir="$2" missing=""
  for f in SKILL.md references/example.md references/model-mapping.md; do
    [ -f "$dir/$f" ] || missing="$missing $f"
  done
  if [ -n "$missing" ]; then fail "$route" "missing in $dir:$missing"; return; fi
  if [ -e "$dir/evals" ]; then fail "$route" "evals/ was installed into $dir"; return; fi
  pass "$route" "installed to ${dir#$WORK/home/}"
}

prepare_source() {
  if [ -n "$(git -C "$SOURCE" status --porcelain 2>/dev/null)" ]; then
    echo "note: working tree has uncommitted changes. Tests use the committed HEAD only." >&2
  fi
  git clone -q "$SOURCE" "$REPO" || { echo "cannot clone $SOURCE" >&2; exit 2; }
}

t_skills() {
  need npx skills || return
  local h f; h="$(new_home skills)"; f="$(log skills)"
  (export HOME="$h" DISABLE_TELEMETRY=1; to 120 npx -y skills add "$REPO" --list) >"$f" 2>&1 || { fail skills "npx skills add --list failed"; return; }
  grep -q -- "$SKILL" "$f" || { fail skills "$SKILL not listed"; return; }
  (export HOME="$h" DISABLE_TELEMETRY=1; to 120 npx -y skills add "$REPO" --skill "$SKILL" -a cursor -g -y) >>"$f" 2>&1 || { fail skills "npx skills add failed"; return; }
  check_installed skills "$h/.agents/skills/$SKILL"
}

t_gh() {
  need gh gh || return
  local h f; h="$(new_home gh)"; f="$(log gh)"
  (export HOME="$h" GH_CONFIG_DIR="$h/gh"; to 60 gh skill install --from-local "$REPO" "$SKILL" --agent cursor --scope user) >"$f" 2>&1 || { fail gh "gh skill install failed"; return; }
  check_installed gh "$h/.cursor/skills/$SKILL"
}

main() {
  local routes=() a
  while [ $# -gt 0 ]; do
    case "$1" in
      --source) SOURCE="$(cd "$2" && pwd)"; shift 2 ;;
      -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
      all) routes+=($ALL); shift ;;
      *) routes+=("$1"); shift ;;
    esac
  done
  [ ${#routes[@]} -gt 0 ] || { echo "usage: $0 [--source DIR] <route>... | all (routes: $ALL)" >&2; exit 2; }
  prepare_source
  for a in "${routes[@]}"; do
    case "$a" in
      skills) t_skills ;;
      gh) t_gh ;;
      *) echo "unknown route: $a (routes: $ALL)" >&2; FAILED=1 ;;
    esac
  done
  if [ "${KEEP:-0}" = "1" ]; then echo "scratch dir kept: $WORK"; else chmod -R u+w "$WORK" 2>/dev/null; rm -rf "$WORK" 2>/dev/null || true; fi
  exit "$FAILED"
}

main "$@"
