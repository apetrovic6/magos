# Styled inlay hint / decoration API for the steel fork

Vendored patches from `Ra77a3l3-jar/helix`, branch `steel-inlay-hints`
(https://github.com/Ra77a3l3-jar/helix/tree/steel-inlay-hints), applied on top
of the locked `helix-w-plugins` (`mattwparas/helix@steel-event-system`) rev in
`../../default.nix`.

## Why these exist

`vista.hx` (in-editor markdown rendering, packaged as
`pkgs.helixPlugins.vista`) draws its rendering with Steel APIs that do **not**
exist upstream:

    add-styled-inlay-hint
    add-styled-line-inlay-hint
    add-overlay!
    add-highlight!
    add-line-background!
    clear-decorations!

`helix-w-plugins@steel-event-system` only has the unstyled `add-inlay-hint`, so
without these patches `vista` fails at `(require ...)`/render time — and
`helix-plugins-nix` says as much in `pkgs/helixPlugins/vista.nix`:

    # doesnt work with pkgs.steelix
    # needs a custom patch on top of the helix steel branch

## Why patches and not the fork

`steel-inlay-hints` is a fork of an **older** `steel-event-system`: relative to
our lock it is `ahead 5 / behind 14` (`github.com/mattwparas/helix/compare/09d67dfe...Ra77a3l3-jar:helix:steel-inlay-hints`).
Switching the input to it would regress 14 upstream commits that the rest of the
config's cogs (oil, scooter, scopeline, connect.hx, helix-file-watcher) currently
run against. The 5 commits themselves are small (~600 lines over 12 files), so
they are vendored onto the existing lock instead.

Applied in filename order (`0001` .. `0007`); they are not independent — `0004`
and `0005` are edits to the code `0002` introduced, and `0006` edits what all of
them introduced. `0007` is unrelated to all of them — it is a separate API on
the same two files.

| patch | upstream commit |
|---|---|
| 0001 | `3ed20dd3402a3de3a6ceae6ef7a78d19191f728a` Add styled inlay hint storage and rendering |
| 0002 | `75e9884241b2fc0376636926cd061c7e2c0b55f1` Add steel API for styled inlay hints |
| 0003 | `b64ce4695933d659d32d0e836f42bb85962d3c63` Add cursor before inlay hints anchored at a line end |
| 0004 | `d6ce45ef2380d9d6887650d80cb11c78f50affb6` Add line placement for styled inlay hints |
| 0005 | `f25de1eac72cc203e7f1e27e3a2d0a6ac612daeb` Add Steel overlay, highlight and background API |
| 0006 | **ours, not upstream** — see below |
| 0007 | **ours, not upstream** — see below |

## 0007 is ours: DAP state for Steel

`0007-add-steel-api-for-dap-frame-scopes-and-variables` adds three
Steel-callable functions to `helix/core/misc`: `dap-current-frame`, returning
the active stack frame as `(path line column)`; `dap-scopes`, returning that
frame's scopes as `(name reference expensive)`; and `dap-variables`, returning
the variables under one reference as `(name type value reference)`. The
traversal is copied from the `dap_variables` command
(`helix-term/src/commands/dap.rs`), driven synchronously with `block_on` from
the binding itself. Every guard (no debug session, target running rather than
stopped, no frame, failed request) returns `#f` / `'()` **silently**, unlike the
command's status messages, because the consumer is a plugin polling on every
selection-did-change; that is what the stop trigger of the inline-values plugin
needs (stopping already moves the cursor, and the cursor move fires Steel's
`selection-did-change` hook).

Scopes and variables are two calls rather than one flattened list so a caller
fetches only what it draws. Measured on a codelldb stop with four locals: all
scopes flattened is 11,529 bytes over 5 DAP round-trips, of which the three
register scopes are ~95%; the Local scope alone is 322 bytes over 2. Which
scope that is stays the caller's decision, because the names are
adapter-specific (codelldb `Local`, debugpy `Locals`, delve
`Locals`/`Arguments`). The DAP `expensive` flag is passed through but is **not**
a usable filter here — codelldb reports `false` for every scope, `Registers`
included. A variable's own reference is returned too, which is what expanding a
struct into its fields would use.

It is local rather than upstream because the only consumer is the Steel inline
plugin this stack is built for
: there is no equivalent of a Steel plugin
upstream to receive it, and Helix's own issue #5927 (inline values, open since
2023) is shaped around editor internals instead. If a clean upstream version
ever emerges, drop this patch.

## 0006 is ours (do not send it anywhere)

`0001`-`0005` introduce two quadratics in the decoration pipeline, and `vista`
hits both on any document with real tables:

1. `View::text_annotations` pushes **one annotation layer per overlay**
   (`add_overlay(slice::from_ref(overlay), highlight)`) because `Layer` binds one
   highlight to a whole layer. `TextAnnotations::overlay_at` then loops over
   **every layer for every grapheme**, so a frame costs `O(overlays × graphemes)`.
2. Every `add-overlay!` / `add-styled-inlay-hint` / `add-line-background!` call
   does `doc.inlay_hints(view_id).cloned()` and re-inserts it, so the plugin pass
   itself is `O(overlays²)`.

`vista` creates roughly one overlay **per character** it renders (a table row is
concealed character by character, `add-highlight!` expands to one overlay per
grapheme). `~/.claude/plans/auth-seam-implementation.md` — 91KB, 1502 lines, 58
table rows — ends up with **28,587 plugin overlays per render pass**.

`0006` keeps all plugin overlays in one document-owned layer sorted by
`char_idx` with a per-entry highlight (`TextAnnotations::add_styled_overlays`),
and grows the inlay-hints snapshot in place through a new
`Document::inlay_hints_mut`. Nothing else in Helix changes: the styled layer is
empty unless a Steel plugin has called the decoration API, so LSP inlay hints,
jump labels and colour swatches take the identical code path as before, and
`overlay_at` consumes the styled layer first only when it is non-empty.

CPU consumed by one cursor move while vista renders that file (100 jiffies = 1s):

| build | per cursor move |
|---|---|
| without 0006 | 166 jiffies (1.66 s) |
| with 0006 | 4 jiffies (40 ms) |
| vista not rendering | 1 jiffy (unpatched-helix baseline) |

`TextAnnotations` build per rendered frame with 0006: 87 µs median, 436 µs max.
Rendered terminal output is byte-identical with and without 0006, and buffer
contents are unaffected (conceals stay display-only).

## Refreshing

Fetch the commits again (they are the only commits that `vista`'s fork adds):

    curl -sL "https://api.github.com/repos/mattwparas/helix/compare/<helix-lock-rev>...Ra77a3l3-jar:helix:steel-inlay-hints" \
      | jq -r '.commits[].sha'   # status: diverged, ahead_by = number of patches

Then test against a new lock without building (`<rev>` = `rev` of
`helix-w-plugins` in `flake.lock`, currently `09d67dfe…`):

    git clone -n https://github.com/mattwparas/helix /tmp/hx && git -C /tmp/hx checkout <rev>
    cd /tmp/hx && for p in .../_config/steel-inlay-hints/000*.patch; do patch -p1 --dry-run -i $p || break; done

Offsets and fuzz are fine (`patch` reported up to +53 offset / 2 fuzz on the
Sep 2026 lock). A hunk that fails outright means the fork needs a rebase — drop
`vista` from `selectPlugins` (and delete `0006`, which only exists to make
`vista` usable) rather than carrying a hand-rebased patch, or move the base input
to a newer commit of `steel-inlay-hints` if it has caught up.

The perf probe behind the numbers above, if you want to confirm a rebase did not
put the quadratic back (CPU deltas of the running `hx`, keystrokes injected
through a pty):

    jif() { p=$(pgrep -n -f "$BIN $FILE"); awk '{print $14+$15}' /proc/$p/stat; }
    # open file, `space m m` (enable), let it settle, one `j`, let it settle, compare

If it comes back, the symptom is a multi-second pause per keystroke on
*table-heavy* markdown only (a plain-prose file of similar size stays quick,
which is what makes it look file-dependent rather than quadratic).
