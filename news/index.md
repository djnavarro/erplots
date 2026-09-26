# Changelog

## erplots 0.2.0

### New features

- Added [`er_tte()`](https://erplots.djnavarro.net/reference/er_tte.md),
  a third mini-grammar (alongside
  [`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md)/[`er_vpc()`](https://erplots.djnavarro.net/reference/er_vpc.md))
  for Kaplan-Meier/survival-over-time figures, built around a time axis,
  a survival-probability axis, and an optional discrete `stratify_by`.
  Five singleton layers:
  [`er_tte_add_curve()`](https://erplots.djnavarro.net/reference/er_tte_add_curve.md)
  (the KM step curve + confidence band),
  [`er_tte_add_censor()`](https://erplots.djnavarro.net/reference/er_tte_add_censor.md)
  (censoring tick marks),
  [`er_tte_add_risktable()`](https://erplots.djnavarro.net/reference/er_tte_add_risktable.md)
  (a number-at-risk panel stacked below the curve),
  [`er_tte_add_summary()`](https://erplots.djnavarro.net/reference/er_tte_add_summary.md)
  (a corner-placed text/label annotation – a log-rank test by default,
  or subject/event counts or a fitted model’s
  coefficients/goodness-of-fit via `style`), and
  [`er_tte_add_model()`](https://erplots.djnavarro.net/reference/er_tte_add_model.md)
  (a fitted parametric `S(t)` curve/ribbon overlay).
  [`er_tte_theme()`](https://erplots.djnavarro.net/reference/er_tte_theme.md)
  styles labels, titles, axis limits, formatters, the legend key, and
  panel heights, mirroring
  [`er_plot_theme()`](https://erplots.djnavarro.net/reference/er_plot_theme.md)/[`er_vpc_theme()`](https://erplots.djnavarro.net/reference/er_vpc_theme.md).
  See the new `plot-tte` vignette.
- Added
  [`er_predict_survival()`](https://erplots.djnavarro.net/reference/er_model_interface.md),
  a fourth model-interface generic (see
  [`?er_model_interface`](https://erplots.djnavarro.net/reference/er_model_interface.md))
  powering
  [`er_tte_add_model()`](https://erplots.djnavarro.net/reference/er_tte_add_model.md)’s
  `S(t)` overlay. The new companion package `ertte`
  (`Suggests`/`Remotes`-only, GitHub- only like `erglm`/`emaxnls`)
  implements it, alongside the existing
  [`er_predict()`](https://erplots.djnavarro.net/reference/er_model_interface.md)/[`er_simulate()`](https://erplots.djnavarro.net/reference/er_model_interface.md)/[`er_summary()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
  methods.
- [`cut_quantile()`](https://erplots.djnavarro.net/reference/cut_quantile.md)/[`cut_exposure_quantile()`](https://erplots.djnavarro.net/reference/cut_quantile.md)
  gain a `ties` argument controlling how a value that sits exactly on an
  interior quantile break is assigned (`"upward"`, the default and prior
  behaviour; `"downward"`; or `"split-even"`, which randomly balances
  tied values between the two candidate bins), plus an opt-in `seed`
  argument for reproducing `"split-even"`’s random tie-break. The
  resolved rule is recorded as a `"ties"` attribute on the returned
  factor.
- [`cut_quantile()`](https://erplots.djnavarro.net/reference/cut_quantile.md)/[`cut_exposure_quantile()`](https://erplots.djnavarro.net/reference/cut_quantile.md)
  gain a `quantile_type` argument, passed straight through to
  \[stats::quantile()\]’s own `type` argument for computing the quantile
  break points. Defaults to `7` (unchanged prior behaviour) and is
  recorded as a `"quantile_type"` attribute on the returned factor.
- [`cut_quantile()`](https://erplots.djnavarro.net/reference/cut_quantile.md)/[`cut_exposure_quantile()`](https://erplots.djnavarro.net/reference/cut_quantile.md)
  gain a `labeller` argument for customising quantile-bin labels: a
  function called as `labeller(n, breaks)`, or a character vector used
  directly. Defaults to `NULL` (unchanged `"Q1"`/`"Q2"`/… labelling);
  [`cut_exposure_quantile()`](https://erplots.djnavarro.net/reference/cut_quantile.md)’s
  separate `"Placebo"` level is untouched by `labeller`.
- [`er_plot_add_quantiles()`](https://erplots.djnavarro.net/reference/er_plot_add_quantiles.md)/[`er_plot_add_groups()`](https://erplots.djnavarro.net/reference/er_plot_add_groups.md)
  gain `ties`/ `quantile_type`/`labeller` arguments, forwarded to
  [`cut_exposure_quantile()`](https://erplots.djnavarro.net/reference/cut_quantile.md)/[`cut_quantile()`](https://erplots.djnavarro.net/reference/cut_quantile.md).
  These are local to each call – they aren’t required to agree across
  different
  [`er_plot_add_groups()`](https://erplots.djnavarro.net/reference/er_plot_add_groups.md)
  calls, or with
  [`er_plot_add_quantiles()`](https://erplots.djnavarro.net/reference/er_plot_add_quantiles.md)
  – except in one case:
  [`er_plot_build()`](https://erplots.djnavarro.net/reference/er_plot_build.md)
  now warns if
  [`er_plot_add_groups()`](https://erplots.djnavarro.net/reference/er_plot_add_groups.md)
  bins *the exposure variable itself* differently than
  [`er_plot_add_quantiles()`](https://erplots.djnavarro.net/reference/er_plot_add_quantiles.md)
  does, since the two panels would then show inconsistent quantile bins
  for the same variable.
- [`er_vpc()`](https://erplots.djnavarro.net/reference/er_vpc.md) gains
  `ties`/`quantile_type`/`labeller` for `plot_by`, plus a `seed`
  argument for reproducing a `"split-even"` tie-break. Unlike the
  [`er_plot_add_quantiles()`](https://erplots.djnavarro.net/reference/er_plot_add_quantiles.md)/[`er_plot_add_groups()`](https://erplots.djnavarro.net/reference/er_plot_add_groups.md)
  arguments above, these live on
  [`er_vpc()`](https://erplots.djnavarro.net/reference/er_vpc.md) itself
  rather than on
  [`er_vpc_add_observed()`](https://erplots.djnavarro.net/reference/er_vpc_add_observed.md)/[`er_vpc_add_simulated()`](https://erplots.djnavarro.net/reference/er_vpc_add_simulated.md),
  since the observed and simulated layers must always bin `plot_by`
  identically –
  [`er_vpc_add_simulated()`](https://erplots.djnavarro.net/reference/er_vpc_add_simulated.md)’s
  own `seed` argument now also seeds its independent `"split-even"`
  tie-break.
- [`er_vpc()`](https://erplots.djnavarro.net/reference/er_vpc.md) gains
  an optional `stratify_by` for faceting a VPC into one panel per
  discrete stratum, mirroring
  [`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md)’s
  own stratification (facet-only here, since a VPC has no colour/fill
  precedence rule to reconcile). Errors if `stratify_by` resolves to the
  same variable as `plot_by`.

### Improvements

- `emaxnls` is back in `Suggests`/`Remotes` (pinned to
  `emaxnls (>= 0.1.1.9000)`, the GitHub development version), and its
  gated examples in
  [`?erplots_data`](https://erplots.djnavarro.net/reference/erplots_data.md)
  are reinstated, now that `emaxnls` registers the
  [`er_predict()`](https://erplots.djnavarro.net/reference/er_model_interface.md)/[`er_simulate()`](https://erplots.djnavarro.net/reference/er_model_interface.md)/[`er_summary()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
  methods. It had been stripped for the 0.1.0 CRAN submission, ahead of
  that registration landing.

### Breaking changes

- `stratify_by` must now name a discrete/categorical variable in
  [`er_vpc()`](https://erplots.djnavarro.net/reference/er_vpc.md); a
  numeric column errors instead of being automatically split into
  quantile bins, and the `n_strata` argument is removed. Bin a
  continuous covariate yourself first with
  [`cut_quantile()`](https://erplots.djnavarro.net/reference/cut_quantile.md)/
  [`cut_exposure_quantile()`](https://erplots.djnavarro.net/reference/cut_quantile.md),
  which also gives full control over bin count, tie-breaking, and labels
  – see [`?er_vpc`](https://erplots.djnavarro.net/reference/er_vpc.md).
  ([`er_tte()`](https://erplots.djnavarro.net/reference/er_tte.md)’s own
  `stratify_by` has the same discrete-only requirement from the outset,
  being new in this release.)

### Bug fixes

- [`er_plot_add_model()`](https://erplots.djnavarro.net/reference/er_plot_add_model.md)’s
  curve/ribbon no longer goes stale after `er_plot_theme(xlim = ...)`
  narrows or widens the exposure axis once the model layer has already
  been added – the prediction grid is now recomputed at build time
  rather than cached from add-layer time
  ([\#14](https://github.com/djnavarro/erplots/issues/14)).
- The data, quantile, and group layers now drop (and warn about) any
  observations falling outside `er_plot_theme(xlim = )`/`ylim = )`,
  instead of silently handing them to a geom that renders past the
  visible panel with no visual cue
  ([\#16](https://github.com/djnavarro/erplots/issues/16)).
- [`er_vpc_add_observed()`](https://erplots.djnavarro.net/reference/er_vpc_add_observed.md)/[`er_vpc_add_simulated()`](https://erplots.djnavarro.net/reference/er_vpc_add_simulated.md)
  summary markers falling outside `er_vpc_theme(xlim = )`/`ylim = )` are
  now dropped, with a warning, instead of silently drawn past the panel
  ([\#17](https://github.com/djnavarro/erplots/issues/17)).
- [`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md) now
  errors clearly when `stratify_by` names a numeric column, instead of
  silently mapping it to a continuous colour scale (which broke every
  stratified builder’s discrete-groups assumption – ribbons, per-stratum
  lines, dodging – with no warning). `stratify_by` has always been
  documented as requiring a discrete variable; this was simply never
  validated.
- [`er_plot_add_groups()`](https://erplots.djnavarro.net/reference/er_plot_add_groups.md)’s
  `bins` argument now actually controls the number of quantile bins used
  for a continuous grouping variable. Previously documented but silently
  ignored – every continuous grouping variable was always split into
  [`cut_quantile()`](https://erplots.djnavarro.net/reference/cut_quantile.md)/[`cut_exposure_quantile()`](https://erplots.djnavarro.net/reference/cut_quantile.md)’s
  own default of 4 bins, regardless of what `bins` was set to.

## erplots 0.1.2

CRAN release: 2026-09-09

Addresses CRAN reviewer feedback on the 0.1.1 submission. User-facing
changes:

- [`er_plot_add_data()`](https://erplots.djnavarro.net/reference/er_plot_add_data.md)’s
  two jittered builders
  ([`er_style_data_overlay()`](https://erplots.djnavarro.net/reference/er_style_data.md),
  [`er_style_data_boxjitter()`](https://erplots.djnavarro.net/reference/er_style_data.md))
  no longer hard-code a specific RNG seed (previously a literal `1234L`
  in `R/er-plot-layer.R`, used so that repeated
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html) calls on the
  same object always showed identical jitter). Seeding is now opt-in
  only: pass `seed = <value>` through
  [`er_plot_add_data()`](https://erplots.djnavarro.net/reference/er_plot_add_data.md)’s
  own `...` for reproducible jitter across rebuilds of the same object;
  with no `seed` (the default), jitter draws from the ambient RNG stream
  and differs from one build to the next, like any other jittered geom.
- [`er_plot_add_groups()`](https://erplots.djnavarro.net/reference/er_plot_add_groups.md)’s
  jittered builders
  ([`er_style_group_boxjitter()`](https://erplots.djnavarro.net/reference/er_style_group.md),
  [`er_style_group_violinjitter()`](https://erplots.djnavarro.net/reference/er_style_group.md))
  gain the same opt-in `seed` support, for consistency – their jitter
  previously had no seed control at all. `withr` moves from `Suggests`
  to `Imports` to support this.

## erplots 0.1.1

- No user-facing changes. Fixes a documentation issue flagged by CRAN’s
  Debian pretest check.

## erplots 0.1.0

Initial CRAN submission.

### `er_plot()`: the plotting mini-language

- [`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md)
  builds a fluent, pipe-based specification for exposure-response plots,
  generalised across binary, continuous, and count responses
  (`response_type = c("auto", "binary", "continuous", "count")`,
  auto-detected when not supplied).
- Six pipeline verbs attach layers to the specification – nothing is
  drawn until
  [`er_plot_build()`](https://erplots.djnavarro.net/reference/er_plot_build.md)/[`print()`](https://rdrr.io/r/base/print.html)/[`plot()`](https://rdrr.io/r/graphics/plot.default.html)
  – and pipe order never affects the built plot:
  - [`er_plot_add_model()`](https://erplots.djnavarro.net/reference/er_plot_add_model.md)
    – a model curve/ribbon.
  - [`er_plot_add_summary()`](https://erplots.djnavarro.net/reference/er_plot_add_summary.md)
    – a corner-placed text/label annotation (a model-derived statistic,
    or a plain observation count).
  - [`er_plot_add_quantiles()`](https://erplots.djnavarro.net/reference/er_plot_add_quantiles.md)
    – a quantile-binned response-rate/mean summary with confidence
    interval.
  - [`er_plot_add_data()`](https://erplots.djnavarro.net/reference/er_plot_add_data.md)
    – a raw-data layer, either an overlay drawn on the main panel or one
    or more panels stacked below it.
  - [`er_plot_add_groups()`](https://erplots.djnavarro.net/reference/er_plot_add_groups.md)
    – stacked panels showing the exposure distribution per group
    variable (the one additive, non-singleton layer).
- `stratify_by` splits colour/facet encoding across strata, following a
  documented colour/facet precedence rule (see
  `vignettes/articles/design.Rmd`).
- [`er_plot_theme()`](https://erplots.djnavarro.net/reference/er_plot_theme.md)
  styles labels, titles, axis limits, discrete/ continuous colour and
  fill palettes, formatters, the legend key glyph, and relative panel
  heights, without changing which variable drives which aesthetic.

### The model interface

- Any model implementing
  [`er_predict()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
  can be visualised; additionally implementing
  [`er_simulate()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
  and/or
  [`er_summary()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
  enables uncertainty spaghetti plots/VPCs and model-derived summary
  annotations. See
  [`?er_model_interface`](https://erplots.djnavarro.net/reference/er_model_interface.md).
- erplots never fits a model itself – it is designed to work alongside
  companion packages that implement the interface, such as `erglm`
  (GLM-based exposure-response models) and `emaxnls` (Emax/sigmoidal
  dose-response models).

### The builder system

- Every layer-adding function accepts a `style` argument (a
  `er_style_*()` builder function) that can be swapped for another
  built-in or a fully custom builder, with a documented interface
  ([`?er_style`](https://erplots.djnavarro.net/reference/er_style.md))
  and self-declared metadata via
  [`er_style_tag()`](https://erplots.djnavarro.net/reference/er_style_tag.md).
- Built-in builders cover multiple visual idioms per layer, e.g.
  ribbon/line/spaghetti model curves, p-value/n/coefficients/
  goodness-of-fit summaries, errorbar/pointrange quantile summaries
  (with boundary-labelled `_vlines` variants), overlay/hexbin/ boxjitter
  data layers, and boxplot/violin/histogram/boxjitter/ violinjitter
  group panels.

### `er_vpc()`: the visual predictive check mini-grammar

- [`er_vpc()`](https://erplots.djnavarro.net/reference/er_vpc.md) \|\>
  [`er_vpc_add_observed()`](https://erplots.djnavarro.net/reference/er_vpc_add_observed.md)
  \|\>
  [`er_vpc_add_simulated()`](https://erplots.djnavarro.net/reference/er_vpc_add_simulated.md)
  mirrors
  [`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md)’s
  object/layer/builder architecture for building visual predictive
  checks, with an optional `stratify_by` for faceted panels.
- Three visual idioms are available via `style`: an adaptive mean/
  errorbar default, a continuous-x percentile-band idiom, and an
  adaptive quantile-errorbar idiom.
- [`er_vpc_theme()`](https://erplots.djnavarro.net/reference/er_vpc_theme.md)
  styles labels, titles, axis limits, and formatters.

### Bundled example dataset

- `erplots_data` – 4,000 simulated subjects spanning three exposure
  measures and five response columns (continuous, binary, and count),
  built to exercise every response type and modelling scenario used in
  the package’s documentation and vignettes.
