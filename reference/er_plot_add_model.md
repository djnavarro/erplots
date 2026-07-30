# Add a fitted-model curve/ribbon layer

Adds the model layer: a fitted exposure-response curve with an
uncertainty ribbon (the default, via
[`er_predict()`](https://erplots.djnavarro.net/reference/er_model_interface.md)),
or a spaghetti plot of simulated draws
(`style = er_style_model_spaghetti`, via
[`er_simulate()`](https://erplots.djnavarro.net/reference/er_model_interface.md)).
This layer uses
[`er_predict()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
to compute model predictions on the response scale.

## Usage

``` r
er_plot_add_model(
  object,
  model,
  keep_strata = NULL,
  style = NULL,
  conf_level = 0.95,
  ...
)
```

## Arguments

- object:

  Partially constructed plot (has S3 class `er_plot`)

- model:

  A fitted exposure-response model. Must implement
  [`er_predict()`](https://erplots.djnavarro.net/reference/er_model_interface.md).

- keep_strata:

  Logical; whether this layer should use stratification.

- style:

  Function drawing the model curve/ribbon. Defaults to
  [`er_style_model_ribbonline()`](https://erplots.djnavarro.net/reference/er_style_model.md).

- conf_level:

  Confidence level for the prediction ribbon.

- ...:

  Additional named arguments forwarded unchanged to `style` at build
  time.

## Value

The input `object`, with the model layer added

## Details

`model` may reference covariates beyond the exposure and strata
variables. erplots fills any additional covariates from the plot data
with a reference value (first factor level or numeric mean) when
building the prediction grid. erplots does not check that `model` was
fit on the same exposure/response as the plot; the caller must ensure
compatibility.

## See also

[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md),
[`er_plot_add_summary()`](https://erplots.djnavarro.net/reference/er_plot_add_summary.md),
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

# plug in a fully custom model-curve builder
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

# a model with a covariate beyond the exposure variable still works even when 
# this layer isn't stratifying by it: `sex` is set to a reference value 
# when building the prediction grid, which may not be what the user wants
mod_sex <- erglm_model(ae1 ~ aucss + sex, erglm_data, family = binomial())
erglm_data |>
  er_plot(aucss, ae1) |>
  er_plot_add_model(mod_sex) |>
  plot()
}

#> Using seed = 4188. Pass `seed = 4188` to reproduce this result.



```
