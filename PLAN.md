# erplots development plan

This document tracks scoped-out future development for erplots. It is
not a changelog, but completed work is kept here in condensed form as a
historical record of *why* things are the way they are -- design
decisions and rationale are worth keeping even after the implementation
is done; step-by-step implementation narrative (file-by-file diffs, test
counts, staged PR sequencing) is not, and has been trimmed. See git
history / PR descriptions for that level of detail if it's ever needed.

## Completed: generalising beyond binary responses (continuous/count)

**Motivation.** erplots was originally binary-response-only in three
layers (quantile summary, data strip, VPC), even though the model
curve/ribbon and group panel layers were always response-type-agnostic.
Once `erglm` gained `gaussian`/`Gamma`/`poisson` family support and
matching example columns (`biomarker_change`, `ae_count`, `ae_duration`
alongside `ae1`/`ae2`), this stopped being hypothetical: fitting a
gaussian model and piping it into `er_plot_show_quantiles()` silently
mis-plotted (error bars pinned to y = 0/1) rather than erroring.

**Decisions made:**
- `response_type = c("auto", "binary", "continuous", "count")` on
  `er_plot()`/`er_vpc_plot()`. `"auto"` detects `"binary"` (logical or
  values confined to `{0, 1}`) vs. `"continuous"`, and never resolves to
  `"count"` -- that's opt-in only, so it's purely additive to existing
  auto-detected behaviour.
- Continuous-response quantile bins use a **t-interval** for the mean
  (not a bootstrap), matching the inference convention `erglm` uses for
  dispersion-estimated families.
- Count responses default to being treated as `"continuous"` (mean +
  t-interval) even under `"auto"`, documented as a known approximation;
  `response_type = "count"` is an explicit opt-in fast-follow that swaps
  in an exact Poisson/Garwood interval (`poisson_interval()`), which
  (unlike the t-interval) never produces a negative lower bound for a
  low-count bin.
- The data strip (`er_plot_show_datastrip()`, as it was named then) was
  *not* generalised in this pass -- the binary "responders above the
  line" two-panel design has no direct continuous analogue, so it was
  left erroring loudly for continuous/count responses rather than
  guessing at a design. (Superseded later -- see next section.)

**What changed:** `er_plot()` response-type detection/storage and
scale-aware corner-distance placement for the model layer's p-value
label; `.part_quantile()`/`build_quantile_errorbar()` dispatch on
response type (rate+Clopper-Pearson / mean+t-interval / mean+exact-
Poisson); `er_vpc_plot()` gained the same dispatch for its observed-side
summary; a shared `.abort_continuous_unsupported()` guard was added
first (Stage 5) so nothing could *silently* mis-plot while the
generalisation landed layer by layer, then removed from each call site
as that layer was generalised (it now has no callers -- see below).

**Status:** done, `devtools::check()` clean, full test coverage
including continuous/count fixtures (`er_test_mod_gaussian`,
`er_test_mod_poisson` in `tests/testthat/helper-data.R`),
`vignettes/articles/plot.Rmd`'s "Continuous responses" section
(including a synthetic low-count example demonstrating the t-interval's
negative-lower-bound failure mode vs. the exact Poisson interval's
non-negative one).

## Completed: continuous-response data layer (redesign + rename)

**Motivation.** The above pass's "no continuous variant" call for the
data strip was explicitly left open to revisiting given a concrete use
case; this section is that revisit.

**Naming decision (landed ahead of the redesign):** "data strip" ->
"data layer" throughout (`er_plot_show_datastrip()` ->
`er_plot_show_data()`, `.part_strip()` -> `.part_data()`,
`build_datastrip_jitter()` -> `build_data_jitter()`,
`object$part/plot$strip` -> `$data`, etc.), matching the existing
`model`/`quantile`/`group` "named for what it shows" convention.

**Design chosen for the continuous/count variant:** a single panel,
points jittered along `y = 0` as before, but with `color` mapped
*continuously to the response value* rather than partitioning into
upper/lower panels by a binary flag. Rejected alternatives: a
threshold-split two-panel design (rejected -- the threshold, e.g. the
median, is an arbitrary and under-motivated choice for *every*
continuous response) and a quantile-binned rug (rejected as a first
pass for using more vertical space, but noted as a reasonable fallback
if the color encoding proves hard to read in practice).

**A second, now-default design was added alongside it:** rather than a
separate panel, `build_data_overlay()` plots raw points directly on the
*base* model panel at their true `(exposure, response)` coordinates --
response-type-agnostic (only the amount of jitter differs: a small
vertical nudge for binary 0/1 values, none otherwise), and its `color`
aesthetic (when stratified) is always strata, sharing the base plot's
own legend. `er_plot_show_data()`'s `style` argument defaults to
`"overlay"`; `style = "jitter"` selects the older panel-based design.
The two styles are mutually exclusive (`object$part$data` vs.
`object$part$overlay`).

**Mechanics this forced into the open:**
- The strip composition machinery (`.build_strip_plot()`,
  `.polish_margins()`/`.polish_arrangement()`/`.polish_labels()`) had
  hardcoded exactly two named panels (`upper`/`lower`). Generalised to a
  named list of zero-or-more panels (keyed by stratum level for the
  continuous/count facet fallback), with panel build order/vertical
  position (`"above"`/`"below"`) looked up rather than hardcoded.
- Color no longer reliably means "strata" for every layer. A
  `config$color_role` tag (`"strata"` vs. `"response"`, set by
  `.part_data()`) tells `.polish_labels()`/`.polish_legends()` whether a
  part's legend is the shared, deduplicated strata legend or a
  standalone response colorbar -- consulted instead of inferring
  meaning from `stratify` alone.
- This generalises to a one-sentence rule, now documented in
  `?er_plot`'s "Stratification" section, `?er_plot_show_data`,
  `?er_partial`, and `vignettes/articles/design.Rmd`: **a layer's own
  encoding takes precedence; stratification adapts to whatever channel
  is left**, defaulting to color/fill and falling back to per-stratum
  facets when color is already spoken for. Today only the data layer's
  `style = "jitter"` path (for continuous/count) needs the facet
  fallback.

**Status:** done -- composition refactor, `build_data_color()` +
dispatch, `build_data_overlay()` + new default style, and vignette
updates (`plot.Rmd`'s "Data component" section covers both styles side
by side) all landed. `devtools::check()` clean throughout.

**Open questions, not yet decided (flagging, not blocking):**
- **Color scale.** Every other builder in this package relies on
  ggplot2's default discrete hue scale with no explicit
  `scale_color_*()` call. `build_data_color()`'s continuous colorbar
  uses the default `scale_colour_gradient()`, which may read as lower-
  contrast than a deliberately chosen scale (e.g.
  `scale_colour_viridis_c()`) -- worth a deliberate decision rather than
  defaulting into one.
- **Legibility at scale.** A single continuous color gradient over a
  jittered 1-D strip is a fairly weak channel for reading exact response
  values -- inherent to the chosen design, not a bug, but worth a sanity
  check against a real dataset if it turns out to matter in practice.

## Completed: mini-language documentation (grammar review)

**Motivation.** The response-type work above surfaced two properties of
the mini-language that had never been written down: (1) layers don't
all behave the same way when their `er_plot_show_*()` function is
called twice (`model`/`quantile`/`data` are **singleton** and overwrite;
`group` is **additive** and accumulates), and (2) "stratification always
means color, with one shared legend" is only true until a layer needs
color for something else (see the data layer's `color_role` above).

**What was done:**
- `?er_plot` gained dedicated "Layers are either singleton or additive"
  and "Stratification" sections; every per-layer Rd topic
  (`er_plot_show_model`/`_quantiles`/`_data`/`_groups`) states its own
  singleton-vs-additive status and cross-references them.
- `?er_partial` (the shared `build_*()` builder-contract topic) gained
  the same singleton/additive framing plus a `color_role` explanation
  covering all three data-layer builders
  (`build_data_jitter()`/`build_data_color()`/`build_data_overlay()`) --
  this was the one place the framing hadn't yet landed; closed by adding
  it to the shared roxygen block in `R/er-plot-partials.R` and
  regenerating `man/er_partial.Rd`.
- `vignettes/articles/design.Rmd` (new conceptual/grammar vignette) was
  added, covering the four layers, singleton/additive semantics with
  runnable examples, the stratification color/facet precedence rule, and
  the response-type dispatch table -- and has since been refreshed to
  match the shipped data-layer redesign above (the layer table, the
  "Stratification composes with layers" section, and the response-type
  section had all fallen behind Stage 7b/7d and described a binary-only
  data layer that no longer existed; now describe `style =
  "overlay"`/`"jitter"` and `color_role` accurately).
- `?er_plot`'s previously-shared `@rdname er_plot` page (covering
  `er_plot()`, `er_plot_style()`, and every layer function under one Rd
  topic with one shared `@param` list) turned out to already have been
  split into per-function topics by the time this was checked -- nothing
  further needed there.
- Resolved (not left open): model/quantile/data stay singleton, group
  stays additive; an additive `model` layer (for overlaying two fitted
  curves, e.g. candidate vs. reference) is the one plausible future
  exception, explicitly deferred rather than built speculatively.

**Status:** done. `vignettes/articles/design.Rmd` carries a closing
note that it must be updated in the same change as any future
grammar-altering decision (a rename, a new response-type dispatch, a
change to singleton/additive status, etc.) -- treat a design change that
isn't reflected there as incomplete.

## Other completed fixes

- **Stratified quantile labels visually overlapping.** Two strata's
  labels for the same exposure bin could land on top of each other in
  `build_quantile_errorbar()` (noticed on a `sex`-stratified continuous
  quantile plot, but not specific to continuous responses). Fixed via
  `.dodge_quantile_strata()`, a small symmetric-around-`x_mid` per-
  stratum horizontal offset sized as a fixed fraction of the exposure
  range; points/error bars/labels now plot at the dodged position
  instead of a shared `x_mid`, with the label's color matched to its
  stratum.

## Open / deferred (no concrete need yet -- not scheduled)

- **Additive model layer.** Overlaying two fitted model curves (e.g. a
  candidate vs. a null/reference model, or Emax vs. linear) isn't
  possible today since `er_plot_show_model()` is singleton. Real work,
  comparable to the data layer's stratified-legend handling -- deferred
  until a concrete request exists.
- **Data layer color scale.** Whether `build_data_color()` should use a
  deliberately chosen continuous scale (e.g. viridis) instead of
  ggplot2's default gradient -- see "Open questions" above.
- **Quantile-binned rug** as a fallback data-layer design, if the
  single-panel continuous color encoding turns out to be hard to read in
  practice -- see "Design chosen" above.
