# erplots development plan

This document tracks scoped-out future development for erplots. It is
not a changelog, but completed work is kept here in condensed form as a
historical record of *why* things are the way they are -- design
decisions and rationale are worth keeping even after the implementation
is done; step-by-step implementation narrative (file-by-file diffs, test
counts, staged PR sequencing) is not, and has been trimmed. See git
history / PR descriptions for that level of detail if it's ever needed.

## Planned: builder-level style customisation arguments

A review of every exported `er_style_*()` builder found a long list of
hardcoded, purely visual constants (jitter width/height, alpha,
linewidth, point/label size, dodge spacing, hex bin count, ribbon fill,
vline colour/linetype, etc.) with no way for a caller to override them
short of writing a full custom builder. This section scopes out
exposing the highest-value ones as explicit function arguments, per
three cross-cutting decisions made up front:

1. **Explicit named arguments with defaults, not a `...`-only escape
   hatch.** Every new knob gets its own documented parameter (with a
   sensible default reproducing today's behaviour) on the relevant
   `er_style_*()` builder, so it's discoverable via autocomplete and
   `?er_style_*` -- not just reachable by knowing to pass an
   undocumented name through `...`. `...` passthrough (see AGENTS.md's
   "Passing extra arguments to a builder" section) remains for genuine
   one-offs (e.g. `er_style_model_spaghetti()`'s `seed`), but every
   argument listed below is promoted to a first-class parameter.
2. **Names mirror ggplot2's own vocabulary wherever the semantics
   match.** `alpha`, `linewidth`, `size`, `bins`, `width`, `height`,
   `linetype` are reused verbatim from the geoms these builders already
   wrap, so a user who knows ggplot2 doesn't have to learn a parallel
   vocabulary. Where a value isn't a literal geom parameter (e.g. the
   quantile errorbar's width is computed as a *fraction* of the exposure
   range, not an absolute value), the argument name says so explicitly
   (`errorbar_width`, documented as a fraction) rather than reusing the
   bare geom name and implying identical units.
3. **Cross-layer/stratification-wide settings move to
   `er_plot_theme()`, not a per-builder argument.** Only one candidate
   fit this: the quantile layer's stratum-dodge spacing
   (`.dodge_quantile_strata()`'s `step`), which is conceptually about
   how stratification lays out *any* dodged layer, not one builder's own
   look. This becomes `er_plot_theme(dodge_width = ...)` (`object$theme$dodge_width`,
   default `0.05`, a fraction of the exposure range -- matching the
   existing hardcoded value), threaded into `config` by `.layer_quantile()`
   and read by `.dodge_quantile_strata()` via `theme$dodge_width` inside
   the quantile builders that call it. No other candidate cut across
   layers enough to justify a theme-level home over a builder argument.

Where a current hardcoded value already depends on `stratify` or
`config$response_type` (e.g. `er_style_data_overlay()`'s jitter height,
`er_style_model_spaghetti()`'s spaghetti alpha), the new argument
defaults to `NULL`, preserving that conditional default; an explicit
value overrides it uniformly regardless of `stratify`/response type.

### Model layer (`R/er-plot-style-model.R`)

- **`er_style_model_ribbonline()`**: `ribbon_fill = "grey40"` (only
  takes effect when unstratified -- stratified ribbons already map
  `fill = strata`; documented as such), `ribbon_alpha = 0.25`,
  `linewidth = 1`, and a new feature, `ribbon_edges = FALSE` -- when
  `TRUE`, additionally draws `geom_path()` at the ribbon's own
  `ci_lower`/`ci_upper` bounds (the concrete case from this thread's
  opening question).
- **`er_style_model_line()`**: `linewidth = 1`.
- **`er_style_model_spaghetti()`**: `alpha = NULL` (default: `0.1`
  unstratified / `0.25` stratified, matching today), `linewidth = 1`
  (mean line), `nsim = 100L`. `seed` (already supported via `...`) is
  unaffected.

### Summary layer (`R/er-plot-style-summary.R`)

All four builders (`er_style_summary_pvalue()`, `_n()`,
`_coefficients()`, `_gof()`) share the same corner-placement
`geom_label()` pattern:

- **All four**: `inset = 0.05` -- the label's distance from the panel
  edge, in normalized device coordinates (replaces the hardcoded
  `.05`/`.95` pair; `.95` becomes `1 - inset`).
- **`er_style_summary_gof()`** additionally: `fields = c("n", "aic",
  "bic", "r_squared")` -- which of `glance`'s curated fields to show,
  and in what order (currently hardcoded to all four in a fixed order).

`label_size`/`label_fill`/etc. are left at `geom_label()`'s own
defaults for now (never overridden today) -- not part of this round
unless a concrete need surfaces.

### Quantile layer (`R/er-plot-style-quantile.R`)

- **`er_style_quantile_errorbar()`**: `point_size = 2`,
  `errorbar_width = 0.025` (fraction of the exposure range, matching
  today's `0.025 * (exposure$limits[2] - exposure$limits[1])`),
  `label_size = 3`.
- **`er_style_quantile_errorbar_vlines()`**: redeclares
  `point_size`/`errorbar_width`/`label_size` (forwarded to
  `er_style_quantile_errorbar()`) plus its own `vline_colour =
  "grey50"`, `vline_linetype = "dotted"`.
- **`er_style_quantile_pointrange()`**: `label_size = 3`; optionally
  also exposes `pointrange_size`/`pointrange_linewidth` (ggplot2's own
  `geom_pointrange()` parameters, currently left at their defaults) for
  symmetry with the errorbar builder's `point_size` -- lower priority,
  since nothing is hardcoded here today.
- **`er_style_quantile_pointrange_vlines()`**: redeclares
  `label_size` (plus `pointrange_size`/`pointrange_linewidth` if added)
  forwarded to `er_style_quantile_pointrange()`, plus its own
  `vline_colour = "grey50"`, `vline_linetype = "dotted"`.
- **Dodge width**: moved to `er_plot_theme(dodge_width = 0.05)` per
  decision 3 above -- not a per-builder argument.

### Data layer (`R/er-plot-style-data.R`)

- **`er_style_data_overlay()`**: `jitter_height = NULL` (default:
  `0.05` for a binary response, `0` otherwise, matching today),
  `alpha = 0.4`, `size = 1`.
- **`er_style_data_boxjitter()`**: `box_width = 0.6`, `box_alpha =
  0.4`, `show_outliers = FALSE` (maps to `outlier.shape = NA`/default
  shape), `jitter_height = NULL` (default: `0.3` stratified / `0.15`
  unstratified, matching today), `jitter_size = 1`, `jitter_alpha =
  0.6`.
- **`er_style_data_hex()`**: `bins = 30`.

### Group layer (`R/er-plot-style-group.R`)

- **`er_style_group_boxplot()`**: `alpha = 0.5`.
- **`er_style_group_violin()`**: `alpha = 0.5`. Also noted in passing:
  the existing `quantile.linetype = "solid"` argument to
  `geom_violin()` is currently inert, since `draw_quantiles` (the
  argument that actually enables drawn quantile lines) is never set --
  worth a decision (fix the dead parameter by adding a `quantiles =
  NULL` argument mapped to `draw_quantiles`, or drop
  `quantile.linetype` entirely) alongside this round, not before it.
- **`er_style_group_histogram()`**: `bins = 30`, `alpha = NULL`
  (default: `0.5` stratified / `0.8` unstratified, matching today).

### Not carried forward from the original brainstorm

- Per-corner `hjust`/`vjust` and exact label x/y aren't independently
  exposed -- `inset` covers the one thing worth controlling (how close
  to the edge), and the corner itself is chosen automatically from the
  data, not user-set.
- `show.legend`, `key_glyph`, and other structural/legend-plumbing
  arguments stay internal -- these aren't visual style choices a user
  tunes per plot.

### Status

**Data layer: done.** `er_style_data_overlay()` (`jitter_height = NULL`,
`alpha = 0.4`, `size = 1`), `er_style_data_boxjitter()` (`box_width =
0.6`, `box_alpha = 0.4`, `show_outliers = FALSE`, `jitter_height =
NULL`, `jitter_size = 1`, `jitter_alpha = 0.6`), and `er_style_data_hex()`
(`bins = 30`) all gained the arguments listed above, exactly as scoped
-- each `NULL` default reproduces the previous conditional behaviour
(response-type-aware for `_overlay()`, stratify-aware for
`_boxjitter()`), and every other default reproduces the previous fixed
constant. `show_outliers` maps to `geom_boxplot()`'s `outlier.shape`
(`19` when `TRUE`, `NA` when `FALSE`, discovered via
`geom_params$outlier_gp$shape` under the ggplot2 version in use here --
`outliers`/`outlier_gp` is ggplot2 4.x's internal split of what used to
be a flatter set of `outlier.*` arguments). `@param` docs added to the
shared `er_style_data` roxygen block; one new `@examples` entry
demonstrates overriding `er_style_data_overlay()`'s three arguments.
New tests in `tests/testthat/test-er-plot-style-data.R` cover each
builder's default-reproduces-old-behaviour case, each explicit-override
case, and one integration test confirming `er_plot_add_data(style =
er_style_data_overlay, jitter_height = ..., alpha = ..., size = ...)`
correctly forwards through `...` end to end via `er_plot_build()`.
`devtools::test()` (710 passing) and `devtools::check()` (0 errors/
warnings/notes) both clean.

**Model layer: done.** `er_style_model_ribbonline()` gained
`ribbon_fill = "grey40"` (unstratified only), `ribbon_alpha = 0.25`,
`ribbon_edges = FALSE`, and `linewidth = 1`; `er_style_model_line()`
gained `linewidth = 1`; `er_style_model_spaghetti()` gained
`alpha = NULL` (default: `0.1` unstratified / `0.25` stratified,
matching before), `linewidth = 1` (mean line), and `nsim = 100L`.
`ribbon_edges = TRUE` adds a dashed `geom_path()` at `ci_lower`/
`ci_upper` (colour mapped to strata when stratified, matching the main
line) -- implemented so the returned geom list stays length 2 by
default and only grows to length 4 when `ribbon_edges` is requested,
rather than always including a pair of `NULL` placeholders (a `NULL`-
padded list is a silent `ggplot2::ggplot_add.NULL` no-op at *render*
time, matching the `_vlines` quantile builders' trick, but this
builder's own return length is asserted on directly by existing tests,
so padding it unconditionally would have been a visible regression).
`er_style_model_spaghetti()`'s fallback call to `er_style_model_ribbonline()`
(when `er_simulate()` isn't implemented for a model) now explicitly
forwards its own `linewidth` argument alongside `...`, so a caller's
`linewidth` override still applies to the fallback ribbon+line. `seed`
remains `...`-only, unchanged. `@param` docs added to the shared
`er_style_model` roxygen block; two new `@examples` entries demonstrate
overriding `er_style_model_ribbonline()`'s and
`er_style_model_spaghetti()`'s arguments. New tests in
`tests/testthat/test-er-plot-style-model.R` cover each builder's
default-reproduces-old-behaviour case, each explicit-override case
(including `ribbon_edges`'s geom count/colour mapping and
`nsim`'s effect on the number of distinct `sim_id`s), and the
fallback-forwards-`linewidth` case. `devtools::test()` (738 passing)
and `devtools::check()` (0 errors/warnings/notes) both clean.

**Quantile layer: done.** `er_style_quantile_errorbar()` gained
`point_size = 2`, `errorbar_width = 0.025`, `label_size = 3` and
`er_style_quantile_pointrange()` gained `label_size = 3`, plus
optional `pointrange_size`/`pointrange_linewidth`. `_vlines` variants
were updated to expose `vline_colour`/`vline_linetype` and to forward
these plus the shared quantile args into the base builders. `@param`
docs were added and `@examples` updated to show overriding the new
arguments. `tests/testthat/test-er-plot-style-quantile.R` covers the new
arguments (default & explicit-override cases) and the `_vlines`
variants' behaviour. `devtools::test()` and `devtools::check()` were
run locally and pass.

**Summary layer: done.** `er_style_summary_pvalue()`,
`er_style_summary_n()`, `er_style_summary_coefficients()`, and
`er_style_summary_gof()` now expose `inset`, `label_size`,
`label_colour`, and `label_fill`, with `er_style_summary_gof()` also
accepting a `fields` argument. `tests/testthat/test-er-plot-style-summary.R`
covers these new arguments and the existing corner-placement behaviour.

**Group layer: done.** `er_style_group_boxplot()`,
`er_style_group_violin()`, and `er_style_group_histogram()` already
expose the planned style arguments (`alpha`, `bins`, `quantiles`,
`quantile_linetype`) and the tests in
`tests/testthat/test-er-plot-style-group.R` verify their defaults and
explicit overrides.

## Completed: bundled `erplots_data` example dataset

Added erplots' own simulated dataset (`data/erplots_data.rda`, built by
`data-raw/erplots_data.R`, documented in `R/data.R`) rather than relying
solely on `erglm`/`emaxnls`'s example data for the package's own
examples/vignettes. Design goals: multiple (three) continuous exposure
columns, response columns spanning all three response types, one
exposure/response pair suited to each of Emax-continuous, Emax-binary,
logistic regression, linear regression, and Poisson regression, a
placebo arm plus multiple dose levels, a few plausible covariates, and
enough rows (4,000) that raw-point overplotting is genuinely visible
(motivating `er_style_data_hex()`). All five modelling scenarios were
validated end to end against real `erglm`/`emaxnls` fits before
finalizing the simulation parameters -- not just plausible-looking code,
but confirmed parameter recovery close to the simulated truth.

A follow-up added a sixth column, `study_id`, generated independently of
dose/exposure/response purely so it's convenient to filter on --
subsetting to one study shrinks N substantially (as low as 400 rows)
while still spanning the full dose range, for illustrating the same
plot at smaller sample sizes (e.g. when a raw overlay stops overplotting
and a hex/density summary is no longer the better choice). Unevenly
sized (400/800/1200/1600 across 4 studies) so there's a genuinely small
one to filter down to, rather than four equal quarters.

Verified clean: `devtools::document()`, `devtools::test()` (809 passing,
unaffected -- purely additive), and `devtools::check()` (0 errors/
warnings/notes). See AGENTS.md's "Bundled example dataset: `erplots_data`"
section for the full column-by-column rationale.

**Open / deferred, not scheduled:** a dedicated
`vignettes/articles/erplots-data.Rmd` walkthrough of all five scenarios
end-to-end (currently just a one-sentence pointer from
`vignettes/erplots.Rmd` plus `?erplots_data`'s own `@examples`); tests
asserting `study_id`'s independence from dose/exposure/response
directly (currently just eyeballed via `table(study_id, dose_group)`
during development, not asserted in `tests/testthat/`).

## Planned: stress-test findings (input validation gaps)
