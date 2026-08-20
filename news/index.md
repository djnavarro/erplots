# Changelog

## erplots 0.1.1

- No user-facing changes. Fixes a documentation issue flagged by CRAN’s
  Debian pretest check:
  [`?er_style`](https://erplots.djnavarro.net/reference/er_style.md)
  used `@param` on a page with no attached function, producing an Rd
  file with `\arguments` but no `\usage` (NOTEd by a stricter R-devel Rd
  check). The argument descriptions now live in a plain
  `@section Arguments:` instead.

## erplots 0.1.0

Initial CRAN release.

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
