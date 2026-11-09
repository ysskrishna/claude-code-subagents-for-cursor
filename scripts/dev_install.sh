#!/usr/bin/env bash
# Try this checkout in Cursor without publishing it.
#   bash scripts/dev_install.sh           copy the plugin to ~/.cursor/plugins/local/
#   bash scripts/dev_install.sh --remove  delete that copy
# It copies instead of symlinking: Cursor loads a symlink in plugins/local only when
# the target is inside that folder. Run it again after every change, then run
# "Developer: Reload Window" in Cursor. CURSOR_HOME overrides ~/.cursor (used by tests).
set -euo pipefail

NAME="claude-code-subagents-for-cursor"
SKILL="use-claude-code-subagents"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CURSOR_HOME="${CURSOR_HOME:-$HOME/.cursor}"
DEST="$CURSOR_HOME/plugins/local/$NAME"

case "${1:-}" in
    "" | --install) ;;
    --remove)
        if [ -d "$DEST" ]; then
            rm -rf "$DEST"
            echo "Removed $DEST"
        else
            echo "Nothing to remove at $DEST"
        fi
        echo "Run \"Developer: Reload Window\" in Cursor."
        exit 0
        ;;
    *)
        echo "usage: bash scripts/dev_install.sh [--remove]" >&2
        exit 2
        ;;
esac

[ -f "$ROOT/.cursor-plugin/plugin.json" ] || { echo "FAIL $ROOT is not the plugin repo" >&2; exit 1; }

# Cursor prefers a marketplace-installed plugin of the same name over the local one,
# and loads a skill from every skills folder, so another copy can answer instead of this one.
for other in "$CURSOR_HOME"/plugins/cache/*/"$NAME" \
             "$CURSOR_HOME/skills/$SKILL" "$HOME/.agents/skills/$SKILL"; do
    if [ -e "$other" ]; then
        echo "WARN another copy is installed: $other"
        echo "     Uninstall it first, or Cursor may load it instead of this checkout."
    fi
done

mkdir -p "$(dirname "$DEST")"
rm -rf "$DEST"
mkdir -p "$DEST"
cp -R "$ROOT/.cursor-plugin" "$ROOT/skills" "$DEST/"
[ -d "$ROOT/assets" ] && cp -R "$ROOT/assets" "$DEST/"

version="$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$DEST/.cursor-plugin/plugin.json" | head -n 1)"
echo "Installed $NAME $version to $DEST"
echo "Next: run \"Developer: Reload Window\" in Cursor, then start a new chat and type /$SKILL."
echo "Undo with: bash scripts/dev_install.sh --remove"
