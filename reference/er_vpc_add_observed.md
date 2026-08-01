# Add the observed-data layer to an `er_vpc` VPC

Bins the observed data by `group_by` and computes its response summary
(rate/mean + confidence interval, plus empirical percentiles for a
continuous/count response), for later comparison against a simulated
layer added via
[`er_vpc_add_simulated()`](https://erplots.djnavarro.net/reference/er_vpc_add_simulated.md).

## Usage

``` r
er_vpc_add_observed(
  object,
  group_by = NULL,
  n_bins = 4,
  conf_level = 0.95,
  probs = c(0.1, 0.5, 0.9),
  style = er_style_vpc_observed_pointrange,
  ...
)
```

## Arguments

- object:

  Partially constructed VPC (has S3 class `er_vpc`).

- group_by:

  Variable (unquoted) used to bin/group the comparison. Defaults to the
  plot's own exposure variable. A numeric variable is split into
  `n_bins` quantile bins (placebo, i.e. `0`, kept in its own bin when
  `group_by` is the exposure variable itself); a categorical variable is
  used as-is, with no binning.

- n_bins:

  Number of quantile bins, when `group_by` is numeric.

- conf_level:

  Confidence level for the observed-side interval.

- probs:

  Percentiles to compute for a `"continuous"`-layout builder (e.g.
  [`er_style_vpc_observed_line()`](https://erplots.djnavarro.net/reference/er_style_vpc_observed.md)/
  [`er_style_vpc_observed_pointrange_continuous()`](https://erplots.djnavarro.net/reference/er_style_vpc_observed.md);
  ignored by a `"categorical"`-layout builder like the default
  pointrange). Only computed for a continuous/count response binned on a
  numeric `group_by`. Should match whatever `probs` is passed to
  [`er_vpc_add_simulated()`](https://erplots.djnavarro.net/reference/er_vpc_add_simulated.md)
  – see "Details".

- style:

  A function determining how the observed layer is drawn; see
  [`er_style_vpc_observed()`](https://erplots.djnavarro.net/reference/er_style_vpc_observed.md).

- ...:

  Additional named arguments forwarded to `style`.

## Value

`object`, with `object$layer$observed` populated.

## Details

When both the observed and simulated layers use a `"continuous"`-layout
builder (see
[`er_style_tag()`](https://erplots.djnavarro.net/reference/er_style_tag.md)'s
`layout` argument),
[`er_vpc_add_simulated()`](https://erplots.djnavarro.net/reference/er_vpc_add_simulated.md)
checks this `probs` against its own and errors if they disagree, since
mismatched `probs` would otherwise silently plot two sets of percentile
bands that don't correspond to the same nominal percentile.

## See also

[`er_vpc()`](https://erplots.djnavarro.net/reference/er_vpc.md),
[`er_vpc_add_simulated()`](https://erplots.djnavarro.net/reference/er_vpc_add_simulated.md),
[`er_style_vpc_observed()`](https://erplots.djnavarro.net/reference/er_style_vpc_observed.md)
