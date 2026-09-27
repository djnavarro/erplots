# Add a summary annotation layer

Adds the summary layer: a text/label annotation placed in whichever
corner of the base panel is furthest from the observed data, computed
from the raw `(exposure, response)` coordinates of the data.

## Usage

``` r
er_plot_add_summary(
  object,
  model = NULL,
  keep_strata = NULL,
  style = NULL,
  conf_level = 0.95,
  summary_args = list(),
  ...
)
```

## Arguments

- object:

  Partially constructed plot (has S3 class `er_plot`).

- model:

  A fitted exposure-response model, or `NULL` (the default). Only needed
  for builder styles (e.g.
  [`er_style_summary_pvalue()`](https://erplots.djnavarro.net/reference/er_style_summary.md))
  that produce model-based summaries; a purely descriptive builder (e.g.
  [`er_style_summary_n()`](https://erplots.djnavarro.net/reference/er_style_summary.md))
  ignores it.

- keep_strata:

  Logical; whether this layer should use stratification. Defaults to
  `TRUE` when a stratification variable has been specified, and `FALSE`
  otherwise.

- style:

  Style used to draw the summary annotation layer. Can either be a
  string corresponding to one of the registered style labels (e.g.,
  `"pvalue"`, the default), or a builder function used to compute the
  relevant plot object (see "Styles" below).

- conf_level:

  Confidence level forwarded to
  [`er_summary()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
  (used, e.g., for the `conf_low`/`conf_high` columns of its
  `coefficients` result – see
  [`?er_model_interface`](https://erplots.djnavarro.net/reference/er_model_interface.md)).
  Defaults to `0.95`. Ignored when `model` is `NULL`.

- summary_args:

  A named list of additional arguments forwarded to
  [`er_summary()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
  when generating summaries.

- ...:

  Additional named arguments forwarded to the `style` builder function
  when the plot is built.

## Value

The input `object`, with the summary layer added.

## Styles

The following pre-defined styles are available for this layer. Please
see the documentation for the corresponding builder function to see what
customisation options are available:

|  |  |  |
|----|----|----|
| Label | Builder | Description |
| `"pvalue"` | [`er_style_summary_pvalue()`](https://erplots.djnavarro.net/reference/er_style_summary.md) | A formatted p-value from the model's [`er_summary()`](https://erplots.djnavarro.net/reference/er_model_interface.md) result (the default). |
| `"n"` | [`er_style_summary_n()`](https://erplots.djnavarro.net/reference/er_style_summary.md) | Observation counts; model-agnostic, works with `model = NULL`. |
| `"coefficients"` | [`er_style_summary_coefficients()`](https://erplots.djnavarro.net/reference/er_style_summary.md) | One line per model parameter, from [`er_summary()`](https://erplots.djnavarro.net/reference/er_model_interface.md)'s `coefficients` table. |
| `"gof"` | [`er_style_summary_gof()`](https://erplots.djnavarro.net/reference/er_style_summary.md) | A goodness-of-fit annotation (N/AIC/BIC/R-squared) from [`er_summary()`](https://erplots.djnavarro.net/reference/er_model_interface.md)'s `glance` table. |

See [`er_style()`](https://erplots.djnavarro.net/reference/er_style.md)
for details on how style builder functions are defined for the
exposure-response mini-grammar, should a custom style be required.

## See also

[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md),
[`er_plot_add_model()`](https://erplots.djnavarro.net/reference/er_plot_add_model.md),
[`er_plot_add_quantiles()`](https://erplots.djnavarro.net/reference/er_plot_add_quantiles.md),
[`er_plot_add_data()`](https://erplots.djnavarro.net/reference/er_plot_add_data.md),
[`er_plot_add_groups()`](https://erplots.djnavarro.net/reference/er_plot_add_groups.md),
[`er_style()`](https://erplots.djnavarro.net/reference/er_style.md)

## Examples

``` r
if (requireNamespace("erglm", quietly = TRUE)) {
library(erglm)
mod <- erglm_model(ae1 ~ aucss, erglm_data, family = binomial())
erglm_data |>
  er_plot(aucss, ae1) |>
  er_plot_add_model(mod) |>
  er_plot_add_summary(model = mod) |>
  plot()

# a purely descriptive annotation, with no model at all
erglm_data |>
  er_plot(aucss, ae1) |>
  er_plot_add_summary(style = er_style_summary_n) |>
  plot()
}


```
