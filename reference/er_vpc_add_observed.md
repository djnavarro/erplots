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

  Percentiles to compute for the continuous-x line/ribbon builders
  (ignored by the default pointrange builder). Only computed for a
  continuous/count response binned on a numeric `group_by`.

- style:

  A function determining how the observed layer is drawn; see
  [`er_style_vpc_observed()`](https://erplots.djnavarro.net/reference/er_style_vpc_observed.md).

- ...:

  Additional named arguments forwarded to `style`.

## Value

`object`, with `object$layer$observed` populated.

## See also

[`er_vpc()`](https://erplots.djnavarro.net/reference/er_vpc.md),
[`er_vpc_add_simulated()`](https://erplots.djnavarro.net/reference/er_vpc_add_simulated.md),
[`er_style_vpc_observed()`](https://erplots.djnavarro.net/reference/er_style_vpc_observed.md)
