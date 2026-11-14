#!/usr/bin/env bash
# Validate the plugin: manifests against Cursor's vendored schemas, the skill against
# the Agent Skills limits, versions that must agree, safe `claude` commands in SKILL.md,
# and links and install commands in the README and docs/.
set -uo pipefail
cd "$(dirname "$0")/.."

command -v python3 >/dev/null 2>&1 || { echo "FAIL python3 is required"; exit 1; }

python3 - <<'EOF'
import glob, json, os, re, sys

REPO = "ysskrishna/claude-code-subagents-for-cursor"
bad = 0

def ok(msg): print(f"OK   {msg}")
def err(msg):
    global bad
    bad = 1
    print(f"FAIL {msg}")

def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()

def load_json(path):
    try:
        return json.loads(read(path))
    except (OSError, ValueError) as e:
        err(f"{path}: {e}")
        return None

# 1. Manifests: valid JSON, and valid against Cursor's vendored schemas when jsonschema is installed
manifests = {}
for doc in (".cursor-plugin/plugin.json", ".cursor-plugin/marketplace.json"):
    manifests[doc] = load_json(doc)
try:
    from jsonschema import Draft7Validator
except ImportError:
    Draft7Validator = None
    print("SKIP manifest schema validation (python3 jsonschema not installed)")
if Draft7Validator:
    for schema, doc in (("schemas/plugin.schema.json", ".cursor-plugin/plugin.json"),
                        ("schemas/marketplace.schema.json", ".cursor-plugin/marketplace.json")):
        if manifests.get(doc) is None:
            continue
        errors = sorted(Draft7Validator(load_json(schema)).iter_errors(manifests[doc]), key=lambda e: list(e.path))
        for e in errors:
            err(f"{doc}: {'/'.join(map(str, e.path)) or '<root>'}: {e.message}")
        if not errors:
            ok(f"{doc} matches {schema}")

plugin = manifests.get(".cursor-plugin/plugin.json") or {}
market = manifests.get(".cursor-plugin/marketplace.json") or {}

# 2. Manifest identity and descriptions
if plugin.get("name") != "claude-code-subagents-for-cursor":
    err(f"plugin.json name is {plugin.get('name')!r}")
if not str(plugin.get("repository", "")).startswith(f"https://github.com/{REPO}"):
    err(f"plugin.json repository {plugin.get('repository')!r} does not match {REPO}")
else:
    ok("repository URL matches repo")
if market.get("name") != "claude-code-subagents-for-cursor":
    err(f"marketplace.json name is {market.get('name')!r}")
mkt_plugins = market.get("plugins") or [{}]
for label, value in (("plugin.json description", plugin.get("description")),
                     ("marketplace.json metadata.description", (market.get("metadata") or {}).get("description")),
                     ("marketplace.json plugin description", mkt_plugins[0].get("description"))):
    if not str(value or "").strip():
        err(f"{label} is empty")
logo = plugin.get("logo", "")
if logo and not os.path.isfile(logo):
    err(f"plugin.json logo {logo!r} does not exist")

# 3. Skills: Agent Skills limits, companion files, evals
SEMVER = re.compile(r"^\d+\.\d+\.\d+$")
pub_script = read("scripts/publish_clawhub.py")
slug_block = re.search(r"clawhub_slug_map\s*=\s*\{(.*?)\}", pub_script, re.S)
slug_map = dict(re.findall(r'"([^"]+)":\s*"([^"]+)"', slug_block.group(1))) if slug_block else {}
skill_text = ""
for path in sorted(glob.glob("skills/*/SKILL.md")):
    skill_dir = os.path.dirname(path)
    dirname = os.path.basename(skill_dir)
    text = read(path)
    skill_text += text + "\n"
    lines = text.split("\n")
    if lines[-1] == "":
        lines.pop()
    if not lines or lines[0] != "---" or "---" not in lines[1:]:
        err(f"{path}: frontmatter is missing or not closed")
        continue
    front = lines[1:lines.index("---", 1)]

    def field(key):
        for i, l in enumerate(front):
            if l.startswith(key + ":"):
                rest = l.split(":", 1)[1].strip()
                if rest in (">", "|", ">-", "|-"):
                    block = []
                    for nxt in front[i + 1:]:
                        if nxt.startswith(" "):
                            block.append(nxt.strip())
                        else:
                            break
                    return " ".join(block)
                return rest.strip("\"'")
        return ""

    name = field("name")
    if name != dirname:
        err(f"{path}: name {name!r} must match directory {dirname!r}")
    if not re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", name) or len(name) > 64:
        err(f"{path}: name {name!r} must be 1-64 chars of a-z, 0-9 and single hyphens")
    desc = field("description")
    if not desc or len(desc) > 1024:
        err(f"{path}: description must be 1-1024 chars, found {len(desc)}")
    if len(lines) > 500:
        err(f"{path}: {len(lines)} lines, limit is 500")

    version = None
    in_meta = False
    for l in front:
        if l.startswith("metadata:"):
            in_meta = True
        elif in_meta and l.strip().startswith("version:"):
            version = l.split(":", 1)[1].strip().strip("\"'")
        elif in_meta and not l.startswith(" "):
            in_meta = False
    if version != plugin.get("version"):
        err(f"{path}: metadata.version {version!r} must equal plugin.json version {plugin.get('version')!r}")
    if dirname not in slug_map:
        err(f"{dirname}: missing from clawhub_slug_map in scripts/publish_clawhub.py")

    if not os.path.isfile(os.path.join(skill_dir, "references", "example.md")):
        err(f"{skill_dir}: references/example.md is required")
    for link in re.findall(r"\]\((references/[^)#]+)", text):
        if not os.path.isfile(os.path.join(skill_dir, link)):
            err(f"{path}: broken link {link}")

    ev = f"evals/{dirname}.json"
    items = load_json(ev) if os.path.isfile(ev) else None
    if items is None:
        err(f"{ev} is required")
    else:
        yes = sum(1 for x in items if x.get("should_trigger") is True)
        no = sum(1 for x in items if x.get("should_trigger") is False)
        if yes < 4 or no < 4 or any(not x.get("query") for x in items):
            err(f"{ev}: need at least 4 should-trigger and 4 should-not-trigger queries, found {yes} and {no}")
if not bad:
    ok("skill name, description, size, references, evals and version")

# 4. Safe `claude` commands in SKILL.md: every <placeholder> inside a bash block must be double-quoted
unquoted = []
for block in re.findall(r"```bash\n(.*?)```", skill_text, re.S):
    for line in block.split("\n"):
        rest = re.sub(r'"[^"]*"', "", line)
        unquoted += re.findall(r"<[A-Za-z_][A-Za-z0-9_-]*>", rest)
if unquoted:
    err(f"SKILL.md: unquoted placeholders in a bash block: {sorted(set(unquoted))}")
else:
    ok("SKILL.md bash blocks quote every placeholder")
if re.search(r"<<'?[A-Z]+'?\s*$", skill_text, re.M):
    err("SKILL.md: heredoc found; briefs must go through files")

# 5. One minimum Claude Code version, in SKILL.md and docs/README.md
m1 = re.search(r"must be (\d+\.\d+\.\d+) or later", skill_text)
m2 = re.search(r"Claude Code (\d+\.\d+\.\d+) or later", read("docs/README.md")) if os.path.isfile("docs/README.md") else None
if not (m1 and m2):
    err("minimum Claude Code version not found in SKILL.md or docs/README.md")
elif m1.group(1) != m2.group(1):
    err(f"minimum Claude Code version differs: SKILL.md {m1.group(1)}, docs/README.md {m2.group(1)}")
else:
    ok(f"minimum Claude Code version {m1.group(1)} agrees in SKILL.md and docs/README.md")

# 6. CHANGELOG matches plugin.json
pver = plugin.get("version", "")
if not SEMVER.match(str(pver)):
    err(f"plugin.json version {pver!r} is not X.Y.Z")
if os.path.isfile("CHANGELOG.md"):
    cl = read("CHANGELOG.md")
    heads = re.findall(r"^## \[(\d+\.\d+\.\d+)\]", cl, re.M)
    if not heads or heads[0] != pver:
        err(f"CHANGELOG top version {heads[:1]} differs from plugin.json {pver!r}")
    elif not re.search(rf"^\[{re.escape(pver)}\]: https://github.com/{REPO}/", cl, re.M):
        err(f"CHANGELOG has no footer link for [{pver}]")
    else:
        ok(f"CHANGELOG top version {pver} matches plugin.json")

# 6b. Claude Code, npm, and OpenClaw manifests carry the same version
def same_version(path, data):
    if not isinstance(data, dict):
        return
    if data.get("version") != pver:
        err(f"{path} version {data.get('version')!r} differs from plugin.json {pver!r}")
    else:
        ok(f"{path} version {pver}")

claude_plugin = load_json(".claude-plugin/plugin.json")
same_version(".claude-plugin/plugin.json", claude_plugin)
if isinstance(claude_plugin, dict) and claude_plugin.get("name") != "cursor-subagent-models":
    err(f"claude plugin.json name is {claude_plugin.get('name')!r}")
openclaw = load_json("openclaw.plugin.json")
same_version("openclaw.plugin.json", openclaw)
pkg = load_json("package.json")
same_version("package.json", pkg)

if isinstance(pkg, dict):
    if pkg.get("name") != "@ysskrishna/claude-code-subagents-for-cursor":
        err(f"package.json name is {pkg.get('name')!r}")
    oc = pkg.get("openclaw") or {}
    if not (oc.get("compat") or {}).get("pluginApi") or not (oc.get("build") or {}).get("openclawVersion"):
        err("package.json needs openclaw.compat.pluginApi and openclaw.build.openclawVersion")
    else:
        ok("package.json openclaw compat")

claude_market = load_json(".claude-plugin/marketplace.json")
if isinstance(claude_market, dict):
    entry = (claude_market.get("plugins") or [{}])[0]
    meta_ver = (claude_market.get("metadata") or {}).get("version")
    name_ok = claude_market.get("name") == "cursor-subagent-models"
    source_ok = entry.get("name") == "cursor-subagent-models" and entry.get("source") == "./"
    version_ok = meta_ver == pver and entry.get("version") == pver
    if not name_ok:
        err(f"claude marketplace name is {claude_market.get('name')!r}")
    if not version_ok:
        err(f"claude marketplace version metadata {meta_ver!r} entry {entry.get('version')!r} differs from {pver!r}")
    if not source_ok:
        err("claude marketplace entry must use name cursor-subagent-models and source ./")
    if name_ok and source_ok and version_ok:
        ok("claude marketplace version and source")

display = plugin.get("displayName")
if display != "Claude Code Subagents for Cursor":
    err(f"plugin.json displayName is {display!r}")
elif isinstance(openclaw, dict) and openclaw.get("name") != display:
    err(f"openclaw.plugin.json name {openclaw.get('name')!r} differs from plugin.json displayName")
elif isinstance(openclaw, dict):
    ok("display name Claude Code Subagents for Cursor")

if not os.path.isfile("assets/icon.png"):
    err("assets/icon.png is missing; ClawHub uses that file as the plugin image")
else:
    ok("assets/icon.png")
if isinstance(claude_plugin, dict) and claude_plugin.get("icon") != "./assets/icon.png":
    err(f"claude plugin.json icon is {claude_plugin.get('icon')!r}")
if isinstance(openclaw, dict) and openclaw.get("categories") != ["developer-tools"]:
    err(f"openclaw.plugin.json categories is {openclaw.get('categories')!r}")
elif isinstance(openclaw, dict):
    ok("openclaw category developer-tools")

if isinstance(openclaw, dict):
    id_ok = openclaw.get("id") == "claude-code-subagents-for-cursor"
    skills_ok = openclaw.get("skills") == ["./skills"]
    if not id_ok:
        err(f"openclaw.plugin.json id is {openclaw.get('id')!r}")
    if not skills_ok:
        err(f"openclaw.plugin.json skills is {openclaw.get('skills')!r}")
    if id_ok and skills_ok:
        ok("openclaw.plugin.json id and skills")

# 7. Required files, local links, install commands
for f in ("README.md", "LICENSE", "CHANGELOG.md", "SECURITY.md"):
    if not os.path.isfile(f):
        err(f"missing {f}")

for md in ["README.md"] + sorted(glob.glob("docs/**/*.md", recursive=True)) + sorted(glob.glob("examples/**/*.md", recursive=True)):
    base = os.path.dirname(md)
    for target in re.findall(r"\]\(([^)\s]+)\)", read(md)):
        if re.match(r"[a-z]+:", target) or target.startswith("#"):
            continue
        path = os.path.normpath(os.path.join(base, target.split("#", 1)[0]))
        if not os.path.exists(path):
            err(f"{md}: broken link {target}")
for img in re.findall(r'src="([^"]+)"', read("README.md")):
    if not re.match(r"[a-z]+:", img) and not os.path.exists(img):
        err(f"README.md: missing image {img}")

readme = read("README.md")
for prefix, guide in (("npx skills add ", "docs/install/skills-sh-setup.md"), ("gh skill install ", "docs/install/gh-cli-setup.md")):
    cmds = [l.strip() for l in readme.split("\n") if l.strip().startswith(prefix)]
    if not cmds:
        err(f"README.md has no '{prefix}' command")
    for c in cmds:
        if os.path.isfile(guide) and c not in read(guide):
            err(f"{guide} does not contain the README command: {c}")
if not bad:
    ok("required files, links and install commands")

sys.exit(bad)
EOF
rc=$?
if [ "$rc" -ne 0 ]; then
    echo "VALIDATION FAILED"
    exit 1
fi
echo "All checks passed."
