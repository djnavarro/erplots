# Add a parametric survival-curve overlay layer

Adds the model layer: a fitted parametric `S(t)` curve (with an
uncertainty band) from a time-to-event model, overlaid on the
Kaplan-Meier curve already stored on `object$km` (see
[`er_tte()`](https://erplots.djnavarro.net/reference/er_tte.md)).
Singleton (a second call replaces the previous one).

## Usage

``` r
er_tte_add_model(
  object,
  model,
  keep_strata = NULL,
  style = NULL,
  conf_level = 0.95,
  time_grid = NULL,
  predict_args = list(),
  ...
)
```

## Arguments

- object:

  Partially constructed plot (has S3 class `er_tte`).

- model:

  A fitted time-to-event model. Must implement
  [`er_predict_survival()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
  (see
  [er_model_interface](https://erplots.djnavarro.net/reference/er_model_interface.md)).

- keep_strata:

  Logical; whether this layer should draw one curve per stratum level.
  Defaults to `!is.null(object$strata)`.

- style:

  Function drawing the model curve/ribbon. Defaults to
  [`er_style_tte_model_line()`](https://erplots.djnavarro.net/reference/er_style_tte_model.md).

- conf_level:

  Confidence level for the prediction band.

- time_grid:

  Numeric vector of times at which to predict `S(t)`, or `NULL` (the
  default) to use 100 points evenly spaced across `object$time$limits`.

- predict_args:

  A named list of additional arguments forwarded to
  [`er_predict_survival()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
  (e.g. a model-specific argument its method requires beyond
  `model`/`newdata`/`time_grid`/`conf_level`). Distinct from `...`:
  `predict_args` reaches
  [`er_predict_survival()`](https://erplots.djnavarro.net/reference/er_model_interface.md),
  `...` reaches `style` – mirroring
  [`er_plot_add_model()`](https://erplots.djnavarro.net/reference/er_plot_add_model.md)'s
  `predict_args`.

- ...:

  Additional named arguments forwarded unchanged to `style` at build
  time.

## Value

The input `object`, with the model layer added.

## Details

`model` may reference covariates beyond the strata variable; erplots
fills any additional covariate from the plot data with a reference value
(first factor level or numeric mean), exactly as
[`er_plot_add_model()`](https://erplots.djnavarro.net/reference/er_plot_add_model.md)
does – see its "Details". Strata membership is carried on the `newdata`
passed to
[`er_predict_survival()`](https://erplots.djnavarro.net/reference/er_model_interface.md),
never implicit in `model` itself – see
[er_model_interface](https://erplots.djnavarro.net/reference/er_model_interface.md)'s
"Details".

erplots does not check that `model` was fit on the same time/event
variables as the plot; the caller must ensure compatibility.

## See also

[`er_tte()`](https://erplots.djnavarro.net/reference/er_tte.md),
[`er_style_tte_model_line()`](https://erplots.djnavarro.net/reference/er_style_tte_model.md),
[er_model_interface](https://erplots.djnavarro.net/reference/er_model_interface.md)
