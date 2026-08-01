# Simulated-layer builders for VPC plots

Builder functions for the `simulated` layer
([`er_vpc_add_simulated()`](https://erplots.djnavarro.net/reference/er_vpc_add_simulated.md)),
drawing the simulated side of a visual predictive check as a dodged
point/interval per bin (the default) or as continuous-x percentile
bands.

## Usage

``` r
er_style_vpc_simulated_errorbar(
  data,
  config,
  exposure,
  response,
  theme,
  point_size = 2,
  errorbar_width = 0.2,
  ...
)

er_style_vpc_simulated_ribbon(
  data,
  config,
  exposure,
  response,
  theme,
  ribbon_alpha = 0.3,
  ...
)
```

## Arguments

- data:

  The original data frame.

- config:

  Configuration for the simulated layer.

- exposure:

  Exposure variable.

- response:

  Response variable.

- theme:

  Theme components.

- point_size:

  Point size for `er_style_vpc_simulated_errorbar()`.

- errorbar_width:

  Width of `er_style_vpc_simulated_errorbar()`'s error bars.

- ...:

  Additional named arguments forwarded from
  [`er_vpc_add_simulated()`](https://erplots.djnavarro.net/reference/er_vpc_add_simulated.md)'s
  own `...`.

- ribbon_alpha:

  Fill transparency for `er_style_vpc_simulated_ribbon()`'s bands.

## Value

A list of geoms; see
[`er_style()`](https://erplots.djnavarro.net/reference/er_style.md).

## Details

`er_style_vpc_simulated_errorbar()` plots `config$summary`'s mean +
percentile interval (of the mean, across replicates) at each bin's
categorical (or quantile-bin) label, dodged alongside the observed
layer's own point + interval. `er_style_vpc_simulated_ribbon()` instead
plots `config$percentiles` – one shaded band (median line + interval)
per requested percentile – at each bin's numeric midpoint on the
exposure scale, for pairing with
[`er_style_vpc_observed_line()`](https://erplots.djnavarro.net/reference/er_style_vpc_observed.md).
`config$percentiles` is only computed for a continuous/count response
binned on a numeric `group_by` (see
[`er_vpc_add_observed()`](https://erplots.djnavarro.net/reference/er_vpc_add_observed.md)'s
`probs` argument, which should match what was passed to
[`er_vpc_add_simulated()`](https://erplots.djnavarro.net/reference/er_vpc_add_simulated.md));
calling `er_style_vpc_simulated_ribbon()` without it errors.

`er_style_vpc_simulated_errorbar()` maps a constant
`color = "Simulated"`; `er_style_vpc_simulated_ribbon()` maps a constant
`fill = "Simulated"`. ggplot2 merges either into the paired observed
builder's own `"Observed"` legend entry (same aesthetic) into one
combined legend; the ribbon's `fill` legend is separate from the
point/errorbar builders' `color` legend.

## See also

[`er_style()`](https://erplots.djnavarro.net/reference/er_style.md),
[`er_style_vpc_observed()`](https://erplots.djnavarro.net/reference/er_style_vpc_observed.md)
