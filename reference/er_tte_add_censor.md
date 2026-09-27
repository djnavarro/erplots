# Add a censoring-marks layer

Adds the censoring layer to a TTE plot, showing the times at which a
subject was censored, read from the fit already stored internally within
the plot object.

## Usage

``` r
er_tte_add_censor(object, style = NULL, ...)
```

## Arguments

- object:

  Partially constructed plot (has S3 class `er_tte`).

- style:

  Style used to draw the censoring marks layer. Can either be a string
  corresponding to one of the registered style labels (e.g., `"ticks"`,
  the default), or a builder function used to compute the relevant plot
  object (see "Styles" below).

- ...:

  Additional named arguments forwarded to the `style` builder function
  when the plot is built.

## Value

The input `object`, with the censor layer added.

## Styles

The following pre-defined styles are available for this layer. Please
see the documentation for the corresponding builder function to see what
customisation options are available:

|  |  |  |
|----|----|----|
| Label | Builder | Description |
| `"ticks"` | [`er_style_tte_censor_ticks()`](https://erplots.djnavarro.net/reference/er_style_tte_censor.md) | Tick marks at each censoring time, on the curve's current step height (the only built-in, and the default). |

See
[`er_style_tte()`](https://erplots.djnavarro.net/reference/er_style_tte.md)
for details on how style builder functions are defined for the TTE
mini-grammar, should a custom style be required.

## See also

[`er_tte()`](https://erplots.djnavarro.net/reference/er_tte.md),
[`er_style_tte_censor_ticks()`](https://erplots.djnavarro.net/reference/er_style_tte_censor.md)

## Examples

``` r
library(survival)
lung |>
  er_tte(time, status == 2) |>
  er_tte_add_curve() |>
  er_tte_add_censor() |>
  plot()

```
