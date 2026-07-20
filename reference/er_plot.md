# The exposure-response plotting mini-language

`er_plot()` creates an (empty) plot object of S3 class `er_plot`. Build
up a plot by piping it through one or more layer functions –
[`er_plot_show_model()`](https://erplots.djnavarro.net/reference/er_plot_show_model.md)
(fitted-model curve/ribbon and summary),
[`er_plot_show_quantiles()`](https://erplots.djnavarro.net/reference/er_plot_show_quantiles.md)
(exposure-quantile-binned response summary),
[`er_plot_show_data()`](https://erplots.djnavarro.net/reference/er_plot_show_data.md)
(a strip depicting the raw data), and/or
[`er_plot_show_groups()`](https://erplots.djnavarro.net/reference/er_plot_show_groups.md)
(grouped exposure-distribution panels) – then render with
[`plot()`](https://rdrr.io/r/graphics/plot.default.html)/[`print()`](https://rdrr.io/r/base/print.html),
or build the ggplot2/patchwork objects directly with
[`er_plot_build()`](https://erplots.djnavarro.net/reference/er_plot_build.md).
`er_plot()` never fits a model itself; any model implementing the small
interface in
[er_model_interface](https://erplots.djnavarro.net/reference/er_model_interface.md)
can be passed to
[`er_plot_show_model()`](https://erplots.djnavarro.net/reference/er_plot_show_model.md).

## Usage

``` r
er_plot(data, exposure, response, stratify_by = NULL, response_type = "auto")
```

## Arguments

- data:

  Observed data

- exposure:

  Exposure variable (one variable, unquoted)

- response:

  Response variable (one variable, unquoted)

- stratify_by:

  Stratification variable used for color and fill (one variable,
  unquoted); see "Stratification" above

- response_type:

  One of `"auto"` (the default), `"binary"`, `"continuous"`, or
  `"count"`. Governs response-scale defaults (e.g. axis limits) and
  which summary/CI method the quantile and VPC layers use. When
  `"auto"`, the response column is classified as `"binary"` if it is
  logical or takes only values in `{0, 1}`, and `"continuous"` otherwise
  – this means a count (Poisson-style) response, e.g. an adverse-event
  count, auto-detects as `"continuous"` (counts aren't confined to
  `{0, 1}`) and is summarised as an approximately-continuous quantity
  (bin mean plus a t-interval). `"auto"` never resolves to `"count"`:
  pass `response_type = "count"` explicitly for a genuine count response
  to instead get bin mean plus an *exact* Poisson interval (see
  [`poisson_interval()`](https://erplots.djnavarro.net/reference/poisson_interval.md)),
  which – unlike the t-interval approximation – never produces a
  negative lower bound. See `PLAN.md`'s design decision (4) for the
  rationale.

## Value

An (empty) plot object of class `er_plot`

## Layers are either singleton or additive

[`er_plot_show_model()`](https://erplots.djnavarro.net/reference/er_plot_show_model.md),
[`er_plot_show_quantiles()`](https://erplots.djnavarro.net/reference/er_plot_show_quantiles.md),
and
[`er_plot_show_data()`](https://erplots.djnavarro.net/reference/er_plot_show_data.md)
are **singleton**: calling one of them twice on the same object
overwrites the first call's result rather than combining the two.
[`er_plot_show_groups()`](https://erplots.djnavarro.net/reference/er_plot_show_groups.md)
is **additive**: each call adds another grouped-distribution panel
alongside any already added, rather than replacing them. This asymmetry
is deliberate, not accidental – there is only one "the model" and one
"the quantile summary" to show per plot, but many legitimate ways to
slice the exposure distribution by different grouping variables. See
`PLAN.md`'s "Mini-language architecture review" for the design
discussion, including the one flagged future exception: overlaying two
model curves for comparison isn't currently supported, but is the one
singleton layer where an additive variant might eventually make sense.

## Stratification

`stratify_by` (set once, here in `er_plot()`) declares a single discrete
variable used to split layers by color/fill, with one shared,
deduplicated legend across the whole composed plot. Each layer
function's `keep_strata` argument controls whether *that* layer actually
uses the stratification (it defaults to `TRUE` whenever `stratify_by`
was set, `FALSE` otherwise).
[`er_plot_show_data()`](https://erplots.djnavarro.net/reference/er_plot_show_data.md)
is a partial exception to the "always color/fill" rule for a
continuous/count response: its color aesthetic is already spoken for by
the response value itself, so stratification falls back to one panel per
stratum level instead of a shared legend – see its own documentation and
`PLAN.md` for the general "a layer's own encoding takes precedence" rule
this follows.

## Response type

`response_type` (set once, here in `er_plot()`) governs the response's
scale (`object$response$limits`) and which summary/CI method
[`er_plot_show_quantiles()`](https://erplots.djnavarro.net/reference/er_plot_show_quantiles.md)
and
[`er_vpc_plot()`](https://erplots.djnavarro.net/reference/er_vpc_plot.md)
use; see the `response_type` parameter below and
[`er_plot_show_quantiles()`](https://erplots.djnavarro.net/reference/er_plot_show_quantiles.md)'s
own documentation for the specifics of each response type's summary
statistic.

## See also

[`er_plot_show_model()`](https://erplots.djnavarro.net/reference/er_plot_show_model.md),
[`er_plot_show_quantiles()`](https://erplots.djnavarro.net/reference/er_plot_show_quantiles.md),
[`er_plot_show_data()`](https://erplots.djnavarro.net/reference/er_plot_show_data.md),
[`er_plot_show_groups()`](https://erplots.djnavarro.net/reference/er_plot_show_groups.md),
[`er_plot_build()`](https://erplots.djnavarro.net/reference/er_plot_build.md),
[`er_plot_style()`](https://erplots.djnavarro.net/reference/er_plot_style.md),
[er_model_interface](https://erplots.djnavarro.net/reference/er_model_interface.md)

## Examples

``` r
if (FALSE) { # \dontrun{
library(erglm)
mod <- erglm_model(ae1 ~ aucss, erglm_data, family = binomial())

erglm_data |>
  er_plot(aucss, ae1) |>
  er_plot_show_model(mod) |>
  er_plot_show_quantiles() |>
  er_plot_show_groups(aucss) |>
  plot()
} # }
```
