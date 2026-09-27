# Add a model-based survival curve overlay

Adds the model layer to a TTE plot: a fitted survival curve with an
uncertainty band derived from the corresponding time-to-event model.

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
  [`er_predict_survival()`](https://erplots.djnavarro.net/reference/er_model_interface.md).

- keep_strata:

  Logical; whether this layer should use stratification. Defaults to
  `TRUE` when a stratification variable has been specified, and `FALSE`
  otherwise.

- style:

  Style used to draw the model-based survival curve. Can either be a
  string corresponding to one of the registered style labels (e.g.,
  `"line"`, the default), or a builder function used to compute the
  relevant plot object (see "Styles" below).

- conf_level:

  Confidence level for the prediction band. Defaults to `0.95`.

- time_grid:

  Numeric vector of times at which to predict `S(t)`, or `NULL` (the
  default) to use 100 points evenly spaced across the time range.

- predict_args:

  A named list of additional arguments forwarded to
  [`er_predict_survival()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
  when generating model-based predictions.

- ...:

  Additional named arguments forwarded to the `style` builder function
  when the plot is built.

## Value

The input `object`, with the model layer added.

## Details

The model layer of a TTE plot is used to display predictions generated
from an underlying survival model (e.g., parametric accelerated failure
time model, Cox proportional hazards model, etc). It uses the `model`
object to create the predictions, using the
[`er_predict_survival()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
method for the relevant model class to do the work. The `model` object
is permitted to reference covariates other than the plot stratification
variable: see the details section of
[`er_plot_add_model()`](https://erplots.djnavarro.net/reference/er_plot_add_model.md)
for the specifics.

Note that erplots does not check that `model` was fit on the same
time/event variables passed to the plot itself; it is left to the user
to ensure that the data set provided to the model is consistent with the
data provided to the TTE plot.

## Styles

The following pre-defined styles are available for this layer. Please
see the documentation for the corresponding builder function to see what
customisation options are available:

|  |  |  |
|----|----|----|
| Label | Builder | Description |
| `"line"` | [`er_style_tte_model_line()`](https://erplots.djnavarro.net/reference/er_style_tte_model.md) | Fitted `S(t)` curve with an uncertainty band (the only built-in, and the default). |

See
[`er_style_tte()`](https://erplots.djnavarro.net/reference/er_style_tte.md)
for details on how style builder functions are defined for the TTE
mini-grammar, should a custom style be required.

## See also

[`er_tte()`](https://erplots.djnavarro.net/reference/er_tte.md),
[`er_style_tte_model_line()`](https://erplots.djnavarro.net/reference/er_style_tte_model.md),
[er_model_interface](https://erplots.djnavarro.net/reference/er_model_interface.md)
