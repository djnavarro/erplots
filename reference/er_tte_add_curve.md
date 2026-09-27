# Add a Kaplan-Meier curve layer

Adds the curve layer to a TTE plot: a Kaplan-Meier step curve with a
confidence band, computed from the fit already contained within the plot
object.

## Usage

``` r
er_tte_add_curve(object, style = NULL, ...)
```

## Arguments

- object:

  Partially constructed plot (has S3 class `er_tte`).

- style:

  Style used to draw the Kaplan-Meier curve and ribbon. Can either be a
  string corresponding to one of the registered style labels (e.g.,
  `"km"`, the default), or a builder function used to compute the
  relevant plot object (see "Styles" below).

- ...:

  Additional named arguments forwarded to the `style` builder function
  when the plot is built.

## Value

The input `object`, with the curve layer added.

## Styles

The following pre-defined styles are available for this layer. Please
see the documentation for the corresponding builder function to see what
customisation options are available:

|  |  |  |
|----|----|----|
| Label | Builder | Description |
| `"km"` | [`er_style_tte_curve_km()`](https://erplots.djnavarro.net/reference/er_style_tte_curve.md) | Kaplan-Meier step curve with a confidence band (the only built-in, and the default). |

See
[`er_style_tte()`](https://erplots.djnavarro.net/reference/er_style_tte.md)
for details on how style builder functions are defined for the TTE
mini-grammar, should a custom style be required.

## See also

[`er_tte()`](https://erplots.djnavarro.net/reference/er_tte.md),
[`er_style_tte_curve_km()`](https://erplots.djnavarro.net/reference/er_style_tte_curve.md)

## Examples

``` r
library(survival)
lung |>
  er_tte(time, status == 2) |>
  er_tte_add_curve() |>
  plot()


lung |>
  transform(sex = factor(sex, labels = c("Male", "Female"))) |>
  er_tte(time, status == 2, stratify_by = sex) |>
  er_tte_add_curve() |>
  plot()

```
