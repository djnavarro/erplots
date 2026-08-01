# erplots design history

This file is a condensed historical record of completed design
decisions: what was tried, what was rejected, and why. It exists for
context in future sessions, not as a changelog or PR log -- step-by-step
implementation narrative (file-by-file diffs, exact test-pass counts,
staged PR sequencing) has generally been trimmed in favor of the
decisions themselves; see git history for that level of detail if it's
ever needed. Entries are in roughly chronological order. Current-state
facts that came out of this history (what the API looks like today) live
in `AGENTS.md`, not here.

## Response-type generalisation (binary -> continuous/count)

erplots started binary-response-only. It generalised to `response_type
= c("auto", "binary", "continuous", "count")`, auto-detected when not
given. The model curve/ribbon layer and group panel layer needed no
dispatch to generalise. The quantile summary layer and the VPC grammar
needed real per-type work (rate + Clopper-Pearson for binary; mean +
t-interval for continuous; mean + exact Poisson interval for count). The
data layer went through two rounds of exploration (`build_data_jitter()`,
`build_data_color()`) before settling on `er_style_data_overlay()` as a
single, response-type-agnostic builder that works for any response type
via a small vertical jitter applied only for binary responses -- see
"Removing `build_data_jitter()`/`build_data_color()`" below.

## `er_plot_theme()`: from no-op placeholder to a working interface

`er_plot_theme()` used to be a two-line stub (`function(object, labels)
{ return(object) }`). It became a working interface for the styling
knobs a ggplot2 user would expect to control -- labels, plot-level
title/subtitle/caption, axis limits, the overall visual theme, the
discrete color/fill palette, formatters, the legend key glyph, and
relative panel heights -- without touching which variable is mapped to
which aesthetic (that stays the builder's job via `style`/
`er_style_tag()`).

All arguments are flat (not grouped into nested lists, matching every
other `er_plot_add_*()` function) and default to `NULL`, meaning "leave
unchanged," so the function can be called more than once and each call
only touches what it supplies -- mirroring `ggplot2::theme()`'s own
merging. There's no way to reset a field back to its `er_plot()` default
other than re-supplying that default's value explicitly.

**The `theme_base`/`theme_args` -> plain-object refactor.** Before this
work, `object$theme$theme_base`/`theme_args` were zero-argument
functions (`function() ggplot2::theme_bw()`) called at every use site,
even though nothing ever passed them arguments. Simplified to store
plain ggplot2 theme objects directly, which is both simpler internally
and lets `er_plot_theme()` accept a theme object the way a user would
normally write `+ theme_bw()`. `theme_args` was renamed to `theme_extra`
in the same pass.

**Applying the discrete palette (`.polish_scales()`).** Added to
`R/er-plot-compose.R`, called right after `.polish_labels()`. Reuses the
same role checks `.polish_labels()` already computes to decide whether
`colour`/`fill` on a given plot means strata (discrete, eligible) or
density/response-value (continuous, left alone). One known rough edge,
not solved: if a future custom builder adds its own `scale_color_*()`/
`scale_fill_*()` directly, `.polish_scales()` will add a second scale on
top rather than detecting/deferring to the builder's own choice (ggplot2
emits a message and the later one wins) -- no built-in builder does this
today, so it isn't a live bug.

**Continuous color/fill palette control** (`color_continuous`/
`fill_continuous`) closed a gap left by the first round: `er_style_data_hex()`'s
bin-density fill (and a hypothetical continuous/count response's
response-colored data layer) was stuck at ggplot2's default gradient.
These validate against `"ScaleContinuous"` specifically (tighter than
the discrete pair's generic `"Scale"` check), so passing a discrete
scale is rejected. Each of the four `er_plot_theme()` palette arguments
only touches the aesthetic role it names, so they can be supplied
together without clobbering (e.g. a stratified model ribbon's discrete
`fill = strata` alongside `er_style_data_hex()`'s continuous density
`fill` -- though those two specifically can't coexist on the *same*
plot regardless of theming, since ggplot2 itself rejects two scales for
one aesthetic).

## `er_style_data_hex()`'s default fill palette

Originally left at ggplot2's own default continuous fill gradient, whose
low end is already a moderate blue rather than something that reads as
"no data here" -- a real usability gap once `erplots_data` (4,000 rows)
made this builder's main use case (avoiding scatter overplot) concrete.
Now defaults to `ggplot2::scale_fill_gradient(low = "grey90", high =
"#132B43")` (`grey90` rather than pure white, so a very-low-density cell
still reads as a drawn hex rather than disappearing into the `theme_bw()`
background), applied only when the user hasn't already supplied
`er_plot_theme(fill_continuous = ...)`, avoiding ggplot2's
duplicate-scale warning that `.polish_scales()` layering a second scale
would otherwise cause.

## `er_style_tag()`'s `zorder` attribute

`er_style_data_hex()`'s geoms cover the whole panel, so the fixed
z-order every overlay-layout data builder used to share (added last,
after model/summary/quantile, so a scatter overlay's individual points
are never hidden) meant it completely buried the model curve and summary
annotation whenever all three shared the main panel.

Two fixes were considered: (1) a builder-declared z-order tag, so only a
full-coverage builder opts into drawing first, or (2) switching the
whole package to ggplot2-style semantics where pipeline *call order*
determines z-order. (2) was rejected as a much bigger architectural bet
for a currently-hypothetical benefit: it would require new object state
tracking call order among the main-panel layers, a policy decision for
what happens to that order when a singleton layer is replaced, and --
most importantly -- it would break the package's foundational "pipe
order never affects the result" property for exactly one dimension
(main-panel z-order) while leaving that property intact everywhere else.
(1) was implemented instead: no new object state, no change to any
existing builder's behaviour, and it follows the same self-declared-
metadata pattern `layout`/`fill_role`/`y_role` already established.

`zorder` only has an effect for an overlay-layout data builder; a
panel-layout builder's geoms are never in the same ggplot object as
model/summary/quantile, so the tag is inert there. `er_style_data_hex()`
is tagged `zorder = "background"` and also gained a modest default
`alpha = 0.85` for extra contrast against the now-visible model
curve/summary annotation.

A follow-up review considered whether `?er_style` (the shared
builder-interface doc page) should gain a full `zorder` walkthrough.
That page already discusses `layout`/`layer` in depth but leaves
`fill_role`/`y_role` to the family-specific pages, on the reasoning that
`layout`/`layer` are broad/cross-cutting while `fill_role`/`y_role` are
narrow, single-family concerns. `zorder` was judged closer in scope to
`fill_role`, so it got a single pointer sentence in `?er_style`'s
existing `layout` paragraph rather than a full walkthrough there,
matching that precedent; the full walkthrough lives in
`extending.Rmd`/`er_style_data()`'s own docs instead.

## Fixed: an `er_plot` with no layers at all errored

`er_plot_build()`'s trigger condition for building the base panel only
checked for model/summary/quantile/overlay, mirroring the documented
"a group-only or panel-layout-data-only plot has no base panel"
exception. But when *no* layer at all had been added (e.g. `data |>
er_plot(x, y) |> plot()`, the minimal "empty canvas" example now used at
the top of `vignettes/erplots.Rmd`), `patchwork::wrap_plots(list(), ...)`
failed with an opaque `grid::unit()` error instead of rendering the
blank axes-only panel a user would reasonably expect. Fixed by widening
the trigger: build the base panel when at least one of the four layers
is present (unchanged), *or* when there are no layers at all.

## Quantile boundary-vline value labels, with collision avoidance

`er_style_quantile_errorbar_vlines()`/`er_style_quantile_pointrange_vlines()`
drew interior quantile-bin boundary lines but never labelled them with
the actual exposure cutpoint. Five new arguments were added, defaulting
off (`vline_labels = FALSE`, byte-for-byte unchanged rendering by
default): `vline_label_position`, `vline_label_size`,
`vline_label_colour`, `vline_label_fill`, `vline_label_inset`. Added as
new arguments on the existing `_vlines` builders rather than a further
tier of wrapper builders, since the `_vlines` functions are already thin
wrappers over the base point/errorbar builders and a wrapper-of-a-wrapper
felt like unneeded indirection for a rendering detail (unlike the group
layer's boxjitter/violinjitter, a materially different visual idiom
warranting a dedicated builder).

Labels use `geom_label()` (opaque background), distinct from the plain
`geom_text()` the point/errorbar value labels use, since a vline label
sits on top of a full-height line and needs the background to stay
legible.

**Collision avoidance.** `er_plot_add_summary()`'s annotations place
themselves in whichever of the 4 panel corners is least crowded by raw
data points (a Euclidean distance-to-corner calculation). Rather than
coupling the vline-label layer directly to the summary layer, the same
corner-distance calculation was extracted into a shared helper,
`.compute_corner_distance()` (`R/utils-helpers.R`), which
`.layer_quantile()` now also calls, storing the result as
`config$corner_distance`. `.quantile_label_side()` finds the single
least-crowded corner and returns the *opposite* vertical half. Since
both layers compute the same deterministic, data-driven quantity
independently, this correctly avoids the summary's corner whether or not
a summary layer is present -- no cross-layer coupling needed.

**Follow-up fix: label centering and default rounding.** Two bugs: (1)
`vjust`/`hjust` roles were backwards for `angle = 90` text -- fixed by
setting `vjust = 0.5` unconditionally (centers along the vline) and
moving top/bottom logic to `hjust` (see "Gotchas" in AGENTS.md). (2) No
way to control label decimal places independent of `theme$format_number`
-- added `vline_label_digits` (default `0`).

**Follow-up: every boundary gets a line/label, including the two outer
edges.** The builders used to drop the overall min/max from
`config$breaks` on the reasoning that those "sit at the plot's own
edges." In practice the panel extends past both (padding, plus a
placebo arm sitting at `x = 0`), so those two boundaries were genuinely
invisible. Fixed by drawing/labelling every element of `config$breaks`.

**Follow-up fix: the two outermost labels no longer risk clipping off
the panel edge.** Once every boundary got a label, the leftmost/rightmost
labels (centered via `vjust = 0.5`) could have roughly half their width
fall outside `object$exposure$limits` when there's no placebo arm
(`coord_cartesian(clip = "off")` doesn't clip this, but a real output
device is still finite -- confirmed via an actual stress-test render).
Fixed by justifying only the first/last label to hang *inward*: `vjust`
is a per-row vector rather than one scalar, with the first/last elements
set so those labels hang toward the panel's interior. Getting the
direction right required an empirical check (a small script pinning a
single rotated label between two colour-coded reference vlines): for
`angle = 90` text, `vjust = 0` moves the label *left*, `vjust = 1` moves
it *right* -- the opposite of what "hang the leftmost label rightward"
naively suggests if you reason from the unrotated meaning of `vjust`.

## `er_style_group_boxjitter()`/`er_style_group_violinjitter()`

Added to give the group layer's box/violin builders a jitter overlay of
raw exposure values, the way `er_style_data_boxjitter()` already does
for the data layer -- a thin wrapper that calls the base builder, then
appends a `geom_point()` jitter layer. Chosen over adding jitter
arguments directly to `er_style_group_boxplot()`/`er_style_group_violin()`,
matching the "new dedicated builder" pattern already established by the
quantile layer's `_vlines` wrappers. `jitter_height` defaults to a fixed
`0.15` rather than resolving conditionally on stratification (unlike
`er_style_data_boxjitter()`) -- there's no equivalent reason (a binary
response's upper/lower panel split) for a group panel's jitter spread to
depend on stratification. Exposure position on x is never perturbed,
matching `er_style_data_boxjitter()`'s rule that jittering the actual
exposure value would misrepresent the data.

**Stratified dodging.** `ggplot2::position_jitterdodge()` doesn't support
an `orientation` argument, which is required here since the group layer
puts the group variable on y (see "Gotchas" in AGENTS.md). Worked around
with `.dodge_group_jitter()`, whose dodge width defaults to each wrapped
geom's own ggplot2 default (`0.75` boxplot, `0.9` violin) as a reasonable
approximation of `dodge2()`'s actual (slightly narrower, padded) spacing
-- confirmed visually to align closely enough that exact matching wasn't
pursued.

**Fixed: `er_style_group_boxjitter()` double-drew true outliers** (once
as a boxplot outlier point, once jittered) -- it had missed the same
outlier-suppression `er_style_data_boxjitter()` always applied. Fixed by
giving `er_style_group_boxplot()` its own `show_outliers` parameter
(default `TRUE`, so its standalone behaviour is unchanged), with
`er_style_group_boxjitter()` passing `show_outliers = FALSE`. There is
currently no way for a caller of `er_style_group_boxjitter()` to opt
back into outliers via `...`, since `show_outliers = FALSE` is a
hardcoded named argument in its internal call to
`er_style_group_boxplot()` -- not closed, since it wasn't part of the
reported bug and no one has asked for the override.

## Naming scheme reviews

A sequence of renames settled on today's naming families (see
`AGENTS.md`'s "Conventions" section for the current result):

- **Pipeline verbs**: `er_plot_show_*()` -> `er_plot_add_*()` ("add"
  signals "append to the spec" more accurately than "show," since
  nothing is drawn until build time).
- **Builders**: `build_*()` -> `er_builder_*()` -> `er_style_*()`. The
  final rename resolved a genuine naming collision: every builder's
  signature already had a *different* `style` parameter carrying
  theming state. Resolved in two phases: first the theming concept was
  renamed out of the way (`object$style` -> `object$theme`,
  `er_plot_style()` -> `er_plot_theme()`, each builder's own `style`
  parameter -> `theme`), *then* `style` was applied to builder selection
  (`builder`/`summary_builder` args -> `style`/`summary_style`, the
  whole `er_builder_*()` family -> `er_style_*()`, including source/test
  file renames). "Builder" was kept as ordinary English prose (e.g. "a
  custom builder") -- only actual API symbols were renamed.
- **CI helpers**: `*_interval()` suffix -> `ci_*()` prefix (chosen over
  `confint_*()` to avoid echoing `stats::confint()`'s different calling
  convention).
- **Builder metadata setters**: three separate functions
  (`er_layout()`/`er_data_fill`/`er_group_y`) were consolidated into one,
  `er_style_tag()`, since each attribute is independent and optional and
  a builder needing more than one (e.g. `er_style_data_hex()`) had to
  chain two calls under the old design. A `layer` attribute was added
  later (see below).
- **Object internals**: `object$part` -> `object$layer`; `.part_*()` ->
  `.layer_*()`; and stray "component" references in prose/headings
  consolidated onto "layer," since the concept had drifted across three
  overlapping vocabularies (layer/part/component).

All were straight renames with no deprecation shims -- the package is
GitHub-only/pre-CRAN, so there's no installed user base to break
silently.

## Adding the optional `layer` attribute to `er_style_tag()`

Every `er_plot_add_*()` function now checks a builder's `layer` tag, if
present, against the layer it was actually passed to, erroring
immediately (naming both the tagged and actual layer) if they disagree
-- e.g. passing a quantile builder to `er_plot_add_data()`. Unlike
`layout`, `layer` is entirely optional: an untagged builder (including
every custom builder written before `layer` existed) is simply never
checked. All built-in builders across all layers are tagged.

## Extensibility: removing the separate `style` string argument

There used to be a separate `style` string argument alongside `builder`
(back when the builder-selection argument was still called `builder`),
picking the *structural* family a data builder is slotted into. It was
redundant for the other three layers (pure sugar for choosing a default
builder function) and was removed; builder selection is the only
mechanism now. For the data layer specifically, the structural-family
distinction moved onto the builder function itself via `er_style_tag(fn,
layout = ...)`, since `.layer_overlay()`/`.layer_data()` build different
`config` shapes before any builder runs -- the layout has to be knowable
without calling the builder, which ruled out encoding it in a builder's
return value instead.

## Removing `build_data_jitter()`/`build_data_color()`

These were the original binary (`build_data_jitter()`) and
continuous/count (`build_data_color()`) data-layer builders, predating
`er_style_data_overlay()`. On review, neither earned its keep once
`er_style_data_overlay()` existed as a single response-type-agnostic
default, so both were removed with no shim. A custom `"panel"`-layout
builder for continuous/count remains possible via `er_style_tag()`,
since `.layer_data()`'s response-type dispatch was left in place.
Deferred, not scheduled: whether a future continuous/count
`"panel"`-layout builder should use a deliberately chosen continuous
color scale instead of ggplot2's default gradient, and whether it
should be a quantile-binned rug instead of a color-encoded scatter.

## Quantile layer builders: `er_builder_quantile_bar()` removed

Bar + error bar was reviewed and judged not to be an idiom that shows up
in real exposure-response reporting, unlike the `_vlines` pattern that
replaced it as the notable quantile-layer addition. Removed with no
shim.

## The summary layer promoted to independence

`summary` used to be a secondary argument of `er_plot_add_model()`
(`summary_style`), nested inside the model layer's own `config` and
computed alongside the curve/ribbon predictions. Promoted to its own
peer layer, `er_plot_add_summary()`, for two reasons: (1) a summary
annotation doesn't have to be a *model* summary at all (e.g. a plain
observation count), so requiring `er_plot_add_model()` first was an
artificial coupling; (2) it matches how every other layer is already its
own independent singleton with its own verb. `er_plot_add_model()`
dropped `summary_style` entirely (no shim) and now only draws the
curve/ribbon.

Two decisions made at the same time:

- **Corner placement no longer depends on the model curve.**
  `config$corner_distance` used to be computed from the model's fitted
  curve. Since a summary can now be added with no model at all, this
  switched to a single code path based on the raw observed data instead
  -- rescaled onto `[0, 1]`, same distance-per-corner-then-`min()` shape,
  just fed raw points instead of the curve. This changed existing plots'
  label placement, not just an implementation detail.
- **The "skip when stratified" decision moved into the builder.**
  `.layer_model()` used to refuse to compute a p-value at all when
  stratified. `.layer_summary()` now computes `config$p_value`
  unconditionally whenever a `model` is supplied, and
  `er_style_summary_pvalue()` itself checks `stratify` and returns
  `list()` if `TRUE` -- letting a different builder (e.g.
  `er_style_summary_n()`, most useful precisely when stratified) make
  its own call.

One visible side effect: every existing `er_plot_add_model(mod)` call
used to draw a p-value annotation by default; it no longer does --
showing one now requires an explicit `er_plot_add_summary(model = mod)`
call.

## The `er_summary()` `coefficients`/`glance` contract

`er_summary()`'s return value was originally undocumented beyond "a
named list of scalar summary statistics (e.g. `list(p_value = ...)`)" --
fine for erglm's GLMs (one unambiguous exposure coefficient) but not
generalisable to a model like emaxnls's Emax fits, which have several
named parameters with no single privileged term. Settled on the purely
additive contract now documented in `?er_model_interface` and
`AGENTS.md` (`p_value`/`coefficients`/`glance`, each independently
optional; unrecognized keys permitted and ignored). `coefficients`'
columns are snake_case rather than `broom::tidy()`'s dotted names, to
match the package's existing convention (`p_value`, `corner_distance`).

`er_style_summary_coefficients()` was added to consume `coefficients`
(one line per row, placed via the same corner-distance logic as the
other summary builders); `er_style_summary_gof()` was added later as the
first consumer of `glance` (a curated subset -- `N`/`AIC`/`BIC`/`R²` --
deliberately not the full set, to keep the annotation compact). Both
draw nothing if their required field is absent or the layer is
stratified, matching `er_style_summary_pvalue()`'s posture. This is
purely additive: erglm's existing `er_summary.erglm_model()` (returning
only `p_value`) needed no changes.

## `er_vpc_plot()` and the `sim_resp` extension to `er_simulate()`

`er_vpc_plot()` (the VPC function that predated the current VPC
mini-grammar -- see below) originally took a `sim` data frame that had
to be produced by a bespoke, model-package-specific helper (e.g.
`erglm::erglm_vpc_sim()`). Closed by widening `er_simulate()`'s contract
additively rather than adding a fourth generic: a method may return an
optional `sim_resp` column alongside `fit_resp`. A separate generic
(e.g. `er_simulate_response()`) was considered and rejected, since both
erglm and emaxnls already had `stats::simulate()` methods computing both
the mean/expected response and a full response draw in one call, so
extending `er_simulate()`'s return value was the smaller, more natural
change.

`er_vpc_plot()` gained a `model` argument (mutually exclusive with
`sim`) plus `nsim`/`seed`; when `model` is supplied it calls
`er_simulate()` internally and errors informatively if `sim_resp` is
missing, rather than silently treating `fit_resp` as a noisy draw (which
would produce a falsely narrow, misleading VPC band). The `sim`-based
path remained supported indefinitely. Both companion packages
(`erglm` PR #6, `emaxnls` PR #67) were updated to populate `sim_resp`.
Once `erglm::erglm_vpc_sim()` was actually removed upstream (superseded
by `er_vpc_plot(model = ...)`), erplots' own docs/vignettes/tests were
confirmed to have no remaining dependency on it.

## Documentation sweeps

Three review passes cleaned up documentation quality, none changing
behaviour:

1. **No internal implementation details outside `internals.Rmd`.** Swept
   `man/*.Rd`/`vignettes/articles/*.Rmd` for dot-prefixed internal
   function references, internal file paths, and direct object-slot
   access (`object$layer`, `object$part`), rewriting them to describe
   the same idea through public API instead (e.g. `extending.Rmd`'s
   "inspect `config$summary`" example became a tiny "spy" builder that
   `print()`s `config`, rather than accessing
   `plt$layer$quantile$config$summary` directly). `config`'s own
   documented shape per layer was explicitly kept -- it's the public
   extension contract, not an internal detail.
2. **Roxygen convention sweep**: `@description` kept to 1-2 sentences,
   `@param` kept to 1-2 sentences with overflow moved to `@details`.
   Found and fixed two genuine content bugs caused by a stray blank line
   silently splitting one intended paragraph across two roxygen blocks
   that only merged back together in the rendered `.Rd` (a duplicated
   sentence in the quantile layer's docs; a sentence fragment missing
   its subject in the summary layer's docs).
3. **Missing `@description` blocks + "previous behaviour" language.**
   Nine `.Rd` pages had `\title{}` and `\description{}` containing
   identical text (title-doubling-as-description via roxygen2's
   fallback) -- given real descriptions. Separately, swept for language
   describing current behaviour by reference to what came before it
   (e.g. "matching the previous fixed value") -- appropriate for this
   history file, not for user-facing docs -- and reworded to state the
   current behaviour directly.

## Internal toy `lm`/`glm` test wrapper

The test suite leaned on `erglm` for almost every fixture, not because
erglm itself was under test but because it was the easiest way to get a
fitted model object. Adding *user-facing* native `lm`/`glm` support to
erplots was considered and rejected (would blur the "erplots never fits
a model" principle and undercut erglm's own reason to exist); the fix
was scoped to test infrastructure only.

`tests/testthat/helper-toy-model.R` defines `er_test_toy_model()`, an
unexported, test-only S3 class covering exactly two cases (Gaussian/
identity, binomial/logit) via a plain `stats::glm()` call, with
`er_predict()`/`er_simulate()`/`er_summary()` methods that are direct
mirrors of erglm's own internals. A dedicated sync-check file,
`tests/testthat/test-toy-model-sync.R` (gated on erglm being installed),
fits the same formula/data through both implementations and asserts
their outputs agree -- so a future erglm algorithm change would surface
as a failure there, not silently. Deliberately narrow: no Poisson/Gamma/
non-canonical-link support, so the Poisson fixture stays erglm-backed.

`er_test_data` (the shared dataset fixture) is now a frozen, checked-in
snapshot (`tests/testthat/fixtures/er_test_data.rds`, ~10 KB, fully
synthetic) rather than `erglm::erglm_data` loaded live -- column
names/values are identical, so no downstream test reference needed to
change. Refreshing this snapshot (if erglm's own data is ever revised)
is a manual step. Across the suite, `skip_if_not_installed("erglm")`
usage dropped from 133 occurrences to 9 (the Poisson fixture's tests,
plus the 5 sync-check tests that specifically compare against a real
erglm fit).

## Fixed: jitter seed had no effect

`er_style_data_overlay()`/`er_style_data_boxjitter()` wrapped their
`geom_jitter()` call in `withr::with_seed()`, which looked plausible but
did nothing: `geom_jitter()` only builds a layer spec at construction
time (no RNG call); the actual jitter draw happens later, at render
time, inside `PositionJitter$compute_layer()`. By then `with_seed()`'s
temporary RNG state had long since been restored.

`ggplot2::position_jitter()` does take a working `seed` argument
(applied correctly, at render time) -- but `geom_jitter()` doesn't
forward `...` into it, and passing both a `position` object and
`width`/`height` errors. Fixed by dropping the `width`/`height`
shortcut entirely and building the `position_jitter()` object
explicitly: `position = ggplot2::position_jitter(width = 0, height =
jitter_height, seed = config$seed)`. This left `withr` with no remaining
use in `R/` (only in test helpers, where it wraps RNG calls
synchronously -- the pattern it actually works correctly for), so
`DESCRIPTION`'s `Imports: withr` moved to `Suggests: withr`.

Regression tests specifically check *both* that the same seed reproduces
identical jittered coordinates *and* that a different seed produces a
different draw -- checking only the first direction would pass
vacuously under the old, broken behaviour too, since ambient RNG state
can coincidentally make two draws agree.

## Fixed: grouped/rowwise tibble input broke multiple layers

A robustness sweep found that a grouped or rowwise tibble (a realistic
accidental input, e.g. piping straight out of `group_by()` without
`ungroup()`) broke things a plain `data.frame` can never hit:

- `.layer_quantile()` and `er_vpc_plot()` both call
  `dplyr::summarise(..., .by = ...)`, which errors outright on a grouped
  tibble.
- A rowwise tibble doesn't error, but silently changes what's computed:
  `dplyr::mutate()` on a `rowwise_df` evaluates once per row, so
  `cut_exposure_quantile()` (meant to see the whole column at once) ran
  once per row on a length-1 vector, failing with an unrelated-looking
  error.
- `.compute_corner_distance()` had no grouping guard at all and doesn't
  error on grouped input -- it silently returned one row per stratum
  level instead of one row overall, producing a garbled, partly-character
  vector that surfaced several calls later as an opaque `object 'geoms'
  not found` error inside a summary builder, with no indication grouping
  was the cause.

Fixed by calling `dplyr::ungroup()` once, at the top of `er_plot()` and
`er_vpc_plot()`, on the incoming `data` (and, in the VPC case, `sim`)
argument -- chosen over patching every individual `.by = `-using call
site, since `ungroup()` is a no-op for already-ungrouped input and
closes all three symptoms from one place. No validation error was added
for grouped/rowwise input -- erplots silently ungroups rather than
flagging it as a user mistake, consistent with `ungroup()` being a
normal pipeline step rather than something worth warning about.

## The VPC mini-grammar: `er_vpc_plot()` replaced by `er_vpc()`/`er_vpc_add_observed()`/`er_vpc_add_simulated()`

`er_vpc_plot()` was a single monolithic function from back when erplots
only supported binary outcomes: no builder pluggability, binning
strategy/x-axis treatment/visual idiom all hardcoded together -- adequate
for a quartile-binned, dodged point + error-bar-of-the-mean plot, but
with no way to render a continuous-x, percentile-band VPC (the idiom
common in population-PK work, e.g. tidyvpc's own default) without
forking the function. Promoted to its own mini-grammar mirroring
`er_plot()`'s object/layer/builder architecture, deliberately scoped
narrower (no stratification, always a single panel) since VPCs are used
far less often in exposure-response work and didn't warrant replicating
that much machinery speculatively.

**A correctness fix, not just a refactor.** `er_vpc_plot()` used to bin
observed and simulated rows *independently*, re-deriving fresh quantile
breaks separately for each source. This happened to produce matching
bins in every existing use (since `newdata` was always the observed
`data` itself), but was correct by coincidence, not construction. The
new `.layer_vpc_simulated()` instead bins simulated rows against the
*observed* layer's own stored cutpoints, guaranteeing identical bin
boundaries regardless of how `newdata` might someday differ from `data`.

**The new visual idiom.** Two new builders,
`er_style_vpc_observed_quantile_line()`/`er_style_vpc_simulated_quantile_ribbon()`, keep
exposure on a continuous x-axis and show percentile lines/ribbons rather
than only a central-tendency point + interval -- deliberately scoped to
continuous/count responses only, since a binary response's distribution
is already fully described by its rate. Every builder maps a constant
string to `color`/`fill` (`"Observed"`/`"Simulated"`) so ggplot2 merges
the legend entries automatically without either layer knowing about the
other's data.

**Removed, no shim**: `er_vpc_plot()` itself. Every reference in `R/`,
`tests/`, and vignettes was updated to the new pipeline.

**Explicitly out of scope, deferred**: stratified/faceted VPC panels
(the `er_plot()` `group`-layer analogue); a dedicated `er_vpc_theme()`
(ordinary `+ theme()`/`+ labs()` on the returned object remains the
escape hatch); a "binless"/LOESS-smoothed alternative to quantile
binning; prediction-correction (pcVPC); a dedicated
`vignettes/articles/vpc.Rmd` (the worked example lives only in
`model-interface.Rmd`'s `er_simulate()` section).

## File reorganisation: splitting up `er-plot-api.R`

`R/er-plot-api.R` had grown to 1255 lines mixing four distinct concerns:
the `er_plot` object's lifecycle, theming, builder-tagging machinery,
and the five pipeline verbs. Split into `er-plot-api.R` (lifecycle only),
`er-plot-theme.R`, `er-plot-add.R` (all five verbs together, since they
share a common validation pattern), and moved `er_style_tag()` into the
already-existing `er-plot-style.R` (which had been pure documentation
until then).

That last move surfaced a genuine load-order bug: `er_style_tag()` is
called at *package load time* by every built-in builder (e.g.
`er_style_data_overlay <- er_style_tag(function(...) ...)`), and R
sources `R/*.R` alphabetically by default -- `"er-plot-style-data.R"`
sorts before `"er-plot-style.R"` (`-` sorts before `.`), so every other
style file's load broke once `er_style_tag()` moved there. This had
worked by accident before the split, only because `er-plot-api.R`
happened to sort alphabetically before the style files. Fixed by adding
`#' @include er-plot-style.R` to each style file that needs it, letting
`devtools::document()` write the correct order into `DESCRIPTION`'s
`Collate` field rather than relying on filename luck.

## r-universe: `Suggests: emaxnls (>= 0.1.1.9000)`

erplots' r-universe build broke once `emaxnls` was published to CRAN as
plain `emaxnls` 0.1.1 -- a release predating erplots integration
entirely (no `emax_logistic()`, no `S3method()` registration for
`er_predict`/`er_simulate`/`er_summary`, confirmed by inspecting its
installed `NAMESPACE`). With an unconstrained `Suggests: emaxnls`,
r-universe's resolver treated the CRAN release as satisfying the
dependency and didn't fall through to `Remotes: djnavarro/emaxnls`
(`Remotes:` is generally only forced when CRAN can't satisfy a
dependency at all). Every `@examples` block using `emax_nls()`/
`emax_logistic()` failed on real r-universe build targets as a result --
reproduced locally by installing `emaxnls` from CRAN alone versus from
`djnavarro.r-universe.dev`. Fixed by pinning a version floor that only
the GitHub dev build satisfies, removing the ambiguity. No equivalent
fix was needed for erglm, which has no CRAN release to be confused with.

## Naming scheme: file/test renames accompanying the `style` rename

Alongside the `builder`/`er_builder_*()` -> `style`/`er_style_*()`
rename, source and test files were renamed to match:
`R/er-plot-builder*.R` -> `R/er-plot-style*.R`,
`tests/testthat/test-er-plot-builder-*.R` ->
`tests/testthat/test-er-plot-style-*.R`; `R/er-plot-part.R` ->
`R/er-plot-layer.R` (and its test file similarly) as part of the
`part`/`component` -> `layer` consolidation described above.

## Vignette structure: `extending.Rmd` and `theming.Rmd` split out of `design.Rmd`

`extending.Rmd` used to be a section inside `design.Rmd`, split into its
own article because it needed to grow: the original illustrative example
didn't explain what `config` (a builder's second argument) actually
*was*, so `extending.Rmd` now leads with a table of what each
`.layer_*()` function's `config` contains, inspects it interactively,
then writes a worked custom builder, then walks through all five
`er_style_tag()` arguments with a runnable example of each (including
`er_style_data_hex()`/`er_style_group_histogram()` as worked
illustrations of `fill_role`/`y_role`, and a runnable wrong-layer error
as an illustration of `layer`). `design.Rmd`'s own "Extending erplots"
section is now just a short pointer.

`theming.Rmd` was added as a *standalone* article (not a section within
`design.Rmd` or within each response-type worked example), on the
reasoning that theming is orthogonal to the mini-language grammar and
response-type-/layer-agnostic (unlike everything else in the three
worked-example articles) -- adding it to all three would have meant
near-verbatim triplication. Deliberately titled "Theming," not
"Styling," to avoid resurrecting the `style`/`theme` naming collision
described above.

## Bundled example dataset: `erplots_data`

Added so the package's own examples/vignettes don't have to depend on a
`Suggests`-only companion package, and so there's a dataset purpose-built
to exercise every response type and modelling scenario at once (unlike
`erglm::erglm_data`/`emaxnls::emax_df`, each with one exposure column).
Design goals: three continuous exposure columns, response columns
spanning all three response types, one exposure/response pair suited to
each of Emax-continuous, Emax-binary, logistic regression, linear
regression, and Poisson regression, a placebo arm plus multiple dose
levels, a few plausible covariates, and enough rows (4,000) that
raw-point overplotting is genuinely visible (motivating
`er_style_data_hex()`). All five modelling scenarios were validated by
actually fitting each against `erglm`/`emaxnls` and confirming the
simulated parameters were recovered close to the simulated truth, not
just eyeballed as plausible-looking.

A follow-up added `study_id`, generated independently of dose/exposure/
response purely so it's convenient to filter on -- subsetting to one
study shrinks N substantially (as low as 400 rows) while still spanning
the full dose range, useful for illustrating the same plot at smaller
sample sizes. Unevenly sized (400/800/1200/1600 across 4 studies) so
there's a genuinely small one to filter down to, rather than four equal
quarters.

## Builder-level style customisation arguments (all layers)

A review of every exported `er_style_*()` builder found a long list of
hardcoded, purely visual constants (jitter width/height, alpha,
linewidth, point/label size, dodge spacing, hex bin count, ribbon fill,
vline colour/linetype, etc.) with no way for a caller to override them
short of writing a full custom builder. Exposed as explicit function
arguments, per three ground rules:

1. **Explicit named arguments with defaults, not a `...`-only escape
   hatch** -- discoverable via autocomplete/`?er_style_*`, not just
   reachable by knowing an undocumented name to pass through `...`.
   (`...` passthrough remains for genuine one-offs, e.g.
   `er_style_model_spaghetti()`'s `seed`.)
2. **Names mirror ggplot2's own vocabulary** wherever the semantics
   match (`alpha`, `linewidth`, `size`, `bins`, `width`, `height`,
   `linetype`). Where a value isn't a literal geom parameter (e.g. the
   quantile errorbar's width is a *fraction* of the exposure range), the
   argument name says so explicitly (`errorbar_width`) rather than
   implying identical units to the geom's own parameter.
3. **Cross-layer/stratification-wide settings move to
   `er_plot_theme()`**, not a per-builder argument. Only one candidate
   fit this: the quantile layer's stratum-dodge spacing, which became
   `er_plot_theme(dodge_width = 0.05)`.

Where a hardcoded value already depended on `stratify`/`response_type`
(e.g. `er_style_data_overlay()`'s jitter height,
`er_style_model_spaghetti()`'s alpha), the new argument defaults to
`NULL`, preserving that conditional default; an explicit value overrides
it uniformly.

**Result, by layer** (all now implemented):

- **Model** (`R/er-plot-style-model.R`): `er_style_model_ribbonline()`
  gained `ribbon_fill = "grey40"` (unstratified only), `ribbon_alpha =
  0.25`, `linewidth = 1`, and a new feature, `ribbon_edges = FALSE`
  (draws `geom_path()` at the ribbon's own CI bounds when `TRUE`).
  `er_style_model_line()` gained `linewidth = 1`.
  `er_style_model_spaghetti()` gained `alpha = NULL` (default: `0.1`
  unstratified / `0.25` stratified), `linewidth = 1` (mean line), `nsim
  = 100L`; its fallback call to `er_style_model_ribbonline()` (when
  `er_simulate()` isn't implemented) forwards `linewidth` alongside
  `...`. `ribbon_edges = TRUE` was implemented so the returned geom list
  stays length 2 by default, only growing to length 4 when requested
  (existing tests asserted on the return length directly, so
  unconditional `NULL` padding would have been a visible regression).
- **Summary** (`R/er-plot-style-summary.R`): all four builders gained
  `inset` (label distance from panel edge, replacing the hardcoded
  `.05`/`.95` pair), `label_size`/`label_colour`/`label_fill`;
  `er_style_summary_gof()` additionally gained `fields = c("n", "aic",
  "bic", "r_squared")` (which curated `glance` fields to show, and in
  what order).
- **Quantile** (`R/er-plot-style-quantile.R`):
  `er_style_quantile_errorbar()` gained `point_size = 2`,
  `errorbar_width = 0.025`, `label_size = 3`;
  `er_style_quantile_pointrange()` gained `label_size = 3` plus optional
  `pointrange_size`/`pointrange_linewidth`. Both `_vlines` variants
  redeclare the shared args (forwarded to the base builder) plus their
  own `vline_colour = "grey50"`, `vline_linetype = "dotted"`.
- **Data** (`R/er-plot-style-data.R`): `er_style_data_overlay()` gained
  `jitter_height = NULL` (default: `0.05` binary / `0` otherwise),
  `alpha = 0.4`, `size = 1`. `er_style_data_boxjitter()` gained
  `box_width = 0.6`, `box_alpha = 0.4`, `show_outliers = FALSE` (maps to
  `outlier.shape`, `19`/`NA`), `jitter_height = NULL` (default: `0.3`
  stratified / `0.15` unstratified), `jitter_size = 1`, `jitter_alpha =
  0.6`. `er_style_data_hex()` gained `bins = 30`.
- **Group** (`R/er-plot-style-group.R`): `er_style_group_boxplot()`/
  `er_style_group_violin()` gained `alpha = 0.5`.
  `er_style_group_histogram()` gained `bins = 30`, `alpha = NULL`
  (default: `0.5` stratified / `0.8` unstratified).

**Not carried forward from the original brainstorm**: per-corner
`hjust`/`vjust`/exact label x-y (only `inset` is exposed; the corner
itself is chosen automatically from the data, not user-set);
`show.legend`/`key_glyph`/other structural-plumbing arguments (these
aren't visual style choices a user tunes per plot).

**Noted but not resolved as part of this round**: `er_style_group_violin()`'s
existing `quantile.linetype` argument is currently inert, since
`draw_quantiles` (the argument that actually enables drawn quantile
lines in `geom_violin()`) is never set. Whether to wire it up (add a
`quantiles = NULL` argument mapped to `draw_quantiles`) or drop
`quantile.linetype` entirely was left as an open call -- **status as of
this writing: still unresolved**, worth a decision next time that
builder is touched.

## VPC categorical/continuous layout mismatch

`er_style_vpc_observed_pointrange()` (discrete `.vpc_bin` locations) and
`er_style_vpc_simulated_quantile_ribbon()` (numeric `x_mid` locations) could be
freely mixed via `style`, but doing so silently plotted the two layers
at inconsistent x-positions for the same bin -- the pointrange stayed at
evenly-spaced categorical slots while the ribbon used the bin's actual
exposure midpoint.

Considered: (A) a new `x = c("bin", "midpoint")` argument on the
pointrange/errorbar builders, opt-in on both sides; (B) auto-reconciling
mismatched layouts at build time by silently switching the categorical
builder to plot at `x_mid`; (C) tagging builders with a `layout`
(reusing the data-layer builder's tag machinery, with a new
`"categorical"`/`"continuous"` value pair) and failing fast on a
mismatch; (D) a dedicated pointrange/errorbar builder pair that plots at
`x_mid` for explicit pairing with the continuous-x idiom. Went with C+D
together: B was rejected as too implicit (the same builder rendering
differently depending on what's paired with it undermines "which layer
was added never affects how another layer renders"); A alone leaves the
original bug fully reproducible if the user forgets to set `x` on both
sides.

`layout`'s allowed values were widened from `c("overlay", "panel")` to
also accept `"categorical"`/`"continuous"`, since it's the same concept
(which structural family a builder belongs to) applied to a different
layer pair. Unlike the data-layer case, VPC `layout` is optional
(`.style_vpc_layout()` returns `NULL` silently rather than erroring),
matching how the `layer` tag is already opt-in -- an untagged custom VPC
builder keeps working unchecked. `er_vpc_add_simulated()` calls
`.check_vpc_layout_match()` right after the existing `layer`-tag check.

The two new builders (`er_style_vpc_observed_pointrange_continuous()`,
`er_style_vpc_simulated_errorbar_continuous()`) only need
`config$summary`'s existing `x_mid` column (already computed for a
numeric `group_by`, previously just unused by the categorical-bin
builders) -- no new layer-computation work was needed, and as a side
effect these two work for a binary response too (unlike the percentile-
based line/ribbon idiom, which needs `config$percentiles` and is
continuous/count-only).

## VPC observed/simulated `probs` consistency check

Following the `layout` mismatch fail-fast check (see "VPC
categorical/continuous layout mismatch" above), a second silent
correctness gap remained: `er_vpc_add_observed()` and
`er_vpc_add_simulated()` each take their own `probs` argument, and
nothing stopped them from disagreeing (e.g. `c(0.1, 0.5, 0.9)` on one
side, `c(0.05, 0.5, 0.95)` on the other) -- both sides would compute and
render percentile bands/pointranges just fine, but the two sets
wouldn't correspond to the same nominal percentile, defeating the point
of a visual predictive check.

Added `.check_vpc_probs_match()` (`R/er-plot-style.R`, alongside
`.check_vpc_layout_match()`), called from `er_vpc_add_simulated()` right
after the layout check. It only fires when both builders resolve to
`layout = "continuous"` (i.e. `config$percentiles` is actually rendered
by both sides) -- a `probs` mismatch is harmless and silently ignored
for `"categorical"`-layout builders (the default pointrange/errorbar),
which never look at `config$percentiles` at all, and for untagged
custom builders (same opt-in treatment as `layer`/`layout`). Comparison
is order-independent (`sort()` before `all.equal()`). This required
`.layer_vpc_observed()` to start storing its own `probs` on
`config$probs` so the simulated-side call has something to compare
against.

## VPC builder pruning: dropping the plain mean pointrange/errorbar idiom

After `er_vpc_add_observed()`/`er_vpc_add_simulated()` gained the
adaptive `er_style_vpc_observed_mean_errorbar()`/
`er_style_vpc_simulated_mean_errorbar()` default (which already covers
the plain mean/rate + CI idiom for every response type and both
`plot_by` types) and `er_style_vpc_observed_quantile_line()`/
`er_style_vpc_simulated_quantile_ribbon()` were renamed to make clear
they're a percentile-band idiom, four builders no longer fit the
resulting scheme: `er_style_vpc_observed_pointrange()` and
`er_style_vpc_simulated_errorbar()` (the categorical-bin mean idiom --
functionally superseded by the adaptive default's categorical branch)
and `er_style_vpc_observed_pointrange_continuous()`/
`er_style_vpc_simulated_errorbar_continuous()` (the continuous-x mean
idiom -- superseded by the adaptive default's numeric-median branch,
plus an optional dashed percentile overlay that didn't fit anywhere
else in the naming scheme). All four were removed outright (no
deprecation shim, per project convention for this pre-CRAN package).

This leaves three VPC visual idioms: the adaptive mean/errorbar default
(no `layout` tag), the continuous-x percentile-band idiom
(`er_style_vpc_observed_quantile_line()`/
`er_style_vpc_simulated_quantile_ribbon()`, `layout = "continuous"`),
and the categorical-bin quantile idiom
(`er_style_vpc_observed_quantile_errorbar()`/
`er_style_vpc_simulated_quantile_errorbar()`, `layout = "categorical"`).
Tests and docs that used the removed builders purely as a stand-in for
"any observed/simulated-tagged style" (e.g. wrong-layer-rejection tests)
were repointed at `er_style_vpc_observed_mean_errorbar()`/
`er_style_vpc_simulated_mean_errorbar()` instead.

## Dropping dodging from the categorical-bin quantile idiom (and the mean/errorbar default's categorical branch)

`er_style_vpc_observed_quantile_errorbar()`/
`er_style_vpc_simulated_quantile_errorbar()` used
`ggplot2::position_dodge2()` to separate each bin's requested
percentiles horizontally, applied independently to the `geom_errorbar()`
and `geom_point()` calls within each builder. This was buggy in
practice: `position_dodge2()` computes each geom's dodge offsets from
that geom's own layer data, and a bare `geom_point()` (no natural
width) doesn't dodge consistently with a `geom_errorbar()` in the same
position family, so the point and its own error bar end up offset by
different amounts. Because the observed and simulated builders are
also two entirely separate ggplot2 layers plotted at the same
`.vpc_bin` x locations, they dodge independently of each other too,
compounding the misalignment.

Getting dodging right here needs a shared dodge computation across all
four geoms (both builders' points and error bars), which is more
involved than a quick fix and out of scope for this PR. Dodging was
removed outright rather than patched: `er_style_vpc_observed_mean_errorbar()`/
`er_style_vpc_simulated_mean_errorbar()`'s categorical branch (which
separated the observed and simulated point/errorbar at the same
`.vpc_bin`) and `er_style_vpc_observed_quantile_errorbar()`/
`er_style_vpc_simulated_quantile_errorbar()` (which separated each
bin's requested percentiles) now all plot directly at `.vpc_bin` with
no `position_dodge2()` call and no `dodge_width` parameter. When more
than one percentile is requested, its points/error bars currently
overplot at the same x position within a bin -- distinguishable only by
their differing y-values, not by any horizontal offset. Revisiting
proper dodging (likely via an explicit shared offset computed once and
applied to all four geoms, similar in spirit to `er_plot()`'s own
`.dodge_quantile_strata()`) is deferred to a future PR.
