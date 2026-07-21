# erplots development plan

This document tracks scoped-out future development for erplots. It is
not a changelog, but completed work is kept here in condensed form as a
historical record of *why* things are the way they are -- design
decisions and rationale are worth keeping even after the implementation
is done; step-by-step implementation narrative (file-by-file diffs, test
counts, staged PR sequencing) is not, and has been trimmed. See git
history / PR descriptions for that level of detail if it's ever needed.

## Completed: removing `er_builder_quantile_bar()`, adding `_vlines` quantile builder variants

**Motivation.** On review, `er_builder_quantile_bar()` (bar + error bar)
didn't earn its keep as a built-in: it's not an idiom that shows up in
real exposure-response reporting. Meanwhile, drawing a dotted line at
each quantile-bin boundary -- so a reader can see exactly where one bin
ends and the next begins without inferring it from point/error-bar
spacing -- *is* a common real-world annotation, and wasn't available
from any built-in builder.

**Decisions made:**
- `er_builder_quantile_bar()` removed outright (no deprecation shim --
  same rationale as the naming-scheme rename: GitHub-only/pre-CRAN, no
  installed user base to break silently).
- `cut_exposure_quantile()` now attaches the `n + 1` quantile cutpoints
  (excluding placebo) it computes internally as a `"breaks"` attribute
  on its returned factor, rather than discarding them. `.part_quantile()`
  reads this back off `exposure_bins` (attributes on a factor column
  survive a plain `dplyr::mutate()` assignment) into a new
  `config$breaks` field, so builders can draw boundary separators
  without recomputing quantiles themselves.
- Two new builders, `er_builder_quantile_errorbar_vlines()` and
  `er_builder_quantile_pointrange_vlines()`, are thin wrappers around
  the existing `er_builder_quantile_errorbar()`/
  `er_builder_quantile_pointrange()` that prepend a single
  `geom_vline(xintercept = <interior breaks>, linetype = "dotted")` to
  the wrapped builder's own geom list (`c(list(vlines), geoms)` --
  `ggplot2::ggplot_add.NULL` makes a `NULL` vline, when there are no
  interior boundaries to draw, a silent no-op rather than requiring
  special-casing). "Interior" breaks drop the overall min/max, since
  those sit at/beyond the panel's own edges and aren't boundaries a
  reader would need marked. Implemented as wrappers, not copies, so the
  two variants can't drift from the builders they're based on.
- Both new builders are tagged `er_builder_tag(fn, layer = "quantile")`,
  matching every other built-in quantile builder.

**What changed:** `R/utils-helpers.R` (`cut_exposure_quantile()`'s
`"breaks"` attribute), `R/er-plot-part.R` (`.part_quantile()`'s
`config$breaks`), `R/er-plot-builder-quantile.R` (`er_builder_quantile_bar()`
removed; `.quantile_boundary_vlines()` helper and the two new `_vlines`
builders added), `R/er-plot-api.R` (`er_plot_add_quantiles()` docs/
examples), tests in `tests/testthat/test-er-plot-builder-quantile.R`
(bar tests removed, new tests for `config$breaks` and both `_vlines`
builders added) and `test-er-plot-part.R`/`test-er-plot-api.R` (updated
for the new `config$breaks` field and `er_builder_quantile_bar()`'s
removal), `vignettes/articles/extending.Rmd` (its config-contents table
and worked example's builder-alternatives list), `NAMESPACE`/`man/`
regenerated via `devtools::document()`.

**Status:** done, `devtools::check()` clean (0 errors/warnings/notes),
full test suite passing (471 tests).

## Completed: generalising beyond binary responses (continuous/count)

**Motivation.** erplots was originally binary-response-only in three
layers (quantile summary, data strip, VPC), even though the model
curve/ribbon and group panel layers were always response-type-agnostic.
Once `erglm` gained `gaussian`/`Gamma`/`poisson` family support and
matching example columns (`biomarker_change`, `ae_count`, `ae_duration`
alongside `ae1`/`ae2`), this stopped being hypothetical: fitting a
gaussian model and piping it into `er_plot_add_quantiles()` silently
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
  in an exact Poisson/Garwood interval (`ci_poisson()`), which
  (unlike the t-interval) never produces a negative lower bound for a
  low-count bin.
- The data strip (`er_plot_show_datastrip()`, as it was named then) was
  *not* generalised in this pass -- the binary "responders above the
  line" two-panel design has no direct continuous analogue, so it was
  left erroring loudly for continuous/count responses rather than
  guessing at a design. (Superseded later -- see next section.)

**What changed:** `er_plot()` response-type detection/storage and
scale-aware corner-distance placement for the model layer's p-value
label; `.part_quantile()`/`er_builder_quantile_errorbar()` dispatch on
response type (rate+Clopper-Pearson / mean+t-interval / mean+exact-
Poisson); `er_vpc_plot()` gained the same dispatch for its observed-side
summary; a shared `.abort_continuous_unsupported()` guard was added
first (Stage 5) so nothing could *silently* mis-plot while the
generalisation landed layer by layer, then removed from each call site
as that layer was generalised (it now has no callers -- see below).

**Status:** done, `devtools::check()` clean, full test coverage
including continuous/count fixtures (`er_test_mod_gaussian`,
`er_test_mod_poisson` in `tests/testthat/helper-data.R`),
`vignettes/articles/plot-count.Rmd`'s "Quantile component" section
(including a synthetic low-count example demonstrating the t-interval's
negative-lower-bound failure mode vs. the exact Poisson interval's
non-negative one). (At the time this landed, the worked example lived in
a single combined `plot.Rmd`, later split into per-response-type
articles -- see "Completed: splitting the plotting vignette by response
type" below.)

## Completed: continuous-response data layer (redesign + rename)

**Motivation.** The above pass's "no continuous variant" call for the
data strip was explicitly left open to revisiting given a concrete use
case; this section is that revisit.

**Naming decision (landed ahead of the redesign):** "data strip" ->
"data layer" throughout (`er_plot_show_datastrip()` ->
`er_plot_add_data()`, `.part_strip()` -> `.part_data()`,
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
separate panel, `er_builder_data_overlay()` plots raw points directly on the
*base* model panel at their true `(exposure, response)` coordinates --
response-type-agnostic (only the amount of jitter differs: a small
vertical nudge for binary 0/1 values, none otherwise), and its `color`
aesthetic (when stratified) is always strata, sharing the base plot's
own legend. `er_plot_add_data()`'s `style` argument defaults to
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
  `?er_plot`'s "Stratification" section, `?er_plot_add_data`,
  `?er_partial`, and `vignettes/articles/design.Rmd`: **a layer's own
  encoding takes precedence; stratification adapts to whatever channel
  is left**, defaulting to color/fill and falling back to per-stratum
  facets when color is already spoken for. Today only the data layer's
  `style = "jitter"` path (for continuous/count) needs the facet
  fallback.

**Status:** done -- composition refactor, `build_data_color()` +
dispatch, `er_builder_data_overlay()` + new default style, and vignette
updates (the then-combined `plot.Rmd`'s "Data component" section covered
both styles side by side; that content now lives in
`plot-binary.Rmd`/`plot-continuous.Rmd`/`plot-count.Rmd`, see "Completed:
splitting the plotting vignette by response type" below) all landed.
`devtools::check()` clean throughout.

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
  (`er_plot_add_model`/`_quantiles`/`_data`/`_groups`) states its own
  singleton-vs-additive status and cross-references them.
- `?er_partial` (the shared `build_*()` builder-contract topic) gained
  the same singleton/additive framing plus a `color_role` explanation
  covering all three data-layer builders
  (`build_data_jitter()`/`build_data_color()`/`er_builder_data_overlay()`) --
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

## Completed: formalising the `builder`/`summary_builder` escape hatch

**Motivation.** `.build_*_geoms()` always calls whatever function lives
in `config$builder` (or `config$builder$model`/`$summary` for the model
layer), regardless of how it got there -- so a user could already
override a layer's drawing logic by reassigning
`object$part$<layer>$config$builder` directly after calling the normal
`er_plot_show_*()` function. This worked, but was undocumented, required
knowing the internal list structure, and wasn't exposed as an argument
anywhere.

**What was done:**
- Every `er_plot_show_*()` function gained a `builder` argument
  (`er_plot_add_model()` additionally gained `summary_builder`) that
  gets threaded through to the corresponding `.part_*()` function and
  assigned into `config$builder` in place of the `style`-string dispatch,
  with validation (`builder` must be a function or `NULL`; an
  unrecognised `style` without a `builder` now errors clearly instead of
  failing obscurely downstream). This also resolved the long-standing
  `.part_model()` TODO about customising the summary annotation without
  breaking the `style` arg.
- For the data layer, `style` keeps its *structural* meaning even when
  `builder` is supplied: `"overlay"` (single call merged into the main
  panel) vs. `"jitter"` (one-or-more panels stacked below the base plot,
  per `object$response$type`) -- `builder` only swaps out the geoms drawn
  within whichever structure `style` selects. The other three layers
  have a single structural call site, so `style` is simply ignored once
  `builder` is supplied.
- `?er_partial` gained a "Writing your own builder" section stating the
  contract explicitly (the shared signature is public API, not an
  implementation detail), and each layer function's own Rd topic
  documents its `builder`/`summary_builder` argument with a worked
  example (a dashed model curve, a quantile crossbar, a data-overlay
  scatter).
- `vignettes/articles/design.Rmd` gained an "Extending erplots: writing
  your own builder" section (runnable custom-quantile-builder example,
  cross-referencing `?er_partial` and the per-layer examples).
- `er_builder_quantile_pointrange()` (a single `geom_pointrange()` in place of
  `er_builder_quantile_errorbar()`'s separate point + error bar) started as a
  hypothetical example of the escape hatch and was promoted to a
  built-in `er_plot_add_quantiles(style = "pointrange")` option, since
  it needed no new `config` fields beyond what `.part_quantile()`
  already computes for `er_builder_quantile_errorbar()` -- a template for
  deciding whether a custom builder is worth proposing upstream.

**Status:** done. `devtools::check()` clean; new tests cover the
`builder`/`summary_builder` arguments on all four layer functions and
the `style = "pointrange"` render path.

## Completed: removing `style`, making `builder` the sole mechanism

**Motivation.** Once `builder` (see above) could always override
whatever a `style` string would otherwise select, `style` became
redundant with `builder` for three of the four layers -- it was purely
sugar for choosing a default `build_*()` function. For the data layer,
`style` did double duty: it also picked the *structural* family a
builder was slotted into (a single call merged into the main panel, vs.
one-or-more panels stacked below the base plot), which is not itself a
builder-selection concern. Having both `style` and `builder` arguments
doing overlapping jobs was inelegant, and for the data layer, nothing
stopped a user from pairing a builder with the wrong structural `style`
(e.g. `er_builder_data_overlay()` with `style = "jitter"`) even though that
combination was never sensible.

**What was done:**
- `style` was removed entirely from `er_plot_add_model()`,
  `er_plot_add_quantiles()`, `er_plot_add_data()`, and
  `er_plot_add_groups()`. Each now has a `builder` argument that
  defaults to one built-in `build_*()` function (`er_builder_model_ribbonline()`,
  `er_builder_quantile_errorbar()`, `er_builder_data_overlay()`,
  `er_builder_group_boxplot()`) and can be set to any other function matching
  the standard signature -- built-in or custom. `summary_builder`
  (`er_plot_add_model()` only) similarly defaults to
  `er_builder_summary_pvalue()`.
- For the data layer specifically, the structural distinction that
  `style` used to carry (`"overlay"` vs. `"jitter"`) is now declared
  *on the builder function itself*, via a new exported helper,
  `er_builder_layout(builder, layout = c("overlay", "panel"))`, which attaches
  an `"er_builder_layout"` attribute. `er_plot_add_data()` reads this tag off
  whatever `builder` it's given (`.builder_layout()`) to decide whether
  to route through `.part_overlay()` (single call merged into the main
  panel) or `.part_data()` (one-or-more panels stacked below the base
  plot), with no separate argument needed. All three built-in data
  builders (`er_builder_data_overlay()`: `"overlay"`; `build_data_jitter()`/
  `build_data_color()`: `"panel"`) carry this tag; a custom data-layer
  builder that omits it now errors immediately and informatively at
  `er_plot_add_data()` call time, rather than silently ending up in the
  wrong structural slot.
- This was chosen over the alternative of encoding layout in a
  builder's *return value* instead of on the function itself, because
  `.part_overlay()`/`.part_data()` build genuinely different `config`
  shapes (the latter computes `panels`/`panel_position`/`color_role`)
  *before* any builder runs -- so the layout has to be knowable without
  calling the builder. Tagging the function keeps the "a builder returns
  a plain list of ggplot2 layers" contract uniform across all four
  layers, rather than introducing an inconsistent richer return type for
  the data layer alone.
- `?er_partial`'s "Writing your own builder" section, each layer
  function's own Rd topic, `vignettes/articles/design.Rmd`'s "Extending
  erplots" section, and the then-combined `vignettes/articles/plot.Rmd`
  were all updated to describe `builder`-only dispatch (no more `style`
  strings) and, for the data layer, the `er_builder_layout()` tagging
  requirement.

**Status:** done. `devtools::check()` clean (0 errors/warnings/notes);
existing tests updated to use `builder =` instead of `style =`, plus new
tests for the missing-layout error path and for `er_builder_layout()`-tagged
custom builders.

## Completed: removing `build_data_jitter()`/`build_data_color()`, adding `er_builder_data_boxjitter()`

**Motivation.** With `er_builder_data_overlay()` as the default, a review of
the two older panel-based data builders found neither still earned its
keep. `build_data_jitter()` (binary response) jittered points around
`y = 0` in upper/lower panels -- visually almost identical to what
`er_builder_data_overlay()` already shows merged into the main panel (jittered
points at their true 0/1 y-position), just relocated to separate panels;
no use case was found where the panel version showed something the
overlay didn't. `build_data_color()` (continuous/count response) was
weaker still: its continuous color-gradient encoding of the response
value is a harder read than `er_builder_data_overlay()`'s direct y-position
encoding, and when stratified it *lost* the shared strata legend
entirely, falling back to one panel per stratum level -- more panels
*and* a harder-to-read encoding, with no scenario where it clearly won.

**What was done:**
- Both builders were deleted from `R/er-plot-partials-data.R`.
- `er_builder_data_boxjitter()` (binary-response only) was added in their
  place: reuses `build_data_jitter()`'s upper/lower panel filtering
  (`response == 1`/`response == 0`) verbatim, but overlays the jittered
  points on a `geom_boxplot()` of the exposure values, so the panel
  shows the exposure *distribution* conditional on response -- a
  genuinely different comparison from anything `er_builder_data_overlay()`
  shows, not a rehash of it. Follows the model layer's fill (box) /
  color (jitter) split for strata, so `.polish_labels()`/
  `.polish_legends()` needed no changes.
- Mapping `y` to the strata factor directly (rather than
  `position_dodge()`/`position_jitterdodge()`) was required to make
  stratified boxes/points land in visually distinct rows:
  `position_jitterdodge()` dodges along the *discrete* axis, which here
  is y (`orientation = "y"`), but exposure on x is continuous and (almost)
  never shares an exact value across rows, so ggplot has nothing to dodge
  against and only warns ("requires non-overlapping x intervals") without
  actually separating anything. Using the strata factor as `y` directly
  (the same trick `er_builder_group_boxplot()` uses via `y = lvl`) sidesteps
  this entirely -- ggplot places each stratum at its own discrete row for
  free.
- No continuous/count replacement was added: `er_builder_data_overlay()`
  already fully covers that case (raw points at their true y-position),
  so removing `build_data_color()` leaves no gap. `.part_data()`'s
  response-type dispatch (panels/`panel_position`/`color_role`) was left
  in place rather than gutted, since it's still usable by a custom
  `"panel"`-layout builder -- there's just no built-in one for
  continuous/count today.
- Docs (`?er_partial`, `?er_plot_add_data`, `?er_builder_layout`) and
  `vignettes/articles/{plot,design}.Rmd` (the then-combined `plot.Rmd`)
  were updated throughout to describe `er_builder_data_boxjitter()` in place
  of the two removed functions, including a rewritten comparison section
  (binary-only now, since there's no continuous panel builtin to compare
  against `er_builder_data_overlay()`). That section now lives in
  `plot-binary.Rmd` -- see "Completed: splitting the plotting vignette by
  response type" below.
- Tests referencing the removed builders were updated: binary-response
  cases now use `er_builder_data_boxjitter()`; continuous/count "panel"-layout
  regression coverage (which used to exercise `build_data_color()`) now
  uses small inline custom builders tagged `er_builder_layout(builder, "panel")`,
  since that's the only way to exercise those code paths without a
  shipped built-in.

**Status:** done. `devtools::check()` clean (0 errors/warnings/notes),
full test suite passing. Both updated vignettes were also rendered end
to end (bare `rmarkdown::render()` and a full `pkgdown::build_site()`)
to visually confirm the new prose and the binary/stratified comparison
figures look right and legends dedupe correctly.

## Completed: splitting the plotting vignette by response type

**Motivation.** The single combined `plot.Rmd` had no clear division of
responsibility from `design.Rmd`: response-type-agnostic content (model
component, group component) sat alongside response-type-specific content
(quantile CI method, data-layer builder choice) in one long article, and
the two vignettes overlapped in places rather than cleanly separating
"how do I plot this kind of response" from "how does the grammar work".

**What was done:** `plot.Rmd` was replaced by three parallel articles --
`plot-binary.Rmd`, `plot-continuous.Rmd`, `plot-count.Rmd` -- each
covering the same skeleton (fit model, define plot, stratify, model
component, quantile component, data component, group component, VPC
plot) with response-type-specific detail where it matters (Clopper-
Pearson vs. t-interval vs. exact Poisson interval; `er_builder_data_boxjitter()`
vs. `er_builder_data_overlay()`-only). To avoid tripling the maintenance
burden for the two layers that are genuinely response-type-agnostic
(model, group), `plot-binary.Rmd` carries the full worked treatment of
those two (including `er_builder_model_spaghetti()` and
`er_builder_group_violin()`), and the continuous/count articles show only
default usage with a link back to `plot-binary.Rmd`. A binary-response
VPC example was added to `plot-binary.Rmd` for parallelism, since the
continuous/count articles already had one. `design.Rmd` needed no
structural change -- it already only contained grammar/architecture
content, not usage tutorials -- just cross-reference fixes to point at
the three new articles instead of the old combined one. `_pkgdown.yml`'s
articles nav was reordered to binary/continuous/count/design.

**Status:** done.

## Completed: naming-scheme review

**Motivation.** A review of the package's function-naming conventions
flagged three inconsistencies: the pipeline verb `er_plot_show_*()`
described rendering ("show") when it actually only appends to a
declarative spec; the `build_*()` partial-builder prefix didn't signal
"pluggable strategy function" the way e.g. ggplot2's `geom_*`/`scale_*`
families do, and read as a generic, collision-prone name; and the
confidence-interval helpers (`clopper_pearson_interval()`, `t_interval()`,
`poisson_interval()`) used an inconsistent `*_interval` suffix instead of
a prefix, unlike every other family in the package.

**Decisions made:**
- `er_plot_show_*()` -> `er_plot_add_*()` (verb fix; `er_plot()`,
  `er_plot_style()`, `er_plot_build()` unaffected).
- `build_*()` -> `er_builder_*()` (shared, `er_`-namespaced prefix,
  chosen over a per-layer prefix like `er_model_*()`/`er_data_*()`
  because it keeps "these are all interchangeable builder-strategy
  functions" legible as one family in autocomplete/`library(help =)`,
  at the cost of slightly longer names). The builder-metadata helpers
  moved under the same prefix for consistency: `er_layout()` ->
  `er_builder_layout()`; the two attribute tags that used to be set via
  raw `attr()` calls (`er_data_fill`, `er_group_y`) gained proper setter
  functions, `er_builder_fill_role()`/`er_builder_y_role()`, mirroring
  `er_builder_layout()`'s wrapper-function pattern instead of requiring
  a custom builder author to poke `attr()` with a hand-typed string.
- `clopper_pearson_interval()`/`t_interval()`/`poisson_interval()` ->
  `ci_clopper_pearson()`/`ci_t()`/`ci_poisson()`. `ci_*()` was chosen
  over `confint_*()` specifically to avoid echoing `stats::confint()`'s
  name (a generic with a very different calling convention) despite
  `confint_*()` being more explicit on first read.

**What changed:** every occurrence renamed across `R/`, `tests/`,
`vignettes/articles/`, `README.Rmd`, `AGENTS.md`; `NAMESPACE`/`man/`
regenerated via `devtools::document()`. Internal (dot-prefixed) helpers
were deliberately left alone, including the `.build_*()` assembly
helpers in `R/er-plot-build.R` -- renaming the public prefix away from
`build_*` incidentally resolved the pre-existing ambiguity between those
and the public builders, with no rename needed on the internal side.
Historical mentions of already-removed functions (`build_data_jitter()`,
`build_data_color()`, `build_datastrip_jitter()`) were left under their
old names elsewhere in this document, since they were removed under the
old naming scheme and never existed under the new one. Straight rename,
no deprecation shims -- the package is GitHub-only/pre-CRAN.

**Status:** done, `devtools::check()` clean (0 errors/warnings/notes),
full test suite passing (452 tests).

## Completed: consolidating the builder-metadata setters into `er_builder_tag()`

**Motivation.** `er_builder_layout()`, `er_builder_fill_role()`, and
`er_builder_y_role()` each set one attribute on a builder function via
the same "wrapper function that attaches an attribute" pattern. A
builder that needed more than one tag (e.g. `er_builder_data_hex()`,
which needs both `layout` and `fill_role`) had to chain two calls. On
review, the three-separate-functions design (itself deliberately chosen
during the naming-scheme review just above, with a documented rationale
in `vignettes/articles/extending.Rmd`'s "Why three separate helpers, not
one generic tag function" section) was judged not to earn its keep:
each attribute is independent and optional (aside from `layout` being
mandatory for a data-layer builder), so there's no real benefit to
three names over one function with three optional arguments.

**Decisions made:**
- `er_builder_layout()`/`er_builder_fill_role()`/`er_builder_y_role()`
  collapsed into a single `er_builder_tag(builder, layout = NULL,
  fill_role = NULL, y_role = NULL)`. Each argument independently
  attaches its corresponding attribute (`"er_builder_layout"`,
  `"er_builder_fill_role"`, `"er_builder_y_role"` -- the attribute
  *names* are unchanged, only the setter functions were merged) when
  non-`NULL`; a builder needing multiple tags now does it in one call,
  e.g. `er_builder_tag(fn, layout = "overlay", fill_role = "density")`
  (what `er_builder_data_hex()` does).
- The internal `.builder_layout()`/`.builder_fill_role()`/
  `.builder_y_role()` accessors were left untouched -- they just read
  attributes off a builder and don't care how those attributes were
  set.
- No `layer` attribute (an idea raised alongside this one, to let a
  builder self-declare which `er_plot_add_*()` layer it's meant for, so
  the wrong-layer case could error informatively) was added in this
  pass -- deferred initially, then implemented in the follow-up section
  just below.

**What changed:** every call site across `R/`, `tests/`, and
`vignettes/articles/` updated (built-ins:
`er_builder_data_boxjitter()`/`er_builder_data_overlay()`/
`er_builder_data_hex()`/`er_builder_group_histogram()`); `NAMESPACE`/
`man/` regenerated via `devtools::document()` (`er_builder_layout.Rd`/
`er_builder_role.Rd` deleted, `er_builder_tag.Rd` added);
`extending.Rmd`'s builder-metadata section rewritten around the single
function, including replacing its old "why three separate helpers"
justification with the opposite conclusion. Straight rename, no
deprecation shims -- consistent with the naming-scheme review above.

**Status:** done, full test suite passing (452 tests).

## Completed: adding the optional `layer` attribute

**Motivation.** Deferred in the previous section: `layout` is checked
structurally (it's mandatory for a data-layer builder, and
`er_plot_add_data()` reads it to decide which internal assembly path to
use), but nothing previously caught a builder plugged into the wrong
*layer* entirely -- e.g. passing a quantile builder to
`er_plot_add_data()` would call it with the data layer's `config`
shape, failing with whatever error results from that mismatch (often an
unhelpful "object not found" from inside the builder) rather than a
clear message naming the actual problem.

**Decisions made:**
- `er_builder_tag()` gained a fourth argument, `layer`, one of
  `"model"`, `"summary"`, `"quantile"`, `"data"`, or `"group"` (`
  "summary"` covers `er_plot_add_model()`'s `summary_builder` argument
  specifically, as a slot distinct from that layer's own `builder`).
  Attaches an `"er_builder_layer"` attribute, following the same
  optional/independent pattern as `fill_role`/`y_role`.
- Every `er_plot_add_*()` function now resolves its builder(s) to their
  default *before* validating (`builder <- builder %||% <default>`,
  same as before), then calls a new internal `.check_builder_layer(builder,
  expected_layer, arg = "builder")` helper. If the builder has no
  `"er_builder_layer"` attribute, the check is a no-op -- `layer` is
  opt-in, unlike `layout`. If it has one and it disagrees with the
  layer being added, it errors immediately, naming both the declared
  and actual layer.
- All built-in builders across all five layers were tagged with their
  layer (`er_builder_model_ribbonline()`/`er_builder_model_line()`/
  `er_builder_model_spaghetti()`: `"model"`; `er_builder_summary_pvalue()`:
  `"summary"`; `er_builder_quantile_errorbar()`/`er_builder_quantile_bar()`/
  `er_builder_quantile_pointrange()`: `"quantile"`;
  `er_builder_data_overlay()`/`er_builder_data_boxjitter()`/
  `er_builder_data_hex()`: `"data"` (added alongside their existing
  `layout` tag); `er_builder_group_boxplot()`/`er_builder_group_violin()`/
  `er_builder_group_histogram()`: `"group"`), so the validation has
  real effect out of the box rather than only mattering for
  hand-written custom builders.
- `layer` was deliberately made optional rather than mandatory (unlike
  `layout`), to avoid forcing every existing custom builder (written
  before `layer` existed) to be updated just to keep working -- an
  untagged builder is simply never checked, in any layer.

**What changed:** `R/er-plot-api.R` (`er_builder_tag()`, `.builder_layer()`,
`.check_builder_layer()`, and the validation call added to each
`er_plot_add_*()`); every built-in builder file
(`R/er-plot-partials-model.R`, `-quantile.R`, `-summary.R`, `-data.R`,
`-group.R`) tagged its builders with `layer`; new tests in
`tests/testthat/test-er-plot-api.R` covering the tag itself, each
built-in builder's tag, the wrong-layer error for each of the four
`er_plot_add_*()` functions (and `er_plot_add_model()`'s
`builder`/`summary_builder` pair specifically), and the "untagged
builder is never checked" case; `?er_builder_tag`, `?er_partial`, and
each builder-family's own help topic (`?er_builder_model`,
`?er_builder_quantile`, `?er_builder_summary`, `?er_builder_data`,
`?er_builder_group`) documented; `vignettes/articles/extending.Rmd`
gained a `layer` section (with a runnable wrong-layer error example)
and its summary table gained a fourth row; `NAMESPACE`/`man/`
regenerated via `devtools::document()`.

**Status:** done, `devtools::check()` clean (0 errors/warnings/notes),
full test suite passing (478 tests).

## Other completed fixes

- **Stratified quantile labels visually overlapping.** Two strata's
  labels for the same exposure bin could land on top of each other in
  `er_builder_quantile_errorbar()` (noticed on a `sex`-stratified continuous
  quantile plot, but not specific to continuous responses). Fixed via
  `.dodge_quantile_strata()`, a small symmetric-around-`x_mid` per-
  stratum horizontal offset sized as a fixed fraction of the exposure
  range; points/error bars/labels now plot at the dodged position
  instead of a shared `x_mid`, with the label's color matched to its
  stratum.

## Open / deferred (no concrete need yet -- not scheduled)

- **Additive model layer.** Overlaying two fitted model curves (e.g. a
  candidate vs. a null/reference model, or Emax vs. linear) isn't
  possible today since `er_plot_add_model()` is singleton. Real work,
  comparable to the data layer's stratified-legend handling -- deferred
  until a concrete request exists.
- **Data layer color scale / continuous-response panel design.**
  `build_data_color()` (and its "should this use a deliberately chosen
  continuous scale like viridis" open question, and the quantile-binned
  rug fallback noted under "Design chosen" above) was removed -- see
  "Completed: removing `build_data_jitter()`/`build_data_color()`,
  adding `er_builder_data_boxjitter()`" above. If a concrete need for a
  continuous/count "panel"-layout builder resurfaces, these are the
  design questions to revisit; `.part_data()`'s response-type dispatch
  for that case is still in place, just with no built-in consumer today.
