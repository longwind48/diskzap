<div align="center"><pre>
█▀▄ █ ▄▀▀ █ █ ▀▀▀ ▄▀▄ █▀▄
█ █ █ ▀▀▄ █▀▄ ▄▀  █▀█ █▀
▀▀  ▀ ▀▄▄ ▀ ▀ ▀▀▀ ▀ ▀ ▀

Reclaim your disk. Delete nothing you'll miss.
</pre></div>

<p align="center"><strong>Rust CLI · agent skill · dry-run by default · allowlist-only deletion · lock-aware · safe in a loop</strong></p>

<p align="center">
  <a href="https://github.com/longwind48/diskzap/actions/workflows/ci.yml"><img src="https://github.com/longwind48/diskzap/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="https://crates.io/crates/diskzap"><img src="https://img.shields.io/crates/v/diskzap.svg" alt="crates.io"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT"></a>
  <a href="#safety"><img src="https://img.shields.io/badge/deletes-only%20on%20--apply-brightgreen.svg" alt="Dry-run by default"></a>
  <img src="https://img.shields.io/badge/rust-stable-orange.svg" alt="Rust stable">
  <img src="https://img.shields.io/badge/macOS%20%7C%20Linux%20%7C%20WSL-supported-lightgrey.svg" alt="Platforms: macOS, Linux, WSL">
</p>

<p align="center">
  <a href="#quick-start">Quick start</a> ·
  <a href="#install">Install</a> ·
  <a href="#what-it-cleans">What it cleans</a> ·
  <a href="#safety">Safety</a> ·
  <a href="#how-it-compares">How it compares</a> ·
  <a href="#why-not-just-du">Why not <code>du</code>?</a> ·
  <a href="#run-it-weekly">Run it weekly</a> ·
  <a href="SECURITY.md">Security</a>
</p>

---

## The problem

**"Your disk is almost full."** `ENOSPC` mid-build. An install that dies at 97%.

So you go hunting — delete some downloads, empty the trash, buy back 2 GB, full
again next week. The real culprit is invisible: **package caches and build
artifacts.**

| | Typical size | Source |
|---|---|---|
| One `node_modules` | **340 MB** median (720 MB at p75) | [measured across npm projects, 2026](https://enterno.io/en/s/research-npm-dependencies-median-2026) |
| 10–20 projects' worth | 5–15 GB | [reported range](https://www.cluttered.dev/blog/delete-node-modules) |
| Docker, left unpruned | tens of GB | [reported range](https://khides.com/en/blog/developer-disk-cleanup/) |
| A neglected package cache | **340 GB** | this tool exists because of one |

That last row is real, not hypothetical — package managers rarely evict anything,
so a cache pinned to `@latest` keeps every version it ever downloaded.

**None of it is data.** Every byte regenerates: `npm install` re-downloads it,
`cargo build` remakes it. It's the safest space on your disk to delete and usually
the largest — people leave it because `rm -rf` with a glob at 2am is a bad idea
and telling cache from work is genuinely hard.

diskzap draws that line for you, shows the number first, and deletes nothing
until you say so.

<p align="center">
  <img src="demo/demo.gif" alt="diskzap in action" width="900">
  <br/><sub>Dry-run reports 4.4 GB across 8 caches — then <code>--apply</code> reclaims it.<br/>
  Recorded against a sandbox home; re-render with <code>vhs demo/demo.tape</code>.</sub>
</p>

### It's a harness, not a prompt

Ask an agent to free up disk space and it will improvise `rm -rf` from a bash
tool. That works right up until it doesn't: bash hands the harness an opaque
command string, so nothing can inspect what's about to be deleted or stop it.

diskzap replaces that with a **dedicated, gated tool**. Deletion becomes a typed
action the harness can intercept and audit instead of a shell string it has to
trust:

- **Bounded** — deletes only paths resolved from an explicit catalog
  ([`src/targets.rs`](src/targets.rs)). No arbitrary-path delete exists in the code,
  so no prompt can talk it into one.
- **Refuses on doubt** — `/`, `$HOME`, symlink escapes and caches held by a live
  lockfile are declined. [`src/safety.rs`](src/safety.rs) is 184 readable lines;
  [30 tests](#tests) prove it against a real filesystem.
- **Dry-run by default** — reports first, deletes only on `--apply`, so a
  scheduled run can't surprise you.
- **Scanning chosen by measurement, not vibes** — 200k files in 609 ms, faster
  than every Rust/Go disk-usage tool it was [benchmarked](#why-not-just-du) against.
- **Offline** — no network code, no telemetry, two dependencies (`serde`,
  `serde_json`). [SECURITY.md](SECURITY.md) has the threat model.

## Quick start

**1. Install it** into whichever coding assistants you use:

```bash
npx skills add longwind48/diskzap
```

**2. Call it.** No flags to learn:

```
/diskzap
```

It reports what it found, waits for your OK, then reclaims it. You can add
context in the same breath — `/diskzap ~/projects` or `/diskzap just tell me
what's reclaimable` — or skip the slash entirely and say "I'm low on disk space",
which triggers it too.

**3. Make it automatic.** Wrap that call in a weekly loop and stop thinking about
disk space:

```
/loop 7d /diskzap
```

That's Claude Code's `/loop`; other assistants have their own scheduling verb.
The skill handles the rest — it dry-runs first and age-gates so the project
you're actively building never disappears from under you.

<details>
<summary><b>Prefer the raw CLI?</b> It's a normal binary — no assistant needed.</summary>

```bash
diskzap --root ~/projects            # report; deletes nothing
diskzap --apply --root ~/projects    # reclaim it
```

See [All the flags](#all-the-flags) and [Install](#install) for building from
source.
</details>

## Install

`npx skills add longwind48/diskzap` detects whichever coding assistants you
have and asks where to install. It isn't tied to one vendor —
[`npx skills`](https://github.com/vercel-labs/skills) supports Claude Code,
Codex, Cursor, Zed, Warp, Cline, Continue, Crush, OpenClaw, Amp, Replit and dozens
more. To skip the prompt:

```bash
npx skills add longwind48/diskzap --agent '*' -y      # every agent it finds
npx skills add longwind48/diskzap -a codex -a cursor  # or name them
```

### Using [herdr](https://herdr.dev)?

It's also a herdr plugin, so the report gets a pane instead of a scrollback dump:

```bash
herdr plugin install longwind48/diskzap
herdr plugin pane open --plugin longwind48.diskzap --entrypoint report
```

The pane reports first and deletes only if you answer `y`. Bind it to a key by
pointing at the action:

```toml
[[keys.command]]
key = "prefix+k"
type = "plugin_action"
command = "longwind48.diskzap.report"
description = "reclaimable space"
```

Install builds from source, so it needs `cargo` on your `PATH`. To also sweep
build artifacts, list one project dir per line in
`$(herdr plugin config-dir longwind48.diskzap)/roots` — with no such file it
reports package caches and Docker only, and never walks a directory you didn't
name.

**Just want the binary, no assistant?** With a Rust toolchain it's one line:

```bash
cargo install diskzap
```

Otherwise grab a release build — no toolchain needed. Every asset ships with a
`.sha256` beside it:

```bash
# macOS (Apple silicon); swap for x86_64-apple-darwin or x86_64-unknown-linux-gnu
curl -fsSLO https://github.com/longwind48/diskzap/releases/latest/download/diskzap-aarch64-apple-darwin.tar.gz
curl -fsSLO https://github.com/longwind48/diskzap/releases/latest/download/diskzap-aarch64-apple-darwin.tar.gz.sha256
shasum -a 256 -c diskzap-aarch64-apple-darwin.tar.gz.sha256
tar xzf diskzap-aarch64-apple-darwin.tar.gz && ./diskzap --help
```

Or build it yourself, which is the option to prefer if you'd rather not trust a
binary you didn't compile:

```bash
git clone https://github.com/longwind48/diskzap && cd diskzap
cargo build --release
./target/release/diskzap --help
```

Put the binary on your `PATH` to use the short commands above. No Rust toolchain
and no release for your platform? There's a pure-shell fallback with the same
targets in [`references/fallback.md`](references/fallback.md).

### Platform support

| Environment | Works? |
|---|---|
| macOS (Terminal, iTerm, Ghostty…) | ✅ Yes |
| Linux | ✅ Yes |
| **Windows via WSL2** | ✅ Yes — install and run inside the WSL shell |
| Windows: PowerShell / cmd.exe natively | ❌ **No** |

**Windows users need WSL.** Being straight about why, rather than implying
partial support: diskzap resolves your home directory from `$HOME`, which
Windows doesn't set (it uses `%USERPROFILE%`), so it exits immediately. The cache
catalog also only contains Unix paths — the Windows equivalents live under
`%LOCALAPPDATA%` and aren't in it. And CI only builds and tests on Linux and
macOS, so Windows is genuinely unverified, not just undocumented.

Inside WSL it's a normal Linux install and works fully — but note it cleans the
caches of your *Linux* home, not `C:\Users\you\AppData`. Native Windows support
is a welcome contribution — it needs a `USERPROFILE` fallback in `src/main.rs`,
`%LOCALAPPDATA%` entries in `src/targets.rs`, and `windows-latest` added to the
CI matrix.

## All the flags

```bash
diskzap                        # package caches + docker only (no --root)
diskzap --root <dir>           # also scan <dir> for build artifacts; repeatable
diskzap --apply                # delete instead of report
diskzap --min-age-days 14      # skip anything used in the last 14 days
diskzap --include-os-caches    # opt in to ~/Library/Caches (off by default)
diskzap --json                 # machine-readable output
```

## What it cleans

Everything here regenerates. The full catalog lives in
[`src/targets.rs`](src/targets.rs) — that file is the only way diskzap learns
about a deletable thing, so it's short and auditable on purpose.

| Tier | Targets | Default |
|---|---|---|
| **Package caches** | uv · pip · npm · yarn · pnpm · bun · cargo · go · gradle · maven · huggingface | ✅ on |
| **Build artifacts, inside projects** | `node_modules` · `.venv` · `.next` · `target` · `__pycache__` | ✅ on, needs `--root` |
| **Build artifacts, at a fixed path** | Xcode `DerivedData` | ✅ on |
| **Docker** | dangling images + build cache (via `docker system prune -f`) | ✅ on |
| **OS / app caches** | `~/Library/Caches` | ⛔ opt-in |

Build artifacts that live *inside* your projects are only scanned under a
`--root` you name, so diskzap never walks your home directory uninvited. Xcode's
`DerivedData` is build output too, but it sits at one known path instead of
inside any project, so it needs no `--root` and no walking — the same way a
package cache is found. It regenerates by rebuilding rather than re-downloading,
which is slower than every other default-on target, so the report says "a cold
build, not a download" rather than letting you assume it's cheap.

OS caches are off by default because "regenerable" isn't guaranteed for every app
that writes there.

## Safety

Every rule below is enforced in [`src/safety.rs`](src/safety.rs) and asserted by
[the tests](#tests) — not left as a README promise.

| Guarantee | What it means |
|---|---|
| Allowlist only | Deletes only paths resolved from `src/targets.rs`. No arbitrary-path delete exists. |
| Protected paths | `/`, `$HOME`, any ancestor of home, anything under two components deep — all hard-refused. |
| No symlink escape | Paths are canonicalized and confined to their root; symlinks are never traversed. |
| Lock-aware | A fresh package-manager lockfile means "in use" — declined rather than corrupted. |
| Docker delegated | `docker system prune -f` only. Never `-a` (tagged images), never `--volumes` (your data). |
| Dry-run default | `--apply` is the only way anything is removed. |

## How it compares

Disk cleanup is a crowded shelf, so here is the honest version. The tools worth
comparing against are [kondo](https://github.com/tbillington/kondo) (2.4k),
[npkill](https://github.com/voidcosmos/npkill) (9.5k) and
[dust](https://github.com/bootandy/dust) (12.3k).

| | diskzap | kondo | npkill | dust |
|---|---|---|---|---|
| Project build artifacts | 5 types | **20+ types** | `node_modules` only | — |
| Global package caches (uv, pip, npm, cargo, go, gradle…) | ✅ | — | — | — |
| Docker + container VM disks | ✅ | — | — | — |
| Reports without deleting | ✅ default | interactive prompt | interactive | only ever reports |
| Age gate | ✅ `--min-age-days` | ✅ `--older 3M` | — | — |
| Declines a cache held by a live lockfile | ✅ | — | — | — |
| Machine-readable output | ✅ `--json` | — | — | — |
| Ships as an agent skill | ✅ | — | — | — |

**Where kondo wins, plainly:** it covers four times as many project types
(Unity, Unreal, Haskell, Scala, Terraform…), it has a GUI, and it installs from
Homebrew and winget. If your problem is "I have 200 projects in 20 languages and
want the build dirs gone", use kondo — it is the better tool for that job.

**Where this one is different** is the part that has nothing to do with feature
count. kondo's own README opens its usage section with:

> Kondo is *essentially* `rm -rf` with a prompt. Use at your own discretion.
> Always have a backup of your projects.

That is an honest and reasonable thing for an interactive tool to say — a human
reads the list and decides. It is also precisely what you cannot hand to a
scheduler or an AI agent, because there is nobody at the prompt. diskzap is
built for the case where nothing is watching: no arbitrary-path delete exists in
the code, every path resolves from [`src/targets.rs`](src/targets.rs), dry-run is
the default rather than a flag, and `/`, `$HOME` and symlink escapes are refused
by [`src/safety.rs`](src/safety.rs) instead of by the operator's attention.

So the split is roughly: **kondo for a manual sweep across many languages,
diskzap for an unattended one that also gets the package caches and Docker** —
which on most laptops are the bigger numbers anyway.

## Run it weekly

Scheduling is where this earns its keep: you stop discovering the problem at the
moment a build dies. [Quick start step 3](#quick-start) shows the one-liner —
this is the detail behind it.

**Why it's safe to automate.** Two defaults do the work. Dry-run means a
scheduled run reports unless you explicitly asked it to delete, and
`--min-age-days` skips anything you've touched recently, so the `node_modules` of
whatever you're actively building never disappears from under you. Ask for a
weekly *report* rather than a cleanup and you'll get that instead — the skill
follows the intent you state.

**Prefer a plain cron job?** It's an ordinary CLI, so schedule the command
directly — Mondays at 9am, age-gated to two weeks:

```bash
(crontab -l 2>/dev/null; echo "0 9 * * 1 $HOME/.cargo/bin/diskzap --apply --min-age-days 14 --root $HOME/projects") | crontab -
```

Drop `--apply` if you'd rather be told the number and decide for yourself.

## Tests

```bash
cargo test    # 30 tests: 18 unit guardrails + 12 integration
```

The integration suite builds a real temporary home and asserts on the
filesystem afterward — that dry-run leaves every byte in place, that `--apply`
removes exactly what it reported, that a locked cache survives, that OS caches
stay off without the flag, and that artifacts need a `--root`.

## Why not just `du`?

Because sizing is one step of the job, not the job. diskzap resolves a catalog
of cache targets, runs each through the safety guards (protected-path,
symlink-confinement, lock detection), sizes it, and — on `--apply` — deletes it.
`du` only does the sizing, and shelling out to it would split the safety checks
and the measurement across two processes, add a dependency on flags that differ
between BSD and GNU `du`, and force parsing external text instead of owning a
typed result.

So sizing stays in-process. And it's fast enough that this costs you nothing —
200k files (~800 MB), M4 Mac / APFS, `bash bench/bench.sh`
([hyperfine](https://github.com/sharkdp/hyperfine), 10 runs):

| `du -sk` | **diskzap** | `dust` | `diskus` |
|---|---|---|---|
| 408 ms | **609 ms** | 3,961 ms | 5,008 ms |

Within 1.5× of C `du`, and faster than the Rust/Go disk-usage tools. A parallel
walk was tried and measured 4.7× *slower* — see [`src/scan.rs`](src/scan.rs)
before you re-add threads.

## Trust note

`npx skills add` fetches and runs code from this repo. Before installing
anything that can delete files, skim the source — it's deliberately small
(`src/targets.rs` for what it touches, `src/safety.rs` for how it refuses
everything else) — or pin to a tagged commit instead of `main`. Installed that
way, or via `herdr plugin install`, the binary is compiled locally from that
source and nothing prebuilt is downloaded.

The [release builds](https://github.com/longwind48/diskzap/releases) are the one
exception, and being straight about it: those are binaries you did not compile,
produced by [`release.yml`](.github/workflows/release.yml) on GitHub's runners
from the tagged commit. The `.sha256` beside each asset proves the download
matches what was uploaded, not that the upload matches the source. If that
distinction matters to you, build from source — it takes about four seconds.

## Contributing

Two things would help most: **more cache targets** (add an entry to
[`src/targets.rs`](src/targets.rs) with its regeneration story — that's the whole
change) and **native Windows support** (`%USERPROFILE%` fallback,
`%LOCALAPPDATA%` paths, `windows-latest` in CI). Issues and PRs welcome.

Run this once per clone so `git commit` opens with the house style — imperative
subject under 70 characters, body explaining *why*:

```bash
git config commit.template .gitmessage
```

The [PR template](.github/pull_request_template.md) covers the rest. The one part
worth reading before you start: anything that changes what gets deleted needs a
regeneration story, a marker gate for ambiguous directory names, and a test in
`tests/integration.rs` that asserts against a real filesystem.

## License

MIT — see [LICENSE](LICENSE).

---

<p align="center"><sub>If diskzap got you some disk space back, a ⭐ helps others find it.</sub></p>
