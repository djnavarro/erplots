# erplots 0.2.0

* `cut_quantile()`/`cut_exposure_quantile()` gain a `ties` argument
  controlling how a value that sits exactly on an interior quantile break
  is assigned (`"upward"`, the default and prior behaviour; `"downward"`;
  or `"split-even"`, which randomly balances tied values between the two
  candidate bins), plus an opt-in `seed` argument for reproducing
  `"split-even"`'s random tie-break. The resolved rule is recorded as a
  `"ties"` attribute on the returned factor.
* `cut_quantile()`/`cut_exposure_quantile()` gain a `quantile_type`
  argument, passed straight through to [stats::quantile()]'s own `type`
  argument for computing the quantile break points. Defaults to `7`
  (unchanged prior behaviour) and is recorded as a `"quantile_type"`
  attribute on the returned factor.
* `cut_quantile()`/`cut_exposure_quantile()` gain a `labeller` argument
  for customising quantile-bin labels: a function called as
  `labeller(n, breaks)`, or a character vector used directly. Defaults
  to `NULL` (unchanged `"Q1"`/`"Q2"`/... labelling);
  `cut_exposure_quantile()`'s separate `"Placebo"` level is untouched by
  `labeller`.
* `er_plot_add_quantiles()`/`er_plot_add_groups()` gain `ties`/
  `quantile_type`/`labeller` arguments, forwarded to
  `cut_exposure_quantile()`/`cut_quantile()`. These are local to each
  call -- they aren't required to agree across different
  `er_plot_add_groups()` calls, or with `er_plot_add_quantiles()` -- except
  in one case: `er_plot_build()` now warns if `er_plot_add_groups()` bins
  *the exposure variable itself* differently than `er_plot_add_quantiles()`
  does, since the two panels would then show inconsistent quantile bins
  for the same variable.

* `er_vpc()` gains `ties`/`quantile_type`/`labeller` for `plot_by`, plus
  a `seed` argument for reproducing a `"split-even"` tie-break. Unlike
  the `er_plot_add_quantiles()`/`er_plot_add_groups()` arguments above,
  these live on `er_vpc()` itself rather than on
  `er_vpc_add_observed()`/`er_vpc_add_simulated()`, since the observed
  and simulated layers must always bin `plot_by` identically --
  `er_vpc_add_simulated()`'s own `seed` argument now also seeds its
  independent `"split-even"` tie-break.

## Breaking changes

* `stratify_by` must now name a discrete/categorical variable in
  `er_vpc()` (and in the not-yet-released `er_tte()`); a numeric column
  errors instead of being automatically split into quantile bins. The
  `n_strata` argument is removed from both. Bin a continuous covariate
  yourself first with `cut_quantile()`/`cut_exposure_quantile()`, which
  also gives full control over bin count, tie-breaking, and labels --
  see `?er_vpc`/`?er_tte`.

## Bug fixes

* `er_plot()` now errors clearly when `stratify_by` names a numeric
  column, instead of silently mapping it to a continuous colour scale
  (which broke every stratified builder's discrete-groups assumption --
  ribbons, per-stratum lines, dodging -- with no warning). `stratify_by`
  has always been documented as requiring a discrete variable; this was
  simply never validated.
* `er_plot_add_groups()`'s `bins` argument now actually controls the
  number of quantile bins used for a continuous grouping variable.
  Previously documented but silently ignored -- every continuous grouping
  variable was always split into `cut_quantile()`/`cut_exposure_quantile()`'s
  own default of 4 bins, regardless of what `bins` was set to.

# erplots 0.1.2

Addresses CRAN reviewer feedback on the 0.1.1 submission. User-facing changes:

* `er_plot_add_data()`'s two jittered builders (`er_style_data_overlay()`,
  `er_style_data_boxjitter()`) no longer hard-code a specific RNG seed
  (previously a literal `1234L` in `R/er-plot-layer.R`, used so that
  repeated `plot()` calls on the same object always showed identical
  jitter). Seeding is now opt-in only: pass `seed = <value>` through
  `er_plot_add_data()`'s own `...` for reproducible jitter across
  rebuilds of the same object; with no `seed` (the default), jitter
  draws from the ambient RNG stream and differs from one build to the
  next, like any other jittered geom.
* `er_plot_add_groups()`'s jittered builders (`er_style_group_boxjitter()`,
  `er_style_group_violinjitter()`) gain the same opt-in `seed` support,
  for consistency -- their jitter previously had no seed control at all.
  `withr` moves from `Suggests` to `Imports` to support this.

# erplots 0.1.1

* No user-facing changes. Fixes a documentation issue flagged by CRAN's
  Debian pretest check.

# erplots 0.1.0

Initial CRAN submission.

## `er_plot()`: the plotting mini-language

* `er_plot()` builds a fluent, pipe-based specification for
  exposure-response plots, generalised across binary, continuous, and
  count responses (`response_type = c("auto", "binary", "continuous",
  "count")`, auto-detected when not supplied).
* Six pipeline verbs attach layers to the specification -- nothing is
  drawn until `er_plot_build()`/`print()`/`plot()` -- and pipe order
  never affects the built plot:
  * `er_plot_add_model()` -- a model curve/ribbon.
  * `er_plot_add_summary()` -- a corner-placed text/label annotation
    (a model-derived statistic, or a plain observation count).
  * `er_plot_add_quantiles()` -- a quantile-binned response-rate/mean
    summary with confidence interval.
  * `er_plot_add_data()` -- a raw-data layer, either an overlay drawn
    on the main panel or one or more panels stacked below it.
  * `er_plot_add_groups()` -- stacked panels showing the exposure
    distribution per group variable (the one additive, non-singleton
    layer).
* `stratify_by` splits colour/facet encoding across strata, following a
  documented colour/facet precedence rule (see `vignettes/articles/design.Rmd`).
* `er_plot_theme()` styles labels, titles, axis limits, discrete/
  continuous colour and fill palettes, formatters, the legend key glyph,
  and relative panel heights, without changing which variable drives
  which aesthetic.

## The model interface

* Any model implementing `er_predict()` can be visualised;
  additionally implementing `er_simulate()` and/or `er_summary()`
  enables uncertainty spaghetti plots/VPCs and model-derived summary
  annotations. See `?er_model_interface`.
* erplots never fits a model itself -- it is designed to work alongside
  companion packages that implement the interface, such as `erglm`
  (GLM-based exposure-response models) and `emaxnls` (Emax/sigmoidal
  dose-response models).

## The builder system

* Every layer-adding function accepts a `style` argument (a
  `er_style_*()` builder function) that can be swapped for another
  built-in or a fully custom builder, with a documented interface
  (`?er_style`) and self-declared metadata via `er_style_tag()`.
* Built-in builders cover multiple visual idioms per layer, e.g.
  ribbon/line/spaghetti model curves, p-value/n/coefficients/
  goodness-of-fit summaries, errorbar/pointrange quantile summaries
  (with boundary-labelled `_vlines` variants), overlay/hexbin/
  boxjitter data layers, and boxplot/violin/histogram/boxjitter/
  violinjitter group panels.

## `er_vpc()`: the visual predictive check mini-grammar

* `er_vpc()` |> `er_vpc_add_observed()` |> `er_vpc_add_simulated()`
  mirrors `er_plot()`'s object/layer/builder architecture for building
  visual predictive checks, with an optional `stratify_by` for
  faceted panels.
* Three visual idioms are available via `style`: an adaptive mean/
  errorbar default, a continuous-x percentile-band idiom, and an
  adaptive quantile-errorbar idiom.
* `er_vpc_theme()` styles labels, titles, axis limits, and formatters.

## Bundled example dataset

* `erplots_data` -- 4,000 simulated subjects spanning three exposure
  measures and five response columns (continuous, binary, and count),
  built to exercise every response type and modelling scenario used in
  the package's documentation and vignettes.
