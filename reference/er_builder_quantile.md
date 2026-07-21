# Quantile summary builders for exposure-response plots

Quantile summary builders for exposure-response plots

## Usage

``` r
er_builder_quantile_errorbar(
  data,
  config,
  stratify,
  exposure,
  response,
  strata,
  style
)

er_builder_quantile_bar(
  data,
  config,
  stratify,
  exposure,
  response,
  strata,
  style
)

er_builder_quantile_pointrange(
  data,
  config,
  stratify,
  exposure,
  response,
  strata,
  style
)
```

## Arguments

- data:

  The original data frame

- config:

  Configuration for the specific plot

- stratify:

  Logical indicating whether to stratify

- exposure:

  Exposure variable

- response:

  Response variable

- strata:

  Stratification variable

- style:

  Style components

## Value

A geom, or a list of geoms; see
[`er_partial()`](https://erplots.djnavarro.net/reference/er_partial.md).

## Details

Builders for the `quantile` layer
([`er_plot_add_quantiles()`](https://erplots.djnavarro.net/reference/er_plot_add_quantiles.md)),
which bins exposure into quantile groups and plots a response summary
(rate, mean, or count-mean, depending on response type) with an
uncertainty interval per bin: `er_builder_quantile_errorbar()` (point
plus error bar, the default), `er_builder_quantile_bar()` (bar plus
error bar), and `er_builder_quantile_pointrange()` (point range).

See
[`er_partial()`](https://erplots.djnavarro.net/reference/er_partial.md)
for the shared builder interface these functions implement, including
how to write a custom builder of your own.

## See also

[`er_partial()`](https://erplots.djnavarro.net/reference/er_partial.md)
