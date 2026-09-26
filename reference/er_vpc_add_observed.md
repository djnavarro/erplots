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

  A function determining how the observed layer is drawn. Defaults to
  [`er_style_vpc_observed_mean_errorbar()`](https://erplots.djnavarro.net/reference/er_style_vpc_observed.md);
  see
  [`er_style_vpc_observed()`](https://erplots.djnavarro.net/reference/er_style_vpc_observed.md)
  for the other built-in options. Or one of the registered short-string
  labels for this layer (see "Styles" below).

- ...:

  Additional named arguments forwarded to `style`.

## Value

`object`, with `object$layer$observed` populated.

## Details

`plot_by`/`n_bins`/`conf_level`/`probs` are set once on
[`er_vpc()`](https://erplots.djnavarro.net/reference/er_vpc.md) itself
(rather than here) so the observed and simulated layers can't disagree
about how the comparison is binned or summarized.

## Styles

|  |  |  |
|----|----|----|
| Label | Builder | Description |
| `"mean_errorbar"` | [`er_style_vpc_observed_mean_errorbar()`](https://erplots.djnavarro.net/reference/er_style_vpc_observed.md) | Mean/rate + CI per bin, x-position adaptive to `plot_by`'s type (the default). |
| `"quantile_line"` | [`er_style_vpc_observed_quantile_line()`](https://erplots.djnavarro.net/reference/er_style_vpc_observed.md) | One line per requested percentile against a continuous `plot_by` axis. |
| `"quantile_errorbar"` | [`er_style_vpc_observed_quantile_errorbar()`](https://erplots.djnavarro.net/reference/er_style_vpc_observed.md) | Point + error bar per bin and per requested percentile. |

## See also

[`er_vpc()`](https://erplots.djnavarro.net/reference/er_vpc.md),
[`er_vpc_add_simulated()`](https://erplots.djnavarro.net/reference/er_vpc_add_simulated.md),
[`er_style_vpc_observed()`](https://erplots.djnavarro.net/reference/er_style_vpc_observed.md)
