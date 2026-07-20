# Add a quantile-binned response summary layer

Adds the quantile layer: exposure is cut into quantile bins (see
[`cut_exposure_quantile()`](https://erplots.djnavarro.net/reference/cut_quantile.md))
and, within each bin, the response is summarised with a point estimate
and confidence interval. Which summary/CI method is used dispatches on
the plot's `response_type` (set in
[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md)):

- `"binary"` – response *rate*, with a Clopper-Pearson interval (see
  [`clopper_pearson()`](https://erplots.djnavarro.net/reference/clopper_pearson.md))

- `"continuous"` – bin *mean*, with a t-interval (see
  [`t_interval()`](https://erplots.djnavarro.net/reference/t_interval.md))

- `"count"` – bin *mean*, with an exact Poisson interval (see
  [`poisson_interval()`](https://erplots.djnavarro.net/reference/poisson_interval.md))

## Usage

``` r
er_plot_show_quantiles(
  object,
  keep_strata = NULL,
  style = "errorbar",
  builder = NULL,
  bins = 4,
  conf_level = 0.95
)
```

## Arguments

- object:

  Partially constructed plot (has S3 class `er_plot`)

- keep_strata:

  Logical, indicating whether this layer should be split by the plot's
  stratification variable; defaults to `TRUE` if `stratify_by` was set
  in [`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md),
  `FALSE` otherwise

- style:

  Character string selecting the partial builder: `"errorbar"` (default;
  point + error bar, via
  [`build_quantile_errorbar()`](https://erplots.djnavarro.net/reference/er_partial.md))
  or `"pointrange"` (a single
  [`ggplot2::geom_pointrange()`](https://ggplot2.tidyverse.org/reference/geom_linerange.html),
  via
  [`build_quantile_pointrange()`](https://erplots.djnavarro.net/reference/er_partial.md)).
  Ignored when `builder` is supplied.

- builder:

  Optional function overriding the builder that `style` would otherwise
  select – the escape hatch documented in
  [`er_partial()`](https://erplots.djnavarro.net/reference/er_partial.md)
  for plugging in a custom `build_quantile_*()`-style function without
  touching package internals. Must accept and use the standard
  `(data, config, stratify, exposure, response, strata, style)`
  signature; `config$summary` is the pre-computed per-bin data frame
  (point estimate + CI) to draw.

- bins:

  Number of exposure bins (not counting placebo)

- conf_level:

  Confidence level for the interval

## Value

The input `object`, with the quantile layer added

## Details

Count responses auto-detect as `"continuous"` (see
[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md)'s
`response_type` parameter) and are summarised the same way as any other
continuous response unless `response_type = "count"` is declared
explicitly.

This layer is **singleton** – see
[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md)'s
"Layers are either singleton or additive" – so calling it twice replaces
the previous quantile summary rather than combining bins from both
calls.

## See also

[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md),
[`er_plot_show_model()`](https://erplots.djnavarro.net/reference/er_plot_show_model.md),
[`er_plot_show_data()`](https://erplots.djnavarro.net/reference/er_plot_show_data.md),
[`er_plot_show_groups()`](https://erplots.djnavarro.net/reference/er_plot_show_groups.md),
[`er_vpc_plot()`](https://erplots.djnavarro.net/reference/er_vpc_plot.md),
[`er_partial()`](https://erplots.djnavarro.net/reference/er_partial.md)

## Examples

``` r
if (FALSE) { # \dontrun{
library(erglm)
mod <- erglm_model(ae1 ~ aucss, erglm_data, family = binomial())
erglm_data |>
  er_plot(aucss, ae1) |>
  er_plot_show_model(mod) |>
  er_plot_show_quantiles() |>
  plot()

# continuous response: bin means/t-intervals instead of rates/
# Clopper-Pearson intervals, auto-detected from the response column
mod3 <- erglm_model(biomarker_change ~ aucss, erglm_data, family = gaussian())
erglm_data |>
  er_plot(aucss, biomarker_change) |>
  er_plot_show_model(mod3) |>
  er_plot_show_quantiles() |>
  plot()

# count response: declare response_type = "count" explicitly for an
# exact Poisson interval instead of the t-interval approximation used
# by the auto-detected ("continuous") default
mod4 <- erglm_model(ae_count ~ aucss, erglm_data, family = poisson())
erglm_data |>
  er_plot(aucss, ae_count, response_type = "count") |>
  er_plot_show_model(mod4) |>
  er_plot_show_quantiles() |>
  plot()

# a pointrange instead of an errorbar
erglm_data |>
  er_plot(aucss, ae1) |>
  er_plot_show_model(mod) |>
  er_plot_show_quantiles(style = "pointrange") |>
  plot()

# plug in a fully custom builder instead of choosing a built-in
# `style`; see `?er_partial` for the full contract
build_quantile_crossbar <- function(data, config, stratify, exposure, response, strata, style) {
  ggplot2::geom_crossbar(
    data = config$summary,
    mapping = ggplot2::aes(x = x_mid, y = y_mid, ymin = ci_lower, ymax = ci_upper),
    inherit.aes = FALSE
  )
}
erglm_data |>
  er_plot(aucss, ae1) |>
  er_plot_show_model(mod) |>
  er_plot_show_quantiles(builder = build_quantile_crossbar) |>
  plot()
} # }
```
