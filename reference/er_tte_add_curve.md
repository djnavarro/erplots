# Add a Kaplan-Meier curve layer

Adds the curve layer: a Kaplan-Meier step curve with a confidence band,
computed from the fit already stored on `object$km` (see
[`er_tte()`](https://erplots.djnavarro.net/reference/er_tte.md)) – no
recomputation happens here. Singleton (a second call replaces the
previous one).

## Usage

``` r
er_tte_add_curve(object, style = NULL, ...)
```

## Arguments

- object:

  Partially constructed plot (has S3 class `er_tte`).

- style:

  Function drawing the KM curve/ribbon. Defaults to
  [`er_style_tte_curve_km()`](https://erplots.djnavarro.net/reference/er_style_tte_curve.md).

- ...:

  Additional named arguments forwarded unchanged to `style` at build
  time (e.g.
  [`er_style_tte_curve_km()`](https://erplots.djnavarro.net/reference/er_style_tte_curve.md)'s
  `show_ci`/ `ribbon_alpha`/`linewidth`).

## Value

The input `object`, with the curve layer added.

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
