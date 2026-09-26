# erplots 0.2.0

## New features

* Added `er_tte()`, a third mini-grammar (alongside `er_plot()`/`er_vpc()`)
  for Kaplan-Meier/survival-over-time figures, built around a time axis,
  a survival-probability axis, and an optional discrete `stratify_by`.
  Five singleton layers: `er_tte_add_curve()` (the KM step curve +
  confidence band), `er_tte_add_censor()` (censoring tick marks),
  `er_tte_add_risktable()` (a number-at-risk panel stacked below the
  curve), `er_tte_add_summary()` (a corner-placed text/label annotation
  -- a log-rank test by default, or subject/event counts or a fitted
  model's coefficients/goodness-of-fit via `style`), and
  `er_tte_add_model()` (a fitted parametric `S(t)` curve/ribbon
  overlay). `er_tte_theme()` styles labels, titles, axis limits,
  formatters, the legend key, and panel heights, mirroring
  `er_plot_theme()`/`er_vpc_theme()`. See the new `plot-tte` vignette.
* Added `er_predict_survival()`, a fourth model-interface generic (see
  `?er_model_interface`) powering `er_tte_add_model()`'s `S(t)` overlay.
  The new companion package `ertte` (`Suggests`/`Remotes`-only, GitHub-
  only like `erglm`/`emaxnls`) implements it, alongside the existing
  `er_predict()`/`er_simulate()`/`er_summary()` methods.
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
* `er_vpc()` gains an optional `stratify_by` for faceting a VPC into one
  panel per discrete stratum, mirroring `er_plot()`'s own stratification
  (facet-only here, since a VPC has no colour/fill precedence rule to
  reconcile). Errors if `stratify_by` resolves to the same variable as
  `plot_by`.
* `er_style_tag()` gains a `label` argument for registering a builder
  under a short string (e.g. `label = "logrank"`), so the corresponding
  `_add_*()` function's `style` argument can be given that string
  instead of the function itself (e.g.
  `er_plot_add_model(mod, style = "spaghetti")` in place of `style =
  er_style_model_spaghetti`). Every built-in builder across all three
  grammars is tagged with one; see `er_style_labels()` to list what's
  registered (optionally filtered to one `layer`), and `?er_style_tag`
  for the full naming/lookup contract. `label` requires `layer` to also
  be set in the same call, since the registry is keyed by `(layer,
  label)`, not `label` alone. A new `overwrite` argument (default
  `FALSE`) controls what happens when re-registering a `(layer, label)`
  pair already assigned to a *different* function: errors by default;
  `overwrite = TRUE` replaces it unconditionally. Re-registering the
  identical function is always a silent no-op regardless of `overwrite`.

## Improvements

* `er_style_vpc_observed_mean_errorbar()`/`er_style_vpc_simulated_mean_errorbar()`
  gain an opt-in `show_label`/`label_size` pair that draws each bin's
  formatted rate/mean above its error bar, making `er_vpc_theme()`'s
  `format_percent`/`format_number` arguments actually visible (#22).
* `er_style_tte_risktable_text()` gains an opt-in `show_percent`
  argument that appends each break's number at risk as a percentage of
  its stratum's baseline size, using `er_tte_theme()`'s `format_percent`
  (#22).
* `emaxnls` is back in `Suggests`/`Remotes` (pinned to
  `emaxnls (>= 0.1.1.9000)`, the GitHub development version), and its
  gated examples in `?erplots_data` are reinstated, now that `emaxnls`
  registers the `er_predict()`/`er_simulate()`/`er_summary()` methods.
  It had been stripped for the 0.1.0 CRAN submission, ahead of that
  registration landing.

## Breaking changes

* `er_style_tag()`'s `zorder` argument is renamed to `draw_order` (same
  `"foreground"`/`"background"` values); a builder tagged with the old
  name needs updating (e.g. `er_style_tag(fn, draw_order = "background")`
  in place of `zorder = "background")`). `layout` is split into two
  independent arguments: `layout` keeps its existing `"overlay"`/
  `"panel"` meaning for a data-layer builder, while a VPC observed/
  simulated builder's `"categorical"`/`"continuous"` distinction moves to
  a new `vpc_layout` argument -- the two had shared one argument and
  attribute despite meaning unrelated things. See `?er_style_tag`.
* `er_style_tag()`'s `layer` values are renamed to be grammar-prefixed:
  `"model"`/`"summary"`/`"quantile"`/`"data"`/`"group"` (`er_plot()`)
  become `"plot_model"`/`"plot_summary"`/`"plot_quantile"`/`"plot_data"`/
  `"plot_group"`; `"observed"`/`"simulated"` (`er_vpc()`) become
  `"vpc_observed"`/`"vpc_simulated"`; `"curve"`/`"censor"`/`"risktable"`
  (`er_tte()`) become `"tte_curve"`/`"tte_censor"`/`"tte_risktable"`.
  `"tte_model"`/`"tte_summary"` are unchanged (already grammar-prefixed).
  A custom builder tagged with one of the old values needs updating; see
  `?er_style_tag`.
* `stratify_by` must now name a discrete/categorical variable in
  `er_vpc()`; a numeric column errors instead of being automatically
  split into quantile bins, and the `n_strata` argument is removed. Bin
  a continuous covariate yourself first with `cut_quantile()`/
  `cut_exposure_quantile()`, which also gives full control over bin
  count, tie-breaking, and labels -- see `?er_vpc`. (`er_tte()`'s own
  `stratify_by` has the same discrete-only requirement from the outset,
  being new in this release.)

## Bug fixes

* `er_plot_add_model()`'s curve/ribbon no longer goes stale after
  `er_plot_theme(xlim = ...)` narrows or widens the exposure axis once
  the model layer has already been added -- the prediction grid is now
  recomputed at build time rather than cached from add-layer time (#14).
* The data, quantile, and group layers now drop (and warn about) any
  observations falling outside `er_plot_theme(xlim = )`/`ylim = )`,
  instead of silently handing them to a geom that renders past the
  visible panel with no visual cue (#16).
* `er_vpc_add_observed()`/`er_vpc_add_simulated()` summary markers
  falling outside `er_vpc_theme(xlim = )`/`ylim = )` are now dropped,
  with a warning, instead of silently drawn past the panel (#17).
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
* `er_style_quantile_errorbar_vlines()`/`er_style_quantile_pointrange_vlines()`'s
  bin-boundary lines/labels are now dropped (and warn), like every other
  layer's out-of-range markers, when they fall outside
  `er_plot_theme(xlim = )`, instead of silently landing off the visible
  panel with no cue (#16).

## Documentation

* `?er_style_tag` is rewritten to describe the mechanism as a whole --
  the shared self-declaration system every built-in builder across
  `er_plot()`/`er_vpc()`/`er_tte()` carries -- rather than describing
  each argument in isolation.
* Added `?er_style_vpc`/`?er_style_tte`, documenting the shared builder
  interface for `er_vpc()`/`er_tte()` builders, alongside the existing
  `?er_style` for `er_plot()`. Previously this material was scattered
  across each builder family's own help page.
* Fixed several cross-reference links in the pkgdown articles that
  previously rendered as literal bracketed text instead of a hyperlink.
* Every layer-adding function (`er_plot_add_model()`,
  `er_plot_add_summary()`, `er_plot_add_quantiles()`, `er_plot_add_data()`,
  `er_plot_add_groups()`, `er_vpc_add_observed()`, `er_vpc_add_simulated()`,
  and all five `er_tte_add_*()` functions) now documents a "Styles" table
  listing every registered `style` label for that layer, linking straight
  to each builder's own help page.

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
