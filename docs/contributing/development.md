# Development

For contributors and maintainers. Users do not need this.

## Check scripts

```bash
bash scripts/validate.sh           # manifests, skill rules, CHANGELOG, evals, doc links
bash scripts/check_claude_flags.sh # every claude flag the skill uses exists
bash scripts/test_installs.sh all  # skills.sh and gh routes, in a throwaway HOME
```

- `validate.sh` checks both Cursor manifests against Cursor's plugin schemas (vendored in [`schemas/`](../../schemas), from [cursor/plugins](https://github.com/cursor/plugins)), the skill's frontmatter, size, references and trigger evals ([`evals/`](../../evals)), that the plugin version agrees across `.cursor-plugin/plugin.json`, `SKILL.md`, the CHANGELOG, `.claude-plugin/`, `openclaw.plugin.json` and `package.json`, and that links in the README and `docs/` resolve.
- `check_claude_flags.sh` needs `claude` installed. It fails when a flag used in `SKILL.md` is missing from `claude --help`.
- `test_installs.sh` clones the committed HEAD, so commit before running it.

CI runs all three on pull requests and checks weekly for drift in Cursor's schemas and Claude Code's flags.

## Try your changes in Cursor

```bash
bash scripts/dev_install.sh           # copy the plugin to ~/.cursor/plugins/local/
bash scripts/dev_install.sh --remove  # delete that copy
```

Then run **Developer: Reload Window** in Cursor and start a new chat. Run the script again after each change.

- It copies, because Cursor loads a symlink in `plugins/local` only when the target is inside that folder.
- Cursor prefers a marketplace-installed plugin of the same name over the local one. The script warns when it finds one, or a copy under `~/.cursor/skills` or `~/.agents/skills`. Uninstall those first, then check the first reply: it should show the flow of the version you are testing.
- Before a release, also test the published routes with `scripts/test_installs.sh`.

## Releases

1. Bump `version` in `.cursor-plugin/plugin.json`. Set the same value on `metadata.version` in `skills/use-claude-code-subagents/SKILL.md`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `openclaw.plugin.json`, and `package.json`. `validate.sh` checks them.
2. Add a `## [X.Y.Z]` section to `CHANGELOG.md` and a footer link.
3. Run the three scripts.
4. Merge, then push an annotated tag `vX.Y.Z`. `.github/workflows/release.yml` checks the tag against `plugin.json` and creates the GitHub Release.
5. Update [release-state.md](release-state.md) with the shipped version, tag, `main` commit, and release URL.

## Facts with one home

| Fact | Where it lives |
|---|---|
| Minimum Claude Code version | `SKILL.md` (preflight) and the Requirements list in `docs/README.md` |
| Model suffixes to strip | `skills/use-claude-code-subagents/references/model-mapping.md` |
| Plugin version | `.cursor-plugin/plugin.json` (mirrored in `SKILL.md`, `.claude-plugin/`, `openclaw.plugin.json`, `package.json`, and checked) |
| Last shipped release (tag, commit, URL) | `docs/contributing/release-state.md` |
| Versions last verified | `docs/README.md` |
