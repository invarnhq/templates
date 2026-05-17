# Invarn Templates

Curated `AgentTemplate` recipes for Invarn's connect-time picker. Each template is a versioned, reviewable, fixture-validated CI recipe that seeds a `Protocol` on a fresh `GitHubConnection`.

This repo is the **source of truth** for the catalog. Invarn (`invarn.com`) syncs this repo's tagged releases into its `AgentTemplate` table via a background cron. The picker reads from the synced cache; users see what's released here.

## Repo layout

```
templates/             Template source files (latest HEAD per slug + versioned history)
fixtures/              Real CI fixtures used by the validation harness
scripts/               Author-facing tooling (validate, lint, release helpers)
.github/workflows/     CI: PR validation + tag releases
SCHEMA.md              The apiVersion: invarn/v1 contract every template must follow
CONTRIBUTING.md        Authoring + review process
```

## Status

**v1.** Maintained by Invarn engineers. External PRs are not accepted yet — see [`CONTRIBUTING.md`](CONTRIBUTING.md) for the v1 vs v2 split.

## Quick links

- Catalog schema: [`SCHEMA.md`](SCHEMA.md)
- Authoring guide: [`CONTRIBUTING.md`](CONTRIBUTING.md)
- Run validation locally: `node scripts/validate-template.mjs templates/<slug>/template.yaml`
- Upstream design PRD: `.scratch/multi-agent-orchestration/curated-content-PRD.md` in the Invarn repo.
