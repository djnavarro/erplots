# Observed-layer builders for VPC plots

Builder functions for the `observed` layer
([`er_vpc_add_observed()`](https://erplots.djnavarro.net/reference/er_vpc_add_observed.md)),
drawing the observed side of a visual predictive check as a dodged
point/interval per bin (the default) or as a continuous-x line of
empirical percentiles.

## Usage

``` r
er_style_vpc_observed_pointrange(
  data,
  config,
  exposure,
  response,
  theme,
  point_size = 2,
  errorbar_width = 0.2,
  ...
)

er_style_vpc_observed_line(
  data,
  config,
  exposure,
  response,
  theme,
  point_size = 1.5,
  ...
)
```

## Arguments

- data:

  The original data frame.

- config:

  Configuration for the observed layer.

- exposure:

  Exposure variable.

- response:

  Response variable.

- theme:

  Theme components.

- point_size:

  Point size for both builders.

- errorbar_width:

  Width of `er_style_vpc_observed_pointrange()`'s error bars.

- ...:

  Additional named arguments forwarded from
  [`er_vpc_add_observed()`](https://erplots.djnavarro.net/reference/er_vpc_add_observed.md)'s
  own `...`.

## Value

A list of geoms; see
[`er_style()`](https://erplots.djnavarro.net/reference/er_style.md).

## Details

`er_style_vpc_observed_pointrange()` plots `config$summary`'s
rate/mean + confidence interval at each bin's categorical (or
quantile-bin) label, dodged alongside the simulated layer's own point +
interval. `er_style_vpc_observed_line()` instead plots
`config$percentiles` – one line per requested percentile – at each bin's
numeric midpoint on the exposure scale, for pairing with
[`er_style_vpc_simulated_ribbon()`](https://erplots.djnavarro.net/reference/er_style_vpc_simulated.md).
`config$percentiles` is only computed for a continuous/count response
binned on a numeric `group_by` (see
[`er_vpc_add_observed()`](https://erplots.djnavarro.net/reference/er_vpc_add_observed.md)'s
`probs` argument); calling `er_style_vpc_observed_line()` without it
errors.

Both builders map a constant `color = "Observed"`, so ggplot2 merges
their legend entry with whatever the paired simulated-layer builder maps
for `"Simulated"` into a single combined legend.

## See also

[`er_style()`](https://erplots.djnavarro.net/reference/er_style.md),
[`er_style_vpc_simulated()`](https://erplots.djnavarro.net/reference/er_style_vpc_simulated.md)
