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

er_style_vpc_observed_pointrange_continuous(
  data,
  config,
  exposure,
  response,
  theme,
  point_size = 2,
  errorbar_width = 0.025,
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
errors. `er_style_vpc_observed_pointrange_continuous()` plots the same
rate/mean + confidence interval as `er_style_vpc_observed_pointrange()`,
at the bin's numeric midpoint like `er_style_vpc_observed_line()` does –
for pairing a pointrange/errorbar idiom with a `"continuous"`-layout
simulated builder (e.g.
[`er_style_vpc_simulated_ribbon()`](https://erplots.djnavarro.net/reference/er_style_vpc_simulated.md))
without a layout mismatch. It always plots the mean (from
`config$summary`, so it works for a binary response too); when
`config$percentiles` is also available (continuous/count response,
numeric `group_by`), it additionally plots a dashed pointrange/errorbar
for each requested percentile (see
[`er_vpc_add_observed()`](https://erplots.djnavarro.net/reference/er_vpc_add_observed.md)'s
`probs` argument), with a confidence interval from
[`ci_quantile()`](https://erplots.djnavarro.net/reference/ci_quantile.md)
– the observed-side analogue of the across-replicate interval
[`er_style_vpc_simulated_ribbon()`](https://erplots.djnavarro.net/reference/er_style_vpc_simulated.md)
shows as a band.

Each builder maps a constant `color = "Observed"`, so ggplot2 merges its
legend entry with whatever the paired simulated-layer builder maps for
`"Simulated"` into a single combined legend.

## See also

[`er_style()`](https://erplots.djnavarro.net/reference/er_style.md),
[`er_style_vpc_simulated()`](https://erplots.djnavarro.net/reference/er_style_vpc_simulated.md)
