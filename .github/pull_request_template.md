<!-- Write this for humans, not for an AI agent: plain, everyday engineering language,
     readable at a glance. That goes double for the TLDR and Before/After sections. -->

## TLDR

<!-- One line per bullet, roughly 10 words each. -->

Problem this solves:

-

How it solves it:

-

## Before / After

<!-- Walk through the same run twice, from the seat of someone sitting at a terminal.
     Lead each list with one plain sentence saying where the run goes wrong (Before) or
     right (After), then number the steps.

     Every step is something that person types or sees: the command and its flags, what
     the report said, what was actually on disk afterward. No internals — do not name
     functions, structs, or source files. "The report listed ~/.cache/uv at 0 B" is
     right; "size_of_dir returned None" is wrong. Keep the two lists step-for-step
     identical until they diverge, so the changed step is obvious.

Example:

Before: a Cargo build dir is reported as reclaimed but survives the delete

1. `diskzap --root ~/projects`
2. The report lists `~/projects/api/target` at 1.2 GB
3. `diskzap --apply --root ~/projects`
4. The summary claims 1.2 GB reclaimed, but `du -sh ~/projects/api/target` still shows 1.2 GB

After: the same run removes it, and the summary matches the disk

1. `diskzap --root ~/projects`
2. The report lists `~/projects/api/target` at 1.2 GB
3. `diskzap --apply --root ~/projects`
4. The summary claims 1.2 GB reclaimed and `~/projects/api/target` is gone
-->

## Relevant issues

<!-- e.g. "Fixes #12" -->

## Does this change what gets deleted?

<!-- Tick whichever apply. Delete this whole section if your change cannot delete a byte. -->

- [ ] Adds or changes an entry in `src/targets.rs`
- [ ] Changes `src/safety.rs`
- [ ] Changes what `--apply` removes

If you ticked any of the above, all three below are required:

- [ ] **Regeneration story** — name the command that recreates every byte this can now
      delete. If nothing recreates it, it is data and does not belong in the catalog.
- [ ] **Marker-gated** — an ambiguous directory name (`target`, `build`, `dist`) is only
      matched with proof of its ecosystem beside it, and the walk continues into the
      directory when that proof is missing.
- [ ] **Test** — a case in `tests/integration.rs` asserts against a real filesystem that
      this removes what it reported and leaves everything else alone.

## Checklist

- [ ] Scope is one problem. Unrelated fixes go in their own PR.
- [ ] `cargo fmt --check`
- [ ] `cargo clippy --all-targets -- -D warnings`
- [ ] `cargo test --all`
- [ ] `README.md` and `SKILL.md` updated if a flag or a behavior changed
