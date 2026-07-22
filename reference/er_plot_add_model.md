# Add a fitted-model curve/ribbon layer

Adds the model layer: a fitted exposure-response curve with an
uncertainty ribbon (the default, via
[`er_predict()`](https://erplots.djnavarro.net/reference/er_model_interface.md)),
or a spaghetti plot of simulated draws
(`style = er_style_model_spaghetti`, via
[`er_simulate()`](https://erplots.djnavarro.net/reference/er_model_interface.md)),
plus an optional summary annotation (e.g. a p-value) via
[`er_summary()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
when the layer isn't stratified. This layer needs no `response_type`
dispatch – it only ever consumes
[`er_predict()`](https://erplots.djnavarro.net/reference/er_model_interface.md)'s
output on the response's own scale.

## Usage

``` r
er_plot_add_model(
  object,
  model,
  keep_strata = NULL,
  style = NULL,
  summary_style = NULL,
  conf_level = 0.95,
  ...
)
```

## Arguments

- object:

  Partially constructed plot (has S3 class `er_plot`)

- model:

  A fitted exposure-response model. Must implement
  [`er_predict()`](https://erplots.djnavarro.net/reference/er_model_interface.md);
  implementing
  [`er_simulate()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
  and
  [`er_summary()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
  enables additional visualisations (see
  [er_model_interface](https://erplots.djnavarro.net/reference/er_model_interface.md))

- keep_strata:

  Logical, indicating whether this layer should be split by the plot's
  stratification variable; defaults to `TRUE` if `stratify_by` was set
  in [`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md),
  `FALSE` otherwise

- style:

  Function drawing the model curve/ribbon – defaults to
  [`er_style_model_ribbonline()`](https://erplots.djnavarro.net/reference/er_style_model.md)
  (mean prediction + confidence ribbon).
  [`er_style_model_spaghetti()`](https://erplots.djnavarro.net/reference/er_style_model.md)
  (simulated draws, via
  [`er_simulate()`](https://erplots.djnavarro.net/reference/er_model_interface.md))
  is the other built-in option; any function matching the standard
  `(data, config, stratify, exposure, response, strata, theme, ...)`
  signature can be supplied instead – see
  [`er_style()`](https://erplots.djnavarro.net/reference/er_style.md).

- summary_style:

  Function drawing the summary annotation – defaults to
  [`er_style_summary_pvalue()`](https://erplots.djnavarro.net/reference/er_style_summary.md).
  Any function matching the same standard signature as `style` can be
  supplied instead. See
  [`er_style()`](https://erplots.djnavarro.net/reference/er_style.md).
  If `style`/`summary_style` is tagged with a `layer` (via
  [`er_style_tag()`](https://erplots.djnavarro.net/reference/er_style_tag.md))
  other than `"model"`/`"summary"` respectively, this errors
  informatively rather than passing a mismatched `config` shape to the
  builder; an untagged builder is never checked.

- conf_level:

  Confidence level for the prediction ribbon

- ...:

  Additional named arguments forwarded, unchanged, to both `style` and
  `summary_style` when they're called at build time (each builder is
  free to use only the arguments it recognizes, via its own `...`). Must
  be named – see
  [`er_style()`](https://erplots.djnavarro.net/reference/er_style.md)'s
  "Passing extra arguments to a builder" section. For example,
  `er_plot_add_model(mod, style = er_style_model_spaghetti, seed = 9626)`
  lets
  [`er_style_model_spaghetti()`](https://erplots.djnavarro.net/reference/er_style_model.md)
  pass a reproducible `seed` to
  [`er_simulate()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
  instead of relying on erglm's auto-selected one.

## Value

The input `object`, with the model layer added

## Details

This layer is **singleton** – see
[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md)'s
"Layers are either singleton or additive" – so calling it twice replaces
the previous model layer rather than overlaying two model curves.

## See also

[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md),
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
  plot()

# a spaghetti plot instead of the default ribbon
erglm_data |>
  er_plot(aucss, ae1) |>
  er_plot_add_model(mod, style = er_style_model_spaghetti) |>
  plot()

# plug in a fully custom model-curve builder; see `?er_style` for the
# full contract
build_model_dashed <- function(data, config, stratify, exposure, response, strata, theme, ...) {
  ggplot2::geom_line(
    data = config$predictions,
    mapping = ggplot2::aes(x = .data[[exposure$name]], y = fit_resp),
    linetype = "dashed"
  )
}
erglm_data |>
  er_plot(aucss, ae1) |>
  er_plot_add_model(mod, style = build_model_dashed) |>
  plot()
}

#> Using seed = 4188. Pass `seed = 4188` to reproduce this result.


```
