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
4. Merge, then push an annotated tag `vX.Y.Z`. [`.github/workflows/release.yml`](../../.github/workflows/release.yml) checks the tag against `plugin.json`, creates the GitHub Release, and publishes `@ysskrishna/claude-code-subagents-for-cursor` with [npm trusted publishing](https://docs.npmjs.com/trusted-publishers/). The workflow uses GitHub's OIDC token (`id-token: write`). It does not use an npm token. npm CLI in that job is upgraded to latest, which must be 11.5.1 or newer, on Node 22.
5. On that tagged commit, publish the same version to ClawHub:

   ```bash
   python3 scripts/publish_clawhub.py --publish
   ```

   `clawhub` must already be logged in. The script's default, without `--publish`, only prints the command. It stages one host manifest (`.cursor-plugin/plugin.json`) plus `openclaw.plugin.json`. Uploading the whole repo fails, because ClawHub allows one bundle manifest.
6. Confirm the GitHub Release, the npm version, and the ClawHub version. Update [release-state.md](release-state.md) with the shipped version, tag, `main` commit, and release URL.

npmjs.com has to trust this repo before the workflow can publish. The package settings page does not exist until the package does, so the first publish is still one local `npm publish --access public` (an authenticator code if npm asks). Then, on npmjs.com, open the package, **Settings, Trusted publishing**, and add GitHub Actions:

| Field | Value |
| --- | --- |
| Organization or user | `ysskrishna` |
| Repository | `claude-code-subagents-for-cursor` |
| Workflow filename | `release.yml` |
| Environment name | leave empty |

Allow `npm publish`. The filename must match, including `.yml`. A new trusted-publisher row has to publish successfully within 2 days or it expires. Later tags publish with no token and no one-time code. Provenance is added automatically. This repo has no GitHub Environment named `prod`, so the workflow does not set one.

## Facts with one home

| Fact | Where it lives |
|---|---|
| Minimum Claude Code version | `SKILL.md` (preflight) and the Requirements list in `docs/README.md` |
| Model suffixes to strip | `skills/use-claude-code-subagents/references/model-mapping.md` |
| Plugin version | `.cursor-plugin/plugin.json` (mirrored in `SKILL.md`, `.claude-plugin/`, `openclaw.plugin.json`, `package.json`, and checked) |
| Last shipped release (tag, commit, URL) | `docs/contributing/release-state.md` |
| Versions last verified | `docs/README.md` |
