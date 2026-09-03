# erplots 0.2.0

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
