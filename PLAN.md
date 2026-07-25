# erplots development plan

This document tracks scoped-out future development for erplots. It is
not a changelog, but completed work is kept here in condensed form as a
historical record of *why* things are the way they are -- design
decisions and rationale are worth keeping even after the implementation
is done; step-by-step implementation narrative (file-by-file diffs, test
counts, staged PR sequencing) is not, and has been trimmed. See git
history / PR descriptions for that level of detail if it's ever needed.

## Completed: `keep_strata = FALSE` / missing-covariate `newdata` crash

**Discovered while** converting the roxygen `@examples` blocks across
`R/er-plot-api.R`/`R/er-vpc.R` from `\dontrun{}` to
`if (requireNamespace("erglm", quietly = TRUE)) { ... }` (so examples
actually run on the pkgdown site whenever `erglm` is installed, instead
of never being executed at all). Running the examples for real surfaced
a latent bug that `\dontrun{}` had been silently hiding since at least
the continuous/count generalisation work above.

**The bug.** `.part_model()`'s `.get_model_predictions()` builds the
prediction `newdata` it hands to `er_predict()` from *only* the exposure
variable (a length-300 grid) plus, if `stratify = TRUE`, a cross-join
against the strata variable's levels -- it has no way to know what other
covariates a given fitted model's formula actually contains, since
erplots never fits models and is deliberately model-agnostic. This is
fine as long as the model's `er_predict()` method can cope with a
`newdata` that's missing a covariate from its formula (e.g. by filling
in a reference/mean level itself). `erglm`'s current
`er_predict.erglm_model()` does not: it calls `stats::predict(object,
newdata, ...)` directly with no fallback, so `predict.glm()` errors
(`object 'sex' not found` for a model fit with `sex` as a covariate)
the moment `newdata` doesn't include every covariate the formula
references.

**Where this bites concretely.** Any `er_plot_add_model(mod)` call where
`mod`'s formula includes a covariate that either (a) isn't the plot's
`stratify_by` variable at all, or (b) *is* `stratify_by`, but
`keep_strata` resolves to `FALSE` for that call (either explicitly, or
implicitly because `er_plot()` was built without `stratify_by` in the
first place). Two of the `@examples` blocks in `er_plot_add_data()`'s
docs hit exactly this (fixed for now by making sure every example
plotting `mod2` -- fit as `ae2 ~ aucss + sex` -- always stratifies by
`sex`), but the underlying gap is general: **any** user who fits a model
with covariates beyond the exposure variable and calls
`er_plot_add_model(mod, keep_strata = FALSE)`, or omits `stratify_by`
from `er_plot()` altogether, will currently hit this same crash for any
model implementation (not just erglm's) that doesn't defensively handle
an incomplete `newdata`.

**The fix chosen** sidesteps the responsibility question the original
three options (see git history for the fuller discussion this section
used to contain) posed as mutually exclusive: rather than deciding
whether erplots or the model's `er_predict()` method should fill in
missing covariates, `.get_model_predictions()` now fills them in itself
*without* inspecting the model's formula at all. It already had access
to `object$data` (the original fitting data, stored by [er_plot()]) --
so after building the exposure-grid (and, if stratified, strata-crossed)
`newdata` as before, a new `.fill_reference_covariates()` step adds
*every other column present in `object$data`* at a single reference
value (`.reference_value()`: first factor level -- preserving the
factor's levels, so contrasts still resolve -- first value
alphabetically for a character column, `FALSE` for logical, the mean for
numeric, first observed value as a fallback otherwise). A model's
`er_predict()` method that doesn't reference a given column simply
ignores the extra column (this is how `predict()` methods generally
behave), so the fill is harmless when it's not needed and fixes the
crash when it is -- for `keep_strata = FALSE`, no `stratify_by` at all,
or any other covariate combination, and for any model implementing the
standard interface (erglm, emaxnls, or a custom one), with no upstream
package changes required. This is a materially different design than
either original option 1 (no `stats::terms()`/`all.vars()` introspection
needed, and no `?er_model_interface` contract change forcing model
authors to defensively handle incomplete `newdata` themselves) or option
2 (the combination now actually works, rather than just failing more
legibly).

`?er_model_interface`'s `newdata` documentation and `er_plot_add_model()`'s
own `@param model` docs were both updated to describe this filling
behaviour (a model author doesn't need to do anything differently; it
only matters if their own `predict()` call would otherwise error on an
incomplete `newdata`), with a new runnable `@examples` entry
(`ae1 ~ aucss + sex` plotted unstratified).

**Status:** done. New regression test in `tests/testthat/test-er-plot-api.R`
("`er_plot_add_model()` fills in covariates missing from the prediction
grid") covers the no-`stratify_by`-at-all case, the `keep_strata = FALSE`
case, and asserts the actual reference values filled in for both a
factor and a numeric covariate. `devtools::test()` (622 passing) and
`devtools::check()` (0 errors/warnings/notes) both clean, including the
new example running for real.

## Completed: `er_plot_theme()` implemented (was a no-op placeholder)

**Motivation.** `er_plot_theme()` (then `er_plot_style()`) was a
two-line stub returning `object` unchanged, documented as "not yet
implemented" -- there was no supported way to set a plot title, override
axis limits, swap the base ggplot2 theme, or control the discrete
color/fill palette, without reaching into `object$theme`/`object$style`
directly.

**What was done:** a flat-argument, `NULL`-means-"leave unchanged"
signature covering labels (`xlab`/`ylab`/`strata_lab`), plot-level
`title`/`subtitle`/`caption` (new `object$theme` fields, applied via
`patchwork::plot_annotation()`), `xlim`/`ylim` (already read lazily at
build time, so no other code changes needed), `theme_base`/`theme_extra`
(renamed from `theme_args`; also changed from zero-arg functions to
plain ggplot2 theme objects, so a user can pass `theme_bw()` directly
the way they'd normally write `+ theme_bw()`), `color_discrete`/
`fill_discrete` (new fields, applied by a new `.polish_scales()` in
`R/er-plot-compose.R`, which reuses `.polish_labels()`'s existing
strata-vs-density/response role checks to decide which plots are
eligible), the existing `format_p`/`format_percent`/`format_number`/
`draw_key` fields, and `height_base`/`height_data`/`height_group`
(merged via `utils::modifyList()`). Each argument validated by a small
dedicated helper (`.check_theme_string()` etc., `R/er-plot-api.R`).
Calling `er_plot_theme()` more than once accumulates, matching
`ggplot2::theme()`'s own merging semantics.

**Deferred, not done:** continuous color/fill palette control
(`color_continuous`/`fill_continuous`, for `er_style_data_hex()`'s
density fill or a continuous/count response's response-colored data
layer) -- would need the symmetric branch of `.polish_scales()`'s
eligibility logic; per-layer/per-geom style knobs (alpha, linewidth) --
belong to individual `er_style_*()` builders' own arguments, not the
global theme; validating that a `color_discrete`/`fill_discrete`
scale's own aesthetic matches the argument it was passed as -- a
mismatch surfaces as ggplot2's own error at build time instead.
`.polish_scales()` also has one known rough edge, not solved: if a
future custom builder adds its own `scale_color_*()`/`scale_fill_*()`
directly, `.polish_scales()` adds a second scale on top rather than
detecting/deferring to it (ggplot2 emits a message and the later one
wins) -- no built-in builder does this today, so it isn't a live bug.

**Status:** done. New `tests/testthat/test-er-plot-theme.R` (partial-
update semantics, each argument's validation, an integration test, and
a regression check that `color_discrete`/`fill_discrete` don't affect
an `er_style_data_hex()` density fill); `devtools::test()` (618
passing) and `devtools::check()` (0/0/0) both clean.
`vignettes/articles/design.Rmd` was *not* updated to demonstrate
`er_plot_theme()` in this pass -- closed by the dedicated `theming.Rmd`
article added later, see "Completed: vignette restructuring" below.

## Completed: continuous color/fill palette control in `er_plot_theme()`

**Motivation.** `color_discrete`/`fill_discrete` only ever apply where
`colour`/`fill` is genuinely mapped to the stratification variable;
there was no equivalent for the other thing those aesthetics get used
for -- a continuous value -- leaving `er_style_data_hex()`'s bin-density
fill (the one built-in example) and a hypothetical continuous/count
response's response-colored data layer (no built-in consumer, but
`.layer_data()`'s `config$color_role == "response"` dispatch was left
in place for a custom builder -- see "Completed: removing
`build_data_jitter()`/`build_data_color()`" below) stuck at ggplot2's
default gradient with no way to override it.

**What was done:** `color_continuous`/`fill_continuous` added to
`er_plot_theme()`, validated against ggplot2's `"ScaleContinuous"` class
(tighter than `color_discrete`/`fill_discrete`'s generic `"Scale"`
check, since a continuous scale is a distinct S3 class, not just an
unlabelled variant) rather than reusing the generic `"Scale"` check --
so passing a *discrete* scale to `color_continuous` is now also
rejected, not silently accepted. `.polish_scales()` gained the mirror
image of its existing discrete-eligibility branches: `fill_continuous`
applies to the base plot's `fill` only when an overlay builder is
tagged `fill_role = "density"` (never when `fill` means strata);
`color_continuous`/`fill_continuous` apply to a data panel only when
`config$color_role == "response"` (never `"strata"`). Each of the four
arguments only ever touches the aesthetic role it names -- a builder
that maps both a discrete `fill = strata` ribbon and a continuous
density `fill` in the same plot was already a ggplot2-level error
before this (see `er_style_data_hex()`'s own docs), so this doesn't
introduce a new ambiguity, just gives the continuous side a lever to
pull.

**What changed:** `R/er-plot-api.R` (`er_plot()`'s default
`object$theme$color_continuous`/`fill_continuous` fields, `er_plot_theme()`'s
two new parameters/validation/assignment, docs); `R/er-plot-compose.R`
(`.polish_scales()`'s two new branches); new tests in
`tests/testthat/test-er-plot-theme.R` (validation, a regression check
that `fill_continuous` correctly overrides `er_style_data_hex()`'s
density fill without being clobbered by a simultaneously-supplied
`fill_discrete`, and a custom `"panel"`-layout builder exercising the
`color_role == "response"` branch, since no built-in one exists);
`vignettes/articles/theming.Rmd` gained a "Continuous color/fill
palette" section (using `er_style_data_hex()`) alongside the existing
discrete one.

**Status:** done, `devtools::check()` clean (0 errors/warnings/notes),
full test suite passing (634 tests), `theming.Rmd` re-rendered
end-to-end via `rmarkdown::render()`.

## Completed: an `er_plot` with no layers at all errored instead of drawing a blank canvas

**The bug.** `er_plot_build()`'s trigger condition for building the
base panel only checked for the model/summary/quantile/overlay layers
(mirroring the documented "a group-only or panel-layout-data-only plot
has no base panel" exception), so a plot with *no* layer added at all
(e.g. `data |> er_plot(x, y) |> plot()`) ended up with every one of
`object$plot$base`/`$data`/`$group` `NULL`, and
`patchwork::wrap_plots(list(), ...)` failed with an opaque
`'x' and 'units' must have length > 0` error rather than rendering the
axes-only panel a user would reasonably expect from a bare
`ggplot(df, aes(x, y))`.

**Fix:** widened the trigger condition with a `has_any_layer` check
spanning all six layers (including `data`/`group`), so the base panel
is now built either when one of the original four layers is present
*or* when there are no layers at all -- the existing group-only/
panel-layout-data-only no-base-layer behaviour is unchanged.

**Status:** done. Covered by a new test in
`tests/testthat/test-er-plot-api.R`, alongside the existing no-base-
layer tests it sits next to.

## Completed: the summary layer promoted to its own peer layer (`er_plot_add_summary()`)

**Motivation.** `summary` used to be a secondary, nested argument of
`er_plot_add_model()` (`summary_style`), which meant (1) a purely
descriptive annotation (e.g. an observation count) had to route through
the model layer even when no model was involved, and (2) summary was
the only one of the five constituents *not* an independent singleton/
additive layer with its own `er_plot_add_*()` verb.

**What was done:** a new `er_plot_add_summary(object, model = NULL,
keep_strata = NULL, style = NULL, ...)`, with `model` genuinely
optional (`NULL` means no model-derived statistic). `style` defaults to
`er_style_summary_pvalue()`; a new, model-agnostic
`er_style_summary_n()` (total or per-stratum observation count) reads
straight from `data` and ignores `model` entirely, demonstrating a
summary builder need not depend on a model at all.
`er_plot_add_model()` dropped `summary_style` entirely (straight
removal, no shim). Two follow-on decisions made at the same time:
- **Corner placement no longer depends on the model curve.**
  `config$corner_distance` is now computed from the raw observed
  `(exposure, response)` data (rescaled onto `[0, 1]`), not the fitted
  curve, since a summary can now exist with no model at all. A
  deliberate, visible change to existing label placement.
- **The "skip when stratified" decision moved into the builder.**
  `.layer_summary()` now computes `config$p_value` unconditionally
  whenever a model is supplied; `er_style_summary_pvalue()` itself
  checks `stratify` and returns `list()` if `TRUE`, so a different
  builder (e.g. `er_style_summary_n()`) can make its own call instead.

One visible behaviour change flagged at the time: every existing
`er_plot_add_model(mod)` call used to draw a p-value annotation by
default; it no longer does, without an explicit
`er_plot_add_summary(model = mod)` call.

**Status:** done. `er_plot_build()`'s base-plot trigger condition
gained `object$layer$summary`. The three worked-example vignettes were
not updated in this pass to add the now-required explicit call (a gap
closed by a later "Summary layer" section -- see "Completed: vignette
restructuring" below).

## Completed: the `er_summary()` return-value contract (`coefficients`/`glance`)

**Motivation.** `er_summary()`'s return value was documented only as
"a named list (e.g. `list(p_value = ...)`)" -- fine for erglm's GLM
models (one unambiguous exposure coefficient), not obviously
generalisable to a multi-parameter model like emaxnls's Emax fits
(`E0`/`Emax`/`EC50`/`Hill`, no single privileged term).

**What was done:** a purely additive contract in
`?er_model_interface` -- `er_summary()` returns `NULL` or a named list
with any of three independently-optional, reserved keys: `p_value`
(unchanged), `coefficients` (tibble, one row per parameter,
`term`/`label`/`estimate`/`std_error`/`statistic`/`p_value`/
`conf_low`/`conf_high`), and `glance` (single-row tibble,
`broom::glance()`-style goodness-of-fit; reserved for a second
contract revision, not consumed by any built-in yet -- until the next
section). `.layer_summary()` now stores the full raw return value as
`config$summary`. Two new builders demonstrate it:
`er_style_summary_coefficients()` (one line per `coefficients` row) and,
added slightly later as the first `glance` consumer,
`er_style_summary_gof()` (a compact `N`/`AIC`/`BIC`/`R²` annotation,
showing only whichever of those four fields are present/non-`NA`). Both
draw nothing if their input is absent or the layer is stratified, same
posture as `er_style_summary_pvalue()`.

Purely additive -- erglm's existing `er_summary.erglm_model()`
(`p_value` only) needed no change. Explicitly deferred, not erplots-side
work: enriching erglm's method with `coefficients`/`glance`, and an
actual `er_summary.emaxnls()` implementation.

**Status:** done. `plot-binary.Rmd` gained a "Summary layer" section
(worked examples of both `_pvalue()` and `_gof()`, the latter via a
`registerS3method()`-registered demo method since erglm doesn't
populate `glance` yet); `plot-continuous.Rmd`/`plot-count.Rmd` link
back to it. `design.Rmd`'s layer-overview table and ASCII pipeline
diagram, and two stale "the other three layers" doc strings, were
fixed in a follow-up staleness audit at the same time.

## Completed: `er_vpc_plot()`'s `sim_resp` extension to `er_simulate()`

**Motivation.** `er_vpc_plot()` was the one part of the mini-language
not built on the model interface -- it required a bespoke,
model-package-specific `sim` data frame (e.g. via
`erglm::erglm_vpc_sim()`), so every model package needed its own
VPC-shaped simulation helper outside `er_predict()`/`er_simulate()`/
`er_summary()`.

**What was done:** widened `er_simulate()`'s contract additively rather
than adding a fourth generic -- a method may now return an optional
`sim_resp` column alongside the existing `fit_resp` (a full
response-scale draw with observation-level noise, vs. `fit_resp`'s
point on the mean curve). A separate `er_simulate_response()` generic
was considered and rejected: both erglm and emaxnls already compute
both quantities in one `stats::simulate()`-family call, so extending
the return value was the smaller change. `er_vpc_plot()` gained a
`model` argument (mutually exclusive with `sim`) plus `nsim`/`seed`;
when `model` is supplied it calls `er_simulate()` internally and errors
informatively if `sim_resp` is missing, rather than silently treating
`fit_resp` as if it were a noisy draw. The `sim`-argument path is
unchanged and remains supported indefinitely.

Both companion packages were updated to implement the extension
(erglm PR #6, emaxnls PR #67, both merged), so `er_vpc_plot(model =
...)`'s example/tests pass against each package's default branch via
this repo's `Remotes:` entries. `erglm_vpc_sim()` itself is now slated
for removal from erglm; every erplots doc/vignette/example that used to
call it now goes through `er_vpc_plot(model = ...)` instead.

**Status:** done, except one dangling follow-up (see "Open/deferred"
below): `tests/testthat/test-er-vpc.R` still builds its `sim` data
frames via `erglm_vpc_sim()` directly, since that code path remains
supported regardless of the helper's removal -- but once erglm actually
drops the function, those specific tests will need another way to
build `sim` (e.g. directly via `er_simulate(model, newdata = ..., nsim
= ..., seed = ...)`).

## Completed: vignette restructuring (`theming.Rmd`, `extending.Rmd`, `model-interface.Rmd`)

**What was done, in three separate passes:**
- `extending.Rmd` ("Extending erplots: writing your own builder") was
  split out of `design.Rmd`'s "Extending erplots" section into its own
  article, because it needed to grow: it now leads with a table of what
  each `.layer_*()` function's `config` contains before writing a
  custom crossbar builder, and covers all four `er_style_tag()`
  arguments (`layout`/`fill_role`/`y_role`/`layer`) with a runnable
  example of each. `design.Rmd` keeps only a short pointer into it.
- `theming.Rmd` ("Theming erplots") was added as a *standalone* article
  documenting `er_plot_theme()` (one section per argument group, plus
  accumulate/partial-update semantics) -- not folded into `design.Rmd`
  or triplicated across the three worked-example articles, since
  theming is orthogonal to the mini-language grammar and
  response-type-/layer-agnostic. Cross-referenced from `design.Rmd`, the
  top-level `vignettes/erplots.Rmd`, and one sentence each in
  `plot-binary/continuous/count.Rmd`'s shared opening paragraph.
- `model-interface.Rmd` ("Implementing the model interface") was added
  for maintainers of *other* modelling packages (distinct audience from
  `extending.Rmd`'s erplots-*users*), building two self-contained toy
  model classes from scratch (`toy_model`: single-coefficient GLM
  wrapper, exercises `er_style_model_spaghetti()`/`er_vpc_plot(model =
  ...)`; `toy_emax`: three-parameter `nls()` Emax fit with a delta-method
  CI, exercises `coefficients`-based summary) to demonstrate every
  generic, deliberately terser/denser prose than the other five
  articles. Closes with a pointer to erglm's/emaxnls's real
  implementations as the non-simplified analogues.

`_pkgdown.yml`'s `articles` list was updated after each split
(`design` -> `theming` -> `extending` -> `model-interface`).

**Status:** done. All affected/added articles re-rendered end-to-end
via `rmarkdown::render()` with no errors after each pass;
`devtools::test()` unaffected (documentation-only changes).

## Completed: second naming-scheme review -- `builder`/`style` -> `style`/`theme`

**Motivation.** `builder` (and `summary_builder`) read as developer-facing
vocabulary -- "which function builds this layer" -- rather than the
plot-design vocabulary a user thinks in when choosing between, say,
`er_builder_data_overlay()` and `er_builder_data_boxjitter()`. `style`
was judged the better user-facing word for that choice.

**The collision this surfaced.** `style` wasn't free to reuse: every
builder's own signature already had a *different*, unrelated `style`
parameter, carrying theming state (`theme_base()`, `draw_key`,
`format_percent()`, etc.) sourced from `object$style` and set via
`er_plot_style()`. Reusing `style` for builder-selection without
addressing this would have meant three unrelated things sharing one
name. Resolved in two phases, judging the *existing* internal usage to
be the one that was arguably mis-named, rather than picking a different
word for the new builder-selection argument:
1. `object$style` -> `object$theme`, `er_plot_style()` ->
   `er_plot_theme()` (still a no-op placeholder), and every builder's
   own last parameter renamed `style` -> `theme`.
2. `builder`/`summary_builder` -> `style`/`summary_style` on all four
   `er_plot_add_*()` functions; the entire `er_builder_*()` function
   family (18 built-ins) -> `er_style_*()`; `er_builder_tag()` ->
   `er_style_tag()`; its attributes/internal readers followed suit
   (`"er_builder_layout"` -> `"er_style_layout"`, `.builder_layout()` ->
   `.style_layout()`, `.check_builder_layer()` -> `.check_style_layer()`,
   etc.).

**What changed:** every occurrence renamed across `R/` (including
renaming the builder source files themselves, `R/er-plot-builder*.R` ->
`R/er-plot-style*.R`), `tests/testthat/` (including
`test-er-plot-builder-*.R` -> `test-er-plot-style-*.R`), and
`vignettes/articles/`; `NAMESPACE`/`man/` regenerated via
`devtools::document()`. One deliberate scoping choice, consistent with
how the first naming-scheme review (below) treated the word "build":
"builder" was *not* purged as an English word -- prose that just
describes "a function you write to build geoms" (e.g. "a custom
builder", the `?er_style` topic's own "Writing your own builder"
section heading) was left alone, since it reads naturally and isn't an
identifier. Only actual API symbols were renamed. Straight rename, no
deprecation shims -- same rationale as every other rename in this
document (GitHub-only/pre-CRAN, no installed user base to break
silently).

**Read the rest of this document with that in mind.** Every section
below this one predates this rename and was written under the old
`builder`/`er_builder_*()`/`style`-as-theming vocabulary (the same
historical-accuracy convention already applied to old removed-function
names in "Completed: naming-scheme review" further down) -- read
`builder`/`summary_builder` there as what's now `style`/`summary_style`,
`er_builder_*()` as `er_style_*()`, and a bare theming `style` as
`theme`. See `AGENTS.md`'s "Naming scheme" section for the
user-facing, currently-accurate version of this vocabulary.

**Status:** done, `devtools::check()` clean (0 errors/warnings/notes),
full test suite passing (490 tests), and all five
`vignettes/articles/*.Rmd` files re-rendered end-to-end via
`rmarkdown::render()` with no errors and no leftover old-identifier
references in the output.

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
  added, covering the four layers then in existence (model/quantile/
  data/group), singleton/additive semantics with runnable examples, the
  stratification color/facet precedence rule, and the response-type
  dispatch table. It has since been refreshed twice more to stay
  current, per its own closing note: once to match the shipped
  data-layer redesign above (the layer table, the "Stratification
  composes with layers" section, and the response-type section had all
  fallen behind Stage 7b/7d and described a binary-only data layer that
  no longer existed; now describe `style = "overlay"`/`"jitter"` and
  `color_role` accurately), and again once the summary layer was
  promoted out of the model layer into its own, independent layer (see
  AGENTS.md's "The summary layer is independent of the model layer"
  section) with two further builders added consuming the expanded
  `er_summary()` contract (see AGENTS.md's "The `er_summary()`
  return-value contract" section) -- the layer table now lists five
  layers, not four, and the Summary row names all four of its builders
  (`er_style_summary_pvalue()`/`_coefficients()`/`_gof()`/`_n()`) rather
  than the original two (`_pvalue()`/`_n()`).
- `?er_plot`'s previously-shared `@rdname er_plot` page (covering
  `er_plot()`, `er_plot_style()`, and every layer function under one Rd
  topic with one shared `@param` list) turned out to already have been
  split into per-function topics by the time this was checked -- nothing
  further needed there.
- A follow-up audit for lingering staleness from the summary-layer
  promotion found two more spots: `design.Rmd`'s own ASCII pipeline
  diagram (a plain enumeration of `er_plot_add_*()` calls, not caught by
  searching for "N layers" phrasing) was still missing
  `er_plot_add_summary()` and got it added; and two roxygen doc strings
  (`er_plot_add_groups()`'s own details, and `?er_style`'s
  structural-family paragraph) still said "the other three layers"
  where it's now four -- both corrected to "four". `er_plot_add_model()`'s
  own `@examples`/`@seealso` and every other layer function's `@seealso`
  block were checked too and found already consistent (each correctly
  excludes itself and lists the other four).
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
- **`.polish_scales()` vs. a builder's own explicit scale.** If a future
  custom builder calls `scale_color_*()`/`scale_fill_*()` directly,
  `.polish_scales()` will add a second scale on top rather than
  detecting/deferring to it (ggplot2 emits a message and the later one
  wins). No built-in builder does this today, so not a live bug -- just
  a rough edge to keep in mind if one is added.
- **`test-er-vpc.R`'s reliance on `erglm_vpc_sim()`.** That test file
  still builds its `sim` argument test fixtures via
  `erglm::erglm_vpc_sim()` directly, which erglm has flagged for
  removal now that `er_vpc_plot(model = ...)` (via the `sim_resp`
  extension) supersedes it. Not urgent while the function still exists
  upstream, but once erglm actually drops it, those fixtures need
  rebuilding via `er_simulate(model, newdata = ..., nsim = ..., seed =
  ...)` instead -- see "Completed: `er_vpc_plot()`'s `sim_resp`
  extension" above.
