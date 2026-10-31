#!/usr/bin/env bash
# Validate the plugin: manifest JSON against Cursor's vendored schemas,
# frontmatter on every command, and manifest/repo consistency.
set -uo pipefail
cd "$(dirname "$0")/.."

fail=0

# 1. Manifests parse and validate against Cursor's vendored schemas (if python3+jsonschema available)
if command -v python3 >/dev/null 2>&1; then
    if python3 -c "import jsonschema" >/dev/null 2>&1; then
        for pair in "schemas/plugin.schema.json:.cursor-plugin/plugin.json" "schemas/marketplace.schema.json:.cursor-plugin/marketplace.json"; do
            schema="${pair%%:*}"; doc="${pair#*:}"
            if [ -f "$schema" ] && [ -f "$doc" ]; then
                if ! python3 - "$schema" "$doc" <<'EOF'
import json, sys
from jsonschema import Draft7Validator
with open(sys.argv[1]) as f: schema = json.load(f)
with open(sys.argv[2]) as f: doc = json.load(f)
errors = sorted(Draft7Validator(schema).iter_errors(doc), key=lambda e: list(e.path))
for e in errors:
    print(f"  {doc}: {'/'.join(map(str, e.path)) or '<root>'}: {e.message}")
sys.exit(1 if errors else 0)
EOF
                then fail=1; else echo "OK  $doc matches $schema"; fi
            else
                echo "SKIP $doc (schema or doc missing)"; fi
        done
    else
        echo "SKIP manifest schema validation (python3 jsonschema not installed)"; fi
else
    echo "SKIP manifest schema validation (python3 not installed)"; fi

# 2. Every command file has name and description frontmatter
for f in commands/*.md; do
    [ -f "$f" ] || { echo "FAIL no command files found"; fail=1; break; }
    if head -1 "$f" | grep -q '^---$'; then
        front=$(awk 'NR==1{next} /^---$/{exit} {print}' "$f")
        echo "$front" | grep -q '^name:' || { echo "FAIL $f: missing 'name' in frontmatter"; fail=1; }
        echo "$front" | grep -q '^description:' || { echo "FAIL $f: missing 'description' in frontmatter"; fail=1; }
        echo "OK  $f has name + description frontmatter"
    else
        echo "FAIL $f: no frontmatter block"; fail=1
    fi
done

# 3. Manifest/name/repo consistency
for doc in .cursor-plugin/plugin.json .cursor-plugin/marketplace.json; do
    [ -f "$doc" ] || { echo "FAIL missing $doc"; fail=1; continue; }
    python3 -c "import json,sys; json.load(open('$doc'))" 2>/dev/null || { echo "FAIL $doc: invalid JSON"; fail=1; }
done
if [ -f .cursor-plugin/plugin.json ]; then
    mname=$(python3 -c "import json; print(json.load(open('.cursor-plugin/plugin.json'))['name'])" 2>/dev/null)
    [ "$mname" = "claude-code-subagents-for-cursor" ] || { echo "FAIL plugin.json name is '$mname', expected claude-code-subagents-for-cursor"; fail=1; }
    repo=$(python3 -c "import json; print(json.load(open('.cursor-plugin/plugin.json')).get('repository',''))" 2>/dev/null)
    case "$repo" in
        https://github.com/ysskrishna/claude-code-subagents-for-cursor*) echo "OK  repository URL matches repo";;
        *) echo "FAIL repository URL '$repo' does not match ysskrishna/claude-code-subagents-for-cursor"; fail=1;;
    esac
fi
if [ -f .cursor-plugin/marketplace.json ]; then
    mkt_name=$(python3 -c "import json; print(json.load(open('.cursor-plugin/marketplace.json'))['name'])" 2>/dev/null)
    [ "$mkt_name" = "claude-code-subagents-for-cursor" ] || { echo "FAIL marketplace.json name is '$mkt_name'"; fail=1; }
fi

# 4. Required files
for f in README.md LICENSE CHANGELOG.md; do
    [ -f "$f" ] || { echo "FAIL missing $f"; fail=1; }
done

if [ "$fail" -eq 1 ]; then
    echo "VALIDATION FAILED"
    exit 1
fi
echo "All checks passed."
