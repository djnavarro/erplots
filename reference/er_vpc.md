# The exposure-response VPC mini-language

Create an `er_vpc` specification for a visual predictive check. Build
the plot by adding an observed layer and a simulated layer, and render
with
[`plot()`](https://rdrr.io/r/graphics/plot.default.html)/[`print()`](https://rdrr.io/r/base/print.html)
or
[`er_vpc_build()`](https://erplots.djnavarro.net/reference/er_vpc_build.md).

## Usage

``` r
er_vpc(
  data,
  exposure,
  response,
  response_type = "auto",
  plot_by = NULL,
  n_bins = 4,
  conf_level = 0.95,
  probs = c(0.1, 0.5, 0.9)
)
```

## Arguments

- data:

  Data frame or tibble containing the observed data.

- exposure:

  Exposure variable (one variable, unquoted).

- response:

  Response variable (one variable, unquoted).

- response_type:

  One of `"auto"`, `"binary"`, `"continuous"`, or `"count"`.

- plot_by:

  Variable (unquoted) plotted on the x-axis and used to bin/group the
  observed vs. simulated comparison. Defaults to `exposure`. A numeric
  variable is split into `n_bins` quantile bins (placebo, i.e. `0`, kept
  in its own bin when `plot_by` is the exposure variable itself); a
  categorical variable is used as-is, with no binning.

- n_bins:

  Number of quantile bins, when `plot_by` is numeric.

- conf_level:

  Confidence level for both the observed- and simulated-side intervals.
  Must be strictly between 0 and 1.

- probs:

  Percentiles to compute for a percentile-based builder (e.g.
  [`er_style_vpc_observed_quantile_line()`](https://erplots.djnavarro.net/reference/er_style_vpc_observed.md)/[`er_style_vpc_simulated_quantile_ribbon()`](https://erplots.djnavarro.net/reference/er_style_vpc_simulated.md)/
  [`er_style_vpc_observed_quantile_errorbar()`](https://erplots.djnavarro.net/reference/er_style_vpc_observed.md)/[`er_style_vpc_simulated_quantile_errorbar()`](https://erplots.djnavarro.net/reference/er_style_vpc_simulated.md);
  ignored by the default adaptive mean/errorbar pair). Only computed for
  a continuous/count response.

## Value

An (empty) plot object of class `er_vpc`.

## Details

[`er_vpc_add_observed()`](https://erplots.djnavarro.net/reference/er_vpc_add_observed.md)
bins the observed data and computes its response summary;
[`er_vpc_add_simulated()`](https://erplots.djnavarro.net/reference/er_vpc_add_simulated.md)
must be added afterwards, since it reuses the observed layer's own
binning decision so both sides share identical bin boundaries. Both
layers are singletons (a second call replaces the previous one).

Unlike
[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md),
`er_vpc()` has no stratification concept and always renders a single
panel – see
[`er_vpc_add_observed()`](https://erplots.djnavarro.net/reference/er_vpc_add_observed.md)
for `plot_by`, the (orthogonal) variable plotted on the x-axis and used
to bin/group the comparison. Whether `plot_by` is `"continuous"`
(numeric, quantile-binned) or `"discrete"` (used as-is) is auto-detected
from the column's type and stored on `object$group$type`, mirroring how
`object$response$type` records the response's type.

## See also

[`er_vpc_add_observed()`](https://erplots.djnavarro.net/reference/er_vpc_add_observed.md),
[`er_vpc_add_simulated()`](https://erplots.djnavarro.net/reference/er_vpc_add_simulated.md),
[`er_vpc_build()`](https://erplots.djnavarro.net/reference/er_vpc_build.md),
[er_model_interface](https://erplots.djnavarro.net/reference/er_model_interface.md)

## Examples

``` r
if (requireNamespace("erglm", quietly = TRUE)) {
library(erglm)
mod <- erglm_model(ae2 ~ aucss + sex, erglm_data, family = binomial())

erglm_data |>
  er_vpc(aucss, ae2, plot_by = aucss) |>
  er_vpc_add_observed() |>
  er_vpc_add_simulated(model = mod, seed = 9984) |>
  plot()
}

```
