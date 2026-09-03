# Invarn template fixtures

This index lists the standalone fixture repositories that the curated templates in this repo target during authoring and regression checks. Each fixture is a small, real, buildable repo that one or more curated templates must produce a green build against.

## Why standalone repos

Each fixture is its own GitHub repo so it can be cloned at root, matching the layout a curated template expects. Templates target a fixture by its repo URL rather than by a subdirectory of this repo.

## Fixture catalog

| Fixture | Repo | Stack | Targeted by |
|--|--|--|--|
| `ios-spm` | [invarnhq/fixture-ios-spm](https://github.com/invarnhq/fixture-ios-spm) | iOS | `ios-pr-gate` (no Pods — deps step drops), `ui-fidelity` (SwiftPM package with renderable SwiftUI views) |
| `ios-pods` | [invarnhq/fixture-ios-pods](https://github.com/invarnhq/fixture-ios-pods) | iOS | `ios-pr-gate` (Pods present — all members run), `ui-fidelity-adhoc` (package-less app shape — seeds with no SwiftPM package; the render package is shipped per run) |
| `android-single` | invarnhq/fixture-android-single (planned) | Android | `android-pr-gate` (empty `ANDROID_FLAVOR`), `android-ui-fidelity` (package-less app shape — seeds with no Gradle render project; the render package is shipped per run) |
| `android-flavors` | invarnhq/fixture-android-flavors (planned) | Android | `android-pr-gate` (multi-flavor) |
| `kmm-spm-xcframework` | invarnhq/fixture-kmm-spm-xcframework (planned) | KMM | `kmm-pr-gate` (SPM/XCFramework integration) |
| `kmm-cocoapods` | invarnhq/fixture-kmm-cocoapods (planned) | KMM | `kmm-pr-gate` (CocoaPods integration) |
| `kmm-compose` | invarnhq/fixture-kmm-compose (planned) | KMM | `kmm-pr-gate` (Compose Multiplatform integration), `kmm-ui-fidelity` (shared Compose UI — the render package and its references are committed) |

## Adding a new fixture

1. Create a standalone public repo at `invarnhq/fixture-<slug>`.
2. Follow the quality bar in `CONTRIBUTING.md` — real, minimal (≤ 500 LOC, ≤ 3-min build), deterministic.
3. Add a row to the catalog table above in the same PR.
4. Use the fixture as the smoke target when authoring or revising a curated template.
