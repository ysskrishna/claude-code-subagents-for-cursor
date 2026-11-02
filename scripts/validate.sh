#!/usr/bin/env bash
# Validate the plugin: manifest JSON against Cursor's vendored schemas,
# frontmatter on every skill, and manifest/repo consistency.
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

# 2. Every skill file has name and description frontmatter
for f in skills/*/SKILL.md; do
    [ -f "$f" ] || { echo "FAIL no skill files found"; fail=1; break; }
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

# 3b. Skill rules: description shape, size, name, and companion files
if command -v python3 >/dev/null 2>&1; then
    if ! python3 - <<'EOF'
import glob, json, os, re, sys

bad = 0
def err(msg):
    global bad
    print(f"FAIL {msg}")
    bad = 1

for path in sorted(glob.glob("skills/*/SKILL.md")):
    skill_dir = os.path.dirname(path)
    dirname = os.path.basename(skill_dir)
    lines = open(path, encoding="utf-8").read().split("\n")
    if lines and lines[-1] == "":
        lines.pop()
    end = lines.index("---", 1) if lines and lines[0] == "---" and "---" in lines[1:] else -1
    if end < 0:
        err(f"{path}: frontmatter is not closed")
        continue
    front = lines[1:end]

    name = next((l.split(":", 1)[1].strip() for l in front if l.startswith("name:")), "")
    if name != dirname:
        err(f"{path}: name '{name}' must match directory '{dirname}'")

    desc = ""
    for i, l in enumerate(front):
        if l.startswith("description:"):
            rest = l.split(":", 1)[1].strip()
            if rest in (">", "|", ">-", "|-"):
                block = []
                for nxt in front[i + 1:]:
                    if nxt.startswith(" "):
                        block.append(nxt.strip())
                    else:
                        break
                desc = " ".join(block)
            else:
                desc = rest.strip("\"'")
            break
    if not desc.startswith("Use "):
        err(f"{path}: description must start with 'Use '")
    if not 200 <= len(desc) <= 350:
        err(f"{path}: description is {len(desc)} chars, expected 200-350")
    if "Skip" not in desc:
        err(f"{path}: description needs a Skip clause")

    if len(lines) > 120:
        err(f"{path}: {len(lines)} lines, limit is 120")

    if not os.path.isfile(os.path.join(skill_dir, "references", "example.md")):
        err(f"{skill_dir}: references/example.md is required")

    for link in re.findall(r"\]\((references/[^)#]+)", "\n".join(lines)):
        if not os.path.isfile(os.path.join(skill_dir, link)):
            err(f"{path}: broken link {link}")

    ev = f"evals/{dirname}.json"
    if not os.path.isfile(ev):
        err(f"{ev} is required")
    else:
        try:
            items = json.load(open(ev))
            yes = sum(1 for x in items if x.get("should_trigger") is True)
            no = sum(1 for x in items if x.get("should_trigger") is False)
            if (yes, no) != (8, 8) or any(not x.get("query") for x in items):
                err(f"{ev}: expected 8 should-trigger and 8 should-not-trigger queries, found {yes} and {no}")
        except (ValueError, AttributeError) as e:
            err(f"{ev}: invalid ({e})")

if not bad:
    print("OK  skill description, size, references and evals")
sys.exit(bad)
EOF
    then fail=1; fi
fi

# 3c. Release metadata: CHANGELOG matches plugin.json, logo exists, no pipe-to-shell
if [ -f .cursor-plugin/plugin.json ] && [ -f CHANGELOG.md ]; then
    pver=$(python3 -c "import json; print(json.load(open('.cursor-plugin/plugin.json'))['version'])" 2>/dev/null)
    cver=$(sed -n 's/^## \[\([0-9][0-9.]*\)\].*/\1/p' CHANGELOG.md | head -1)
    if [ "$pver" = "$cver" ]; then echo "OK  CHANGELOG top version $cver matches plugin.json"; else echo "FAIL CHANGELOG top version '$cver' differs from plugin.json '$pver'"; fail=1; fi
    grep -q "^\[$pver\]: https://github.com/ysskrishna/claude-code-subagents-for-cursor/" CHANGELOG.md || { echo "FAIL CHANGELOG has no footer link for [$pver]"; fail=1; }
    logo=$(python3 -c "import json; print(json.load(open('.cursor-plugin/plugin.json')).get('logo',''))" 2>/dev/null)
    if [ -n "$logo" ] && [ ! -f "$logo" ]; then echo "FAIL plugin.json logo '$logo' does not exist"; fail=1; fi
fi
# Hermes-style scanners block installs when any file pipes a download into a shell.
if command -v git >/dev/null 2>&1 && git rev-parse --git-dir >/dev/null 2>&1; then
    hits=$(git ls-files -z -- . ':!scripts/validate.sh' | xargs -0 grep -nIE '(curl|wget)[^|]*\|[[:space:]]*(sudo[[:space:]]+)?(ba|z)?sh' 2>/dev/null || true)
    if [ -n "$hits" ]; then echo "FAIL pipe-to-shell found:"; echo "$hits"; fail=1; else echo "OK  no pipe-to-shell in tracked files"; fi
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
