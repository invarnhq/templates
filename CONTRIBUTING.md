# Contributing to Invarn Templates

## v1 — Invarn-maintainers only

External pull requests are not accepted in v1. The repo is operationally open (anyone can read, fork, audit) but commit access is restricted to Invarn engineers.

**Why:** Templates execute arbitrary shell on Invarn's runner image. A malicious template = supply-chain foothold on every dispatch that uses it. Until the validation + security-review process is hardened, the surface stays internal.

**v2** (when external contributions open): the same flow below applies, plus required Invarn-maintainer approval and a sandboxed security-scan pass.

## Author a new template

1. **Decide the slug**: kebab-case, stack-prefixed (`ios-pr-gate`, `android-release-bundle`). Slugs are stable forever — they're stamped onto `Agent.seededFromTemplate` and `Protocol.templateSlug` in Invarn's DB.

2. **Create `templates/<slug>/template.yaml`** following [`SCHEMA.md`](SCHEMA.md). Start at `version: 1.0.0`.

3. **Pick a fixture** under `fixtures/<fixture-slug>/`. If none matches your template's repo shape (e.g. you need a multi-flavor Android fixture and only `android-single` exists), add a new fixture under `fixtures/` in the same PR.

4. **Annotate the template's expected outcome** via a frontmatter comment:
   ```yaml
   # fixture: ios-spm
   # expected_outcome: passed
   apiVersion: invarn/v1
   ...
   ```
   `expected_outcome` is one of `passed`, `failed`, or `failed_with_structured`. For `failed_with_structured`, the validator additionally asserts that `structured_failures` contains at least one entry.

5. **Local smoke check** (until the dispatch-validator script lands): paste your `template.yaml` into a working Invarn dev environment, manually dispatch the seeded `Protocol` against the matching fixture, confirm the outcome.

6. **Open a PR.** CI runs the schema-validation workflow. Once dispatch-validation lands in CI, that runs too.

7. **Release.** After merge to `main`, tag the release: `git tag <slug>@<version>`, push. The `release.yml` workflow snapshots the current `templates/<slug>/template.yaml` into `templates/<slug>/versions/<version>.yaml`.

## Update an existing template

1. Decide the bump (patch / minor / major — see [`SCHEMA.md`](SCHEMA.md#versioning)).
2. Edit `templates/<slug>/template.yaml`. Bump the `version` field.
3. Update local smoke notes + open PR.
4. On merge, tag `<slug>@<new-version>`.

The cron sync in Invarn picks up the new version on its next run. Dashboard users see a "Template updated" badge on their seeded `ProtocolRow` and can apply the diff via the existing Reset-to-defaults UI.

**Don't edit `versions/*.yaml` files directly** — they're write-once archives. The release workflow is the only thing that writes there.

## Add a new fixture

Each fixture is a real, minimal CI fixture that templates can validate against. Goals:

- **Real**: actually buildable / testable on Invarn's runner.
- **Minimal**: ≤ 500 LOC, ≤ 3-minute build time on the standard Invarn runner.
- **Deterministic**: same outcome every run, no flakes.

iOS / KMM fixtures generate their `.xcodeproj` via [XcodeGen](https://github.com/yonaskolb/XcodeGen) — the `project.yml` is checked in, the generated `.xcodeproj` is gitignored. Run `xcodegen generate` before dispatching against the fixture (the future validator script will do this automatically).

Add a `README.md` to each new fixture describing its shape, what templates target it, and any setup commands (e.g. `xcodegen generate`).

## Review checklist (for maintainers)

Before merging a template PR:

- [ ] Template parses; `apiVersion: invarn/v1`.
- [ ] `slug` matches an existing or newly-added `templates/<slug>/` directory.
- [ ] `version` is bumped if this is an update (not the first PR).
- [ ] `requires_env` is complete — every `${VAR}` reference in `inputs` is listed.
- [ ] Mobile templates use typed cibuild steps (no `kind: script`).
- [ ] `requires_when` predicates reference documented `DetectorFacts` keys.
- [ ] Fixture mapping (`# fixture: ...`) points at an existing fixture directory.
- [ ] PR description includes the local smoke-check evidence (build id or screenshot).
- [ ] No secrets are echoed by any command (`echo $SECRET`, `cat $SECRET_FILE`).
- [ ] No `curl | sh` or unaudited external script execution.
- [ ] Network access is limited to standard package registries (`api.cocoapods.org`, `maven.google.com`, `repo1.maven.org`, `objects.githubusercontent.com`, Apple's API hosts).

## Local development

Currently minimal — no `npm install` step. Future tooling lands when the validator script (`scripts/validate-template.mjs`) is added:

```bash
# (planned, not yet implemented)
node scripts/validate-template.mjs templates/<slug>/template.yaml
```

For now, validate via the Invarn dev environment as described above.
