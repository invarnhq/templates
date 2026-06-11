# Invarn template schema (`apiVersion: invarn/v1`)

Every template file MUST conform to this schema. Templates declaring an `apiVersion` Invarn doesn't recognize are dropped silently by the sync cron.

## File location

`templates/<slug>/template.yaml` — the editable HEAD of each template.

On release (semver tag `<slug>@<version>`), CI copies the current HEAD to `templates/<slug>/versions/<version>.yaml` for the audit trail. Old versions are preserved indefinitely.

## Top-level fields

| Field | Type | Required | Description |
|--|--|--|--|
| `apiVersion` | `string` | yes | Must be `invarn/v1`. Forward-compat reservation. |
| `slug` | `string` | yes | Kebab-case identifier. Stable forever — used as the `Agent.seededFromTemplate` value on seeded agents. Examples: `ios-pr-gate`, `android-release-bundle`. |
| `version` | `string` | yes | Semver. Bumping rules in [Versioning](#versioning). Starts at `1.0.0`. |
| `stack` | `string` | yes | One of: `ios`, `android`, `kmm`, `node`, `python`, `go`, `docker`. The detector matches against this. |
| `name` | `string` | yes | Human-facing display name shown in the picker. ≤ 60 chars. |
| `description` | `string` | yes | One-sentence description ending in a period. ≤ 200 chars. Surfaced as the picker card subtitle. |
| `requires_env` | `string[]` | no, default `[]` | Env vars the template depends on. Pre-dispatch validation refuses to run when any are unset. Names follow the stack-prefixed convention (`IOS_*`, `ANDROID_*`, `KMM_*`). |
| `members` | `Member[]` | yes | Ordered list of step definitions. Must contain ≥ 1 member. |

## `Member` shape

| Field | Type | Required | Description |
|--|--|--|--|
| `name` | `string` | yes | Step name within the template. Becomes `${slug}-${name}` on the seeded `Agent`. Kebab-case. |
| `kind` | `string` | yes | Either a registered cibuild step name (e.g. `xcodebuild-build-for-test`, `gradle-build`, `android-lint`) or `'script'`. **Mobile templates must use typed cibuild steps; only non-mobile templates may use `script`.** |
| `inputs` | `object` | yes | Map of step inputs. For typed cibuild steps, keys match the step's input schema. For `script`, the only key is `content`. Values may reference env vars as `${VAR_NAME}` — resolved at execute-time by the runner. |
| `requires_when` | `object` | no | Fact predicate map evaluated at seed time against `DetectorFacts`. Members whose predicate doesn't match are dropped from the seeded protocol. Used for repo-shape-conditional inclusion (e.g. CocoaPods steps included only when `pods: true`). |

### Reserved `script` kind escape hatch

When a typed cibuild step doesn't exist for the needed operation, `kind: script` is allowed. Templates SHOULD prefer typed steps. Use `script` only when:

- A typed step is genuinely missing, AND
- Adding one to cibuild is out of scope for the immediate workstream, AND
- The template is **non-mobile**.

Mobile templates with `kind: script` are rejected by the validator.

### `requires_when` predicate

Equality on a fact lookup, multiple keys ANDed:

```yaml
requires_when:
  pods: true                      # only when DetectorFacts.ios.pods === true
  kmm_integration: cocoapods      # only when DetectorFacts.kmm.integration === 'cocoapods'
```

Supported fact keys (must match `DetectorFacts` shape — see Invarn's `lib/dashboard/stack-detect.ts`):

| Key | Type | Source |
|--|--|--|
| `pods` | `boolean` | `DetectorFacts.ios.pods` |
| `wrapper` | `'workspace' \| 'project' \| 'none'` | `DetectorFacts.ios.wrapper` |
| `kmm_integration` | `'cocoapods' \| 'spm-xcframework' \| 'compose' \| 'manual'` | `DetectorFacts.kmm.integration` |
| `spm_package` | `boolean` | `DetectorFacts.spm` presence (a detected SwiftPM `Package.swift`) |

## Versioning

| Bump | When |
|--|--|
| **Patch** (`1.0.0 → 1.0.1`) | Bug fix in command inputs. No env var changes. No new/removed members. |
| **Minor** (`1.0.x → 1.1.0`) | New OPTIONAL env var (with auto-populated default). New member added. New input field added with a default. |
| **Major** (`1.x.x → 2.0.0`) | Env var renamed. New REQUIRED env var without auto-populated default. Member removed. Substantive command-shape change. |

Templates start at `1.0.0`. The cron sync always picks the highest tag for a given `<slug>`.

## Env var conventions

Templates declare env vars in `requires_env` and reference them in `inputs` as `${VAR_NAME}`. Conventions:

- **Stack-prefixed naming**: `IOS_SCHEME`, `ANDROID_FLAVOR`, `KMM_SHARED_MODULE`, `KMM_INTEGRATION`. Avoids cross-stack collisions.
- **Auto-populated at seed time when the detector is high-confidence**: Invarn writes the detected value as a `ConfigEntry` at `CONNECTION` scope. User can override.
- **Required secrets are documented in `requires_env` but NOT auto-populated**: e.g. `ASC_KEY_ID`, `ASC_KEY_P8_BASE64` for iOS signing. User sets these manually before first dispatch; dispatcher refuses with `PROTOCOL_CONFIGURATION_INCOMPLETE` until they're set.

## Validation

Every template PR triggers `.github/workflows/validate.yml`:

1. Parse the YAML, validate against this schema.
2. Lookup the matching fixture under `fixtures/<fixture-slug>/` (declared in a frontmatter comment — see [Fixture mapping](#fixture-mapping)).
3. *(deferred — the dispatch-validator script lands in a follow-up)*: Synth the template's members into a cibuild pipeline YAML using Invarn's `generateAgentWorkflowYaml` logic, run against the fixture, assert outcome.

For now, schema validation is the gate. Dispatch-validation lands when the script does.

## Fixture mapping

Each template specifies which fixture it validates against via a frontmatter comment:

```yaml
# fixture: ios-spm
# expected_outcome: passed
apiVersion: invarn/v1
slug: ios-pr-gate
...
```

The fixtures themselves live under `fixtures/<slug>/`. Each fixture is a real, minimal CI fixture — typically ≤ 500 LOC and ≤ 3-minute build time. See [`fixtures/ios-spm/README.md`](fixtures/ios-spm/README.md) for the shape.

## Example: minimal valid template

```yaml
# fixture: ios-spm
# expected_outcome: passed
apiVersion: invarn/v1
slug: ios-pr-gate
version: 1.0.0
stack: ios
name: "iOS — PR gate"
description: "Build + unit test on every PR. Recommended starter for iOS repos."
requires_env: [IOS_PROJECT_PATH, IOS_SCHEME]
members:
  - name: deps
    kind: cocoapods-install
    requires_when:
      pods: true
    inputs:
      project_path: "${IOS_PROJECT_PATH}"
  - name: build
    kind: xcodebuild-build-for-test
    inputs:
      project_path: "${IOS_PROJECT_PATH}"
      scheme: "${IOS_SCHEME}"
      configuration: Debug
      destination: auto
  - name: test
    kind: xcode-test-without-building
    inputs:
      project_path: "${IOS_PROJECT_PATH}"
      scheme: "${IOS_SCHEME}"
      destination: auto
```
