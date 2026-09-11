# Add a censoring-marks layer

Adds the censor layer: a tick mark at every time a subject was censored,
read from the fit already stored on `object$km` (see
[`er_tte()`](https://erplots.djnavarro.net/reference/er_tte.md)) – no
recomputation happens here. Singleton (a second call replaces the
previous one).

## Usage

``` r
er_tte_add_censor(object, style = NULL, ...)
```

## Arguments

- object:

  Partially constructed plot (has S3 class `er_tte`).

- style:

  Function drawing the censoring marks. Defaults to
  [`er_style_tte_censor_ticks()`](https://erplots.djnavarro.net/reference/er_style_tte_censor.md).

- ...:

  Additional named arguments forwarded unchanged to `style` at build
  time (e.g.
  [`er_style_tte_censor_ticks()`](https://erplots.djnavarro.net/reference/er_style_tte_censor.md)'s
  `shape`/ `size`/`stroke`).

## Value

The input `object`, with the censor layer added.

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
