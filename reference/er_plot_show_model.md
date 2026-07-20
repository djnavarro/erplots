# Add a fitted-model curve/ribbon layer

Adds the model layer: a fitted exposure-response curve with an
uncertainty ribbon (the default, via
[`er_predict()`](https://erplots.djnavarro.net/reference/er_model_interface.md)),
or a spaghetti plot of simulated draws
(`builder = build_model_spaghetti`, via
[`er_simulate()`](https://erplots.djnavarro.net/reference/er_model_interface.md)),
plus an optional summary annotation (e.g. a p-value) via
[`er_summary()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
when the layer isn't stratified. This layer needs no `response_type`
dispatch – it only ever consumes
[`er_predict()`](https://erplots.djnavarro.net/reference/er_model_interface.md)'s
output on the response's own scale.

## Usage

``` r
er_plot_show_model(
  object,
  model,
  keep_strata = NULL,
  builder = NULL,
  summary_builder = NULL,
  conf_level = 0.95
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

- builder:

  Function drawing the model curve/ribbon – defaults to
  [`build_model_ribbonline()`](https://erplots.djnavarro.net/reference/er_partial.md)
  (mean prediction + confidence ribbon).
  [`build_model_spaghetti()`](https://erplots.djnavarro.net/reference/er_partial.md)
  (simulated draws, via
  [`er_simulate()`](https://erplots.djnavarro.net/reference/er_model_interface.md))
  is the other built-in option; any function matching the standard
  `(data, config, stratify, exposure, response, strata, style)`
  signature can be supplied instead – see
  [`er_partial()`](https://erplots.djnavarro.net/reference/er_partial.md).

- summary_builder:

  Function drawing the summary annotation – defaults to
  [`build_summary_pvalue()`](https://erplots.djnavarro.net/reference/er_partial.md).
  Any function matching the same standard signature as `builder` can be
  supplied instead. See
  [`er_partial()`](https://erplots.djnavarro.net/reference/er_partial.md).

- conf_level:

  Confidence level for the prediction ribbon

## Value

The input `object`, with the model layer added

## Details

This layer is **singleton** – see
[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md)'s
"Layers are either singleton or additive" – so calling it twice replaces
the previous model layer rather than overlaying two model curves.

## See also

[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md),
[`er_plot_show_quantiles()`](https://erplots.djnavarro.net/reference/er_plot_show_quantiles.md),
[`er_plot_show_data()`](https://erplots.djnavarro.net/reference/er_plot_show_data.md),
[`er_plot_show_groups()`](https://erplots.djnavarro.net/reference/er_plot_show_groups.md),
[`er_partial()`](https://erplots.djnavarro.net/reference/er_partial.md)

## Examples

``` r
if (FALSE) { # \dontrun{
library(erglm)
mod <- erglm_model(ae1 ~ aucss, erglm_data, family = binomial())
erglm_data |>
  er_plot(aucss, ae1) |>
  er_plot_show_model(mod) |>
  plot()

# a spaghetti plot instead of the default ribbon
erglm_data |>
  er_plot(aucss, ae1) |>
  er_plot_show_model(mod, builder = build_model_spaghetti) |>
  plot()

# plug in a fully custom model-curve builder; see `?er_partial` for the
# full contract
build_model_dashed <- function(data, config, stratify, exposure, response, strata, style) {
  ggplot2::geom_line(
    data = config$predictions,
    mapping = ggplot2::aes(x = .data[[exposure$name]], y = fit_resp),
    linetype = "dashed"
  )
}
erglm_data |>
  er_plot(aucss, ae1) |>
  er_plot_show_model(mod, builder = build_model_dashed) |>
  plot()
} # }
```
