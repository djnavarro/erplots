# Add a fitted-model curve/ribbon layer

Adds the model layer: a fitted exposure-response curve with an
uncertainty ribbon (the default, via
[`er_predict()`](https://erplots.djnavarro.net/reference/er_model_interface.md)),
or a spaghetti plot of simulated draws
(`builder = er_builder_model_spaghetti`, via
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
  [`er_builder_model_ribbonline()`](https://erplots.djnavarro.net/reference/er_builder_model.md)
  (mean prediction + confidence ribbon).
  [`er_builder_model_spaghetti()`](https://erplots.djnavarro.net/reference/er_builder_model.md)
  (simulated draws, via
  [`er_simulate()`](https://erplots.djnavarro.net/reference/er_model_interface.md))
  is the other built-in option; any function matching the standard
  `(data, config, stratify, exposure, response, strata, style)`
  signature can be supplied instead – see
  [`er_builder()`](https://erplots.djnavarro.net/reference/er_builder.md).

- summary_builder:

  Function drawing the summary annotation – defaults to
  [`er_builder_summary_pvalue()`](https://erplots.djnavarro.net/reference/er_builder_summary.md).
  Any function matching the same standard signature as `builder` can be
  supplied instead. See
  [`er_builder()`](https://erplots.djnavarro.net/reference/er_builder.md).
  If `builder`/`summary_builder` is tagged with a `layer` (via
  [`er_builder_tag()`](https://erplots.djnavarro.net/reference/er_builder_tag.md))
  other than `"model"`/`"summary"` respectively, this errors
  informatively rather than passing a mismatched `config` shape to the
  builder; an untagged builder is never checked.

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
[`er_plot_add_quantiles()`](https://erplots.djnavarro.net/reference/er_plot_add_quantiles.md),
[`er_plot_add_data()`](https://erplots.djnavarro.net/reference/er_plot_add_data.md),
[`er_plot_add_groups()`](https://erplots.djnavarro.net/reference/er_plot_add_groups.md),
[`er_builder()`](https://erplots.djnavarro.net/reference/er_builder.md)

## Examples

``` r
if (FALSE) { # \dontrun{
library(erglm)
mod <- erglm_model(ae1 ~ aucss, erglm_data, family = binomial())
erglm_data |>
  er_plot(aucss, ae1) |>
  er_plot_add_model(mod) |>
  plot()

# a spaghetti plot instead of the default ribbon
erglm_data |>
  er_plot(aucss, ae1) |>
  er_plot_add_model(mod, builder = er_builder_model_spaghetti) |>
  plot()

# plug in a fully custom model-curve builder; see `?er_builder` for the
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
  er_plot_add_model(mod, builder = build_model_dashed) |>
  plot()
} # }
```
