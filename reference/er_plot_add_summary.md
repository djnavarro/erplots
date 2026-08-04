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
  that produced model-based summaries; a purely descriptive builder
  (e.g.
  [`er_style_summary_n()`](https://erplots.djnavarro.net/reference/er_style_summary.md))
  ignores it.

- keep_strata:

  Logical, indicating whether this layer should be split by the plot's
  stratification variable; defaults to `TRUE` if `stratify_by` was set
  in [`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md),
  `FALSE` otherwise.

- style:

  Function drawing the summary annotation, defaulting to
  [`er_style_summary_pvalue()`](https://erplots.djnavarro.net/reference/er_style_summary.md).

- conf_level:

  Confidence level forwarded to
  [`er_summary()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
  (used, e.g., for the `conf_low`/`conf_high` columns of its
  `coefficients` result – see
  [`?er_model_interface`](https://erplots.djnavarro.net/reference/er_model_interface.md)).
  Ignored when `model` is `NULL`.

- summary_args:

  A named list of additional arguments forwarded to
  [`er_summary()`](https://erplots.djnavarro.net/reference/er_model_interface.md),
  distinct from `...` the same way
  [`er_plot_add_model()`](https://erplots.djnavarro.net/reference/er_plot_add_model.md)'s
  `predict_args` is distinct from its own `...` – see "Details" there.

- ...:

  Additional named arguments forwarded, unchanged, to `style` when it's
  called at build time; see
  [`er_style()`](https://erplots.djnavarro.net/reference/er_style.md)'s
  "Passing extra arguments to a builder" section. Must be named.

## Value

The input `object`, with the summary layer added.

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
