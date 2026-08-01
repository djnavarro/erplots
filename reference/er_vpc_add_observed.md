# Add the observed-data layer to an `er_vpc` VPC

Bins the observed data by `plot_by` (see
[`er_vpc()`](https://erplots.djnavarro.net/reference/er_vpc.md)) and
computes its response summary (rate/mean + confidence interval, plus
empirical percentiles for a continuous/count response), for later
comparison against a simulated layer added via
[`er_vpc_add_simulated()`](https://erplots.djnavarro.net/reference/er_vpc_add_simulated.md).

## Usage

``` r
er_vpc_add_observed(object, style = er_style_vpc_observed_mean_errorbar, ...)
```

## Arguments

- object:

  Partially constructed VPC (has S3 class `er_vpc`).

- style:

  A function determining how the observed layer is drawn; see
  [`er_style_vpc_observed()`](https://erplots.djnavarro.net/reference/er_style_vpc_observed.md).

- ...:

  Additional named arguments forwarded to `style`.

## Value

`object`, with `object$layer$observed` populated.

## Details

`plot_by`/`n_bins`/`conf_level`/`probs` are set once on
[`er_vpc()`](https://erplots.djnavarro.net/reference/er_vpc.md) itself
(rather than here) so the observed and simulated layers can't disagree
about how the comparison is binned or summarized.

## See also

[`er_vpc()`](https://erplots.djnavarro.net/reference/er_vpc.md),
[`er_vpc_add_simulated()`](https://erplots.djnavarro.net/reference/er_vpc_add_simulated.md),
[`er_style_vpc_observed()`](https://erplots.djnavarro.net/reference/er_style_vpc_observed.md)
