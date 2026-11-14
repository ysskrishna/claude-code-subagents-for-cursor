#!/usr/bin/env python3
"""Stage a ClawHub bundle and optionally publish it.

ClawHub rejects a full-repo upload (more than one bundle manifest) and rejects
a tarball that only contains openclaw.plugin.json. The stage directory has
openclaw.plugin.json plus one host manifest, .cursor-plugin/plugin.json.

Default is a dry run: print the staged files and the clawhub command.
Pass --publish to run that command. Do that only after the matching git tag
exists on main.
"""

import argparse
import json
import shutil
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PACKAGE_NAME = "@ysskrishna/claude-code-subagents-for-cursor"
DISPLAY_NAME = "Claude Code Subagents"
SOURCE_REPO = "ysskrishna/claude-code-subagents-for-cursor"
OWNER = "ysskrishna"

STAGE_FILES = (
    "openclaw.plugin.json",
    "package.json",
    "README.md",
    "LICENSE",
    "CHANGELOG.md",
)
STAGE_TREES = ("skills", "assets")


def version() -> str:
    data = json.loads((ROOT / "package.json").read_text(encoding="utf-8"))
    return data["version"]


def changelog(ver: str) -> str:
    text = (ROOT / "CHANGELOG.md").read_text(encoding="utf-8")
    marker = f"## [{ver}]"
    start = text.find(marker)
    if start < 0:
        raise SystemExit(f"CHANGELOG.md has no section for {ver}")
    rest = text[start:]
    newline = rest.find("\n")
    body = rest[newline + 1:] if newline >= 0 else ""
    nxt = body.find("\n## [")
    if nxt >= 0:
        body = body[:nxt]
    lines = []
    for ln in body.splitlines():
        stripped = ln.strip()
        if not stripped or stripped.startswith("#"):
            continue
        lines.append(stripped.lstrip("-").strip())
    return " ".join(lines)[:1500] or f"Release {ver}"


def stage_into(dest: Path) -> None:
    for name in STAGE_FILES:
        shutil.copy2(ROOT / name, dest / name)
    for tree in STAGE_TREES:
        shutil.copytree(ROOT / tree, dest / tree)
    host = dest / ".cursor-plugin"
    host.mkdir()
    shutil.copy2(ROOT / ".cursor-plugin" / "plugin.json", host / "plugin.json")


def git_head() -> str:
    out = subprocess.run(
        ["git", "rev-parse", "HEAD"],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    )
    return out.stdout.strip()


def publish_cmd(ver: str, source: Path, dry_run: bool) -> list[str]:
    return [
        "clawhub",
        "package",
        "publish",
        str(source),
        "--family",
        "bundle-plugin",
        "--bundle-format",
        "cursor",
        "--source-repo",
        SOURCE_REPO,
        "--source-commit",
        git_head(),
        "--source-ref",
        f"v{ver}",
        "--owner",
        OWNER,
        "--name",
        PACKAGE_NAME,
        "--display-name",
        DISPLAY_NAME,
        "--version",
        ver,
        "--changelog",
        changelog(ver),
        "--tags",
        "latest",
        *(["--dry-run"] if dry_run else []),
    ]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--publish",
        action="store_true",
        help="run clawhub package publish (default prints the command only)",
    )
    args = parser.parse_args()
    ver = version()
    manifest = json.loads((ROOT / "openclaw.plugin.json").read_text(encoding="utf-8"))
    if manifest.get("version") != ver:
        raise SystemExit(
            f"openclaw.plugin.json version {manifest.get('version')!r} != package.json {ver!r}"
        )
    with tempfile.TemporaryDirectory(prefix="clawhub-stage-") as tmp:
        dest = Path(tmp)
        stage_into(dest)
        print(f"version {ver}")
        for path in sorted(dest.rglob("*")):
            if path.is_file():
                print(path.relative_to(dest))
        cmd = publish_cmd(ver, dest, dry_run=not args.publish)
        print(" ".join(cmd))
        if args.publish:
            subprocess.run(cmd, check=True)


if __name__ == "__main__":
    main()
