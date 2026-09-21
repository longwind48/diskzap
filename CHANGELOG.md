# Changelog

Notable changes per release. `create-gh-release-action` reads the section
matching each tag and uses it as the GitHub release notes, so this file is the
source for those — don't write them by hand in the UI.

Dates are the tag date. Versions follow semver: a minor bump adds a flag or a
surface, a patch fixes behaviour without changing the interface.

## [Unreleased]

Nothing yet.

## [0.3.0] - 2026-09-21

### Added
- `--only-roots` reports only what lives under a `--root`, skipping every
  home-anchored cache. Sizing the global caches dominates a run: on one machine
  a report scoped to a single project took **69s**, against **0.85s** with this
  flag. Anyone asking "what does this project cost" was paying for numbers they
  then discarded.
- herdr popup on `prefix+shift+z`, scoped to the focused pane's directory, with
  a `y/N` prompt to reclaim. Sub-second, because it uses `--only-roots`.
- `setup-keys` action, so the keybinding registers itself instead of asking you
  to paste a block into `config.toml`. Idempotent, backs the file up first, and
  keys off the action name so rebinding it by hand can't produce a duplicate.
- Three cache targets: Bun's install cache, Maven's local repository, and Xcode
  `DerivedData`.
- `-V` / `--version`, contributed by @Voyagerroc-Lab in #7.
- Issue templates, including one for proposing a cache target — it asks for the
  regeneration story up front, since that's what decides whether a target is
  accepted.

### Changed
- README restructured: 439 visible lines down to ~150, with reference material
  behind `<details>`, and the CLI and herdr recordings paired and labelled.
- The trust note no longer claims "nothing prebuilt is ever downloaded", which
  shipping release binaries had made false. It now separates the two install
  paths and says what a `.sha256` does and doesn't prove.
- `Cargo.lock` is tracked. This ships binaries, so a tag should be reproducible.

### Fixed
- The comparison table claimed 5 build-artifact types; it's 6. The
  `What it cleans` table was also missing npx, puppeteer, playwright, homebrew
  and every container VM disk. Each tier now carries its count so the total is
  checkable.
- Dropped the hardcoded test count, which had gone stale twice in a week.

## [0.2.0] - 2026-09-21

### Changed
- **Renamed from `cachewipe` to `diskzap`.** The crates.io name was taken since
  2021, so the old name was never publishable. Renaming at one star cost an
  afternoon; renaming after a launch would have cost every install line.
- Published to crates.io: `cargo install diskzap`.
- Release binaries for `aarch64-apple-darwin`, `x86_64-apple-darwin` and
  `x86_64-unknown-linux-gnu`, each with a `.sha256`. Installing no longer needs
  a Rust toolchain.
- Answers "why not kondo" in the README rather than leaving the strongest
  objection unaddressed.

### Added
- herdr plugin: the report gets its own pane.
- PR and commit-message templates. Anything touching the delete catalog needs a
  regeneration story, a marker gate for ambiguous names, and a test.

## [0.1.0] - 2026-07-30

First release, as `cachewipe`.

### Added
- Package caches (uv, pip, npm, yarn, pnpm, cargo, go, gradle, huggingface),
  build artifacts (`node_modules`, `.venv`, `.next`, `target`, `__pycache__`),
  and dangling Docker layers.
- Dry-run by default; `--apply` is the only way anything is removed.
- Refuses `/`, `$HOME`, symlink escapes, and caches held by a live lockfile.
- `--no-external`, so pointing `$HOME` at a scratch directory actually sandboxes
  a run — the delegated cleanups are subprocesses that read their own config and
  reach the real machine regardless.

[0.3.0]: https://github.com/longwind48/diskzap/releases/tag/v0.3.0
[0.2.0]: https://github.com/longwind48/diskzap/releases/tag/v0.2.0
[0.1.0]: https://github.com/longwind48/diskzap/releases/tag/v0.1.0
