# Add the observed-data layer to a VPC plot

Bins the observed data for a VPC plot and computes binned response
summaries for later comparison against a simulated data layer.

## Usage

``` r
er_vpc_add_observed(object, style = er_style_vpc_observed_mean_errorbar, ...)
```

## Arguments

- object:

  Partially constructed VPC (has S3 class `er_vpc`).

- style:

  Style used to draw the VPC observed data layer. Can either be a string
  corresponding to one of the registered style labels (e.g.,
  `"mean_errorbar"`, the default), or a builder function used to compute
  the relevant plot object (see "Styles" below).

- ...:

  Additional named arguments forwarded to the `style` builder function
  when the plot is built.

## Value

`object`, with `object$layer$observed` populated.

## Details

`plot_by`/`n_bins`/`conf_level`/`probs` are set once on
[`er_vpc()`](https://erplots.djnavarro.net/reference/er_vpc.md) itself
(rather than here) so the observed and simulated layers can't disagree
about how the comparison is binned or summarized.

## Styles

The following pre-defined styles are available for this layer. Please
see the documentation for the corresponding builder function to see what
customisation options are available:

|  |  |  |
|----|----|----|
| Label | Builder | Description |
| `"mean_errorbar"` | [`er_style_vpc_observed_mean_errorbar()`](https://erplots.djnavarro.net/reference/er_style_vpc_observed.md) | Mean/rate + CI per bin, x-position adaptive to `plot_by`'s type (the default). |
| `"quantile_line"` | [`er_style_vpc_observed_quantile_line()`](https://erplots.djnavarro.net/reference/er_style_vpc_observed.md) | One line per requested percentile against a continuous `plot_by` axis. |
| `"quantile_errorbar"` | [`er_style_vpc_observed_quantile_errorbar()`](https://erplots.djnavarro.net/reference/er_style_vpc_observed.md) | Point + error bar per bin and per requested percentile. |

See
[`er_style_vpc()`](https://erplots.djnavarro.net/reference/er_style_vpc.md)
for details on how style builder functions are defined for the VPC
mini-grammar, should a custom style be required.

## See also

[`er_vpc()`](https://erplots.djnavarro.net/reference/er_vpc.md),
[`er_vpc_add_simulated()`](https://erplots.djnavarro.net/reference/er_vpc_add_simulated.md),
[`er_style_vpc_observed()`](https://erplots.djnavarro.net/reference/er_style_vpc_observed.md)
