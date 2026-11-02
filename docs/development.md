# Development

For contributors and maintainers. Users do not need this.

## Check scripts

```bash
bash scripts/validate.sh           # manifests, skill rules, CHANGELOG, evals, doc links
bash scripts/check_claude_flags.sh # every claude flag the skill uses exists
bash scripts/test_installs.sh all  # skills.sh and gh routes, in a throwaway HOME
```

- `validate.sh` checks both manifests against Cursor's plugin schemas (vendored in [`schemas/`](../schemas/), from [cursor/plugins](https://github.com/cursor/plugins)), the skill's frontmatter, size, references and trigger evals ([`evals/`](../evals/)), that versions agree across `plugin.json`, `SKILL.md` and the CHANGELOG, and that links in the README and `docs/` resolve.
- `check_claude_flags.sh` needs `claude` installed. It fails when a flag used in `SKILL.md` is missing from `claude --help`.
- `test_installs.sh` clones the committed HEAD, so commit before running it.

CI runs all three on pull requests and checks weekly for drift in Cursor's schemas and Claude Code's flags.

## Releases

1. Bump `version` in `.cursor-plugin/plugin.json` and `metadata.version` in `skills/use-claude-code-subagents/SKILL.md` to the same value.
2. Add a `## [X.Y.Z]` section to `CHANGELOG.md` and a footer link.
3. Run the three scripts.
4. Merge, then push an annotated tag `vX.Y.Z`. `.github/workflows/release.yml` checks the tag against `plugin.json` and creates the GitHub Release.

## Facts with one home

| Fact | Where it lives |
|---|---|
| Minimum Claude Code version | `SKILL.md` (preflight) and the Requirements list in `docs/README.md` |
| Model suffixes to strip | `skills/use-claude-code-subagents/references/model-mapping.md` |
| Plugin version | `.cursor-plugin/plugin.json` (mirrored in `SKILL.md` and checked) |
| Versions last verified | `docs/README.md` |
