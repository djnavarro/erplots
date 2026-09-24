---
name: write-news-entries
description: Guidance for writing entries in NEWS.md for the erplots R package. Use whenever adding, updating, or reviewing a NEWS.md entry, e.g. after implementing a new feature, fixing a bug, or making an API change.
---

# Writing NEWS.md Entries

`NEWS.md` is a user-facing changelog, not a commit log or a design document.
Unreleased changes accumulate under the top heading of the file, which
carries the current in-development version number matching `DESCRIPTION`
(e.g. `# erplots 0.2.0.9000`), grouped into `## New features`,
`## Improvements`, `## Bug fixes`, `## Testing`, and `## Documentation`
subsections (a heading with no subsections yet, or a single flat bullet
list, is also fine for a small release -- see `# erplots 0.1.2`/`0.1.1` in
the file today). When a release is cut, that heading's version number
drops the `.9000` development suffix (e.g. `# erplots 0.2.0`) and a fresh
heading with the next in-development version is added above it for the
next cycle.

Unlike its sibling package `ertte` (GitHub-only, pre-CRAN), erplots has
already shipped several CRAN releases -- `NEWS.md`'s `# erplots 0.1.0`
("Initial CRAN submission"), `# erplots 0.1.1`, and `# erplots 0.1.2`
headings are real, released versions, not drafts. That makes the
distinction in rule 3 below live: a bug introduced since the last released
heading is a same-cycle fix (fold it into the feature, don't call it out
separately), but a regression in code that shipped in `0.1.2` or earlier
is a genuine, user-visible `## Bug fixes` entry.

Two failure modes recur when writing entries here: restating information
that already lives elsewhere (function documentation, a linked GitHub
issue), and describing a bug fix for code that was only ever broken within
the current, unreleased development cycle. The rules below exist to avoid
both.

## Rules

1. **Keep it short.** One sentence is usually enough; two only if the
   change genuinely needs it. A bare function name like
   `` er_plot_add_quantiles() `` is auto-linked by pkgdown straight to its
   help page, so do not restate parameter names, defaults, algorithmic
   detail, or examples that are already covered in that function's
   `@details`/`@examples`. The NEWS entry's job is to say *that* something
   changed and give just enough context to decide whether to click through
   — not to duplicate the documentation.

2. **NEWS.md is strictly user-facing.** Never reference or link to
   agent-facing or contributor-facing material: skills, `AGENTS.md`,
   `.agents/HISTORY.md`/`.agents/PLAN.md`, internal dot-prefixed helper
   functions (e.g. `.layer_model()`, `.polish_labels()`,
   `.dodge_group_jitter()`), CI configuration, or "how we implemented this"
   narrative. If a change has no visible effect on the public API,
   documented behavior, or output (e.g. an internal helper was refactored,
   `.check_style_response_type()` gained a case nothing exported surfaces
   differently), it does not belong in NEWS.md at all — skip it rather than
   finding a way to phrase it.

3. **Only describe what changed since the last CRAN release.** Check the
   heading at the top of the file: everything under the current
   `.9000`-suffixed development heading is unreleased. If a bug being fixed
   was introduced by a feature added earlier in the *same* development
   cycle (i.e. that feature has never shipped to CRAN), it is not a
   user-visible "bug fix" — it's the feature working correctly. Don't add a
   `## Bug fixes` entry for it; either revise the original feature's own
   bullet if it needs correcting, or just fix the code silently. Only
   regressions in code that already shipped in a previous numbered release
   (`0.1.2`, `0.1.1`, or `0.1.0`, at the time of writing) deserve their own
   `## Bug fixes` bullet.

4. **Point to the issue/PR instead of re-explaining it.** Append `(#N)` to
   the end of the bullet when a GitHub issue or PR number exists. Don't
   restate the issue's background, discussion, or design rationale — that
   history is already written down in the issue itself, one click away.

5. **Match the existing structure and voice.** Group each bullet under the
   closest matching heading (`## New features`, `## Improvements`,
   `## Bug fixes`, `## Testing`, `## Documentation`), only adding a new
   heading if none fits (a small release can also stay a flat bullet list
   with no subsections, matching `# erplots 0.1.2`). Start each bullet
   with a past-tense verb ("Added", "Fixed", "Changed", "Removed",
   "Deprecated").

## Example

Too long — restates documentation detail and mentions an internal helper:

```md
- Added a `seed` argument to `er_style_data_overlay()` and
  `er_style_data_boxjitter()` that controls the RNG used for jittering:
  when supplied, repeated `plot()` calls on the same object show
  identical jitter; when left `NULL` (the default), jitter draws from
  the ambient RNG stream and differs from one build to the next.
  Internally, both builders read `seed` out of their own `...` via
  `dots <- rlang::list2(...); seed <- dots$seed` and pass it straight
  through to `ggplot2::position_jitter()`'s own `seed` argument rather
  than wrapping construction in `withr::with_seed()`, since the jitter
  itself is only realised lazily at `ggplot_build()` time (#41).

- `.dodge_group_jitter()` now accepts a `seed` argument too, for
  consistency with the two builders above (#41).
```

Right level of detail — says what changed, links to the function for the
rest, skips the internal-only change entirely:

```md
- `er_style_data_overlay()`/`er_style_data_boxjitter()` gain an opt-in
  `seed` argument for reproducible jitter across rebuilds of the same
  object; with no `seed` (the default), jitter differs from one build to
  the next, like any other jittered geom (#41).
```

## Checklist before adding an entry

- [ ] Is this visible to a user of the package, not just to future
      contributors? If not, skip NEWS.md entirely.
- [ ] If this is a bug fix, did the bug exist in a previously released
      version (`0.1.2`, `0.1.1`, `0.1.0`), rather than being a same-cycle
      regression in unreleased code under the current `.9000` heading?
- [ ] Is the bullet one or two sentences, with parameter/implementation
      detail left to the function's own documentation?
- [ ] Does it rely on pkgdown's auto-linking of bare function names rather
      than re-describing what that link leads to?
- [ ] Does it append `(#N)` instead of re-explaining the linked issue/PR?
- [ ] Does it avoid mentioning skills, `AGENTS.md`, `.agents/*.md`, internal
      dot-prefixed helpers, or other agent/contributor-facing material?
