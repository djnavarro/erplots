# The exposure-response plotting mini-language

Create an `er_plot` specification for exposure-response visualization.
Build the plot by adding layers (model, summary, quantiles, data,
groups) and render with
[`plot()`](https://rdrr.io/r/graphics/plot.default.html)/[`print()`](https://rdrr.io/r/base/print.html)
or
[`er_plot_build()`](https://erplots.djnavarro.net/reference/er_plot_build.md).

## Usage

``` r
er_plot(data, exposure, response, stratify_by = NULL, response_type = "auto")
```

## Arguments

- data:

  Data frame or tibble containing the observed data.

- exposure:

  Exposure variable (one variable, unquoted).

- response:

  Response variable (one variable, unquoted).

- stratify_by:

  Stratification variable used for color and fill (one variable,
  unquoted).

- response_type:

  One of `"auto"`, `"binary"`, `"continuous"`, or `"count"`.

## Value

An (empty) plot object of class `er_plot`.

## Details

Layers are either singleton or additive: model, summary, quantile, and
data layers are singleton (a second call replaces the previous); groups
are additive (each call adds a panel).

`stratify_by` declares a discrete variable used for color/fill across
layers; each layer's `keep_strata` controls whether it uses
stratification. Rows with `NA` in the stratification variable are kept
as their own level.

`response_type` governs response-scale defaults and which interval
method the quantile and VPC layers use; see `response_type` below and
[`er_plot_add_quantiles()`](https://erplots.djnavarro.net/reference/er_plot_add_quantiles.md)
for details.

## See also

[`er_plot_add_model()`](https://erplots.djnavarro.net/reference/er_plot_add_model.md),
[`er_plot_add_summary()`](https://erplots.djnavarro.net/reference/er_plot_add_summary.md),
[`er_plot_add_quantiles()`](https://erplots.djnavarro.net/reference/er_plot_add_quantiles.md),
[`er_plot_add_data()`](https://erplots.djnavarro.net/reference/er_plot_add_data.md),
[`er_plot_add_groups()`](https://erplots.djnavarro.net/reference/er_plot_add_groups.md),
[`er_plot_build()`](https://erplots.djnavarro.net/reference/er_plot_build.md),
[`er_plot_theme()`](https://erplots.djnavarro.net/reference/er_plot_theme.md),
[er_model_interface](https://erplots.djnavarro.net/reference/er_model_interface.md)

## Examples

``` r
if (requireNamespace("erglm", quietly = TRUE)) {
library(erglm)
mod <- erglm_model(ae1 ~ aucss, erglm_data, family = binomial())

erglm_data |>
  er_plot(aucss, ae1) |>
  er_plot_add_model(mod) |>
  er_plot_add_quantiles() |>
  er_plot_add_groups(aucss) |>
  plot()
}

```
