# Add a number-at-risk panel

Adds the risktable layer: a patchwork panel stacked below the curve,
showing the number of subjects still at risk at a grid of time points
(one row per stratum, when stratified) – read from the fit already
stored on `object$km` (see
[`er_tte()`](https://erplots.djnavarro.net/reference/er_tte.md)) via
`summary.survfit(..., extend = TRUE)`. Singleton (a second call replaces
the previous one).

## Usage

``` r
er_tte_add_risktable(object, style = NULL, times = NULL, n_times = 6, ...)
```

## Arguments

- object:

  Partially constructed plot (has S3 class `er_tte`).

- style:

  Function drawing the risk-count labels. Defaults to
  [`er_style_tte_risktable_text()`](https://erplots.djnavarro.net/reference/er_style_tte_risktable.md),
  or the registered label `"text"` (see
  [`er_style_labels()`](https://erplots.djnavarro.net/reference/er_style_labels.md)).

- times:

  Numeric vector of time points at which to report the number at risk,
  or `NULL` (the default) to use `n_times` evenly spaced breaks spanning
  `object$time$limits`.

- n_times:

  Number of evenly spaced breaks to use when `times` is `NULL`. Must be
  a single whole number of at least 2. Ignored when `times` is supplied.
  Defaults to `6`.

- ...:

  Additional named arguments forwarded unchanged to `style` at build
  time (e.g.
  [`er_style_tte_risktable_text()`](https://erplots.djnavarro.net/reference/er_style_tte_risktable.md)'s
  `text_size`).

## Value

The input `object`, with the risktable layer added.

## Details

The same time breaks used for the number-at-risk grid also become the
curve panel's x-axis tick marks, so the two panels'
[`patchwork::wrap_plots()`](https://patchwork.data-imaginist.com/reference/wrap_plots.html)-collected
x-axis lines up exactly – see
[`er_tte_build()`](https://erplots.djnavarro.net/reference/er_tte_build.md).

## See also

[`er_tte()`](https://erplots.djnavarro.net/reference/er_tte.md),
[`er_style_tte_risktable_text()`](https://erplots.djnavarro.net/reference/er_style_tte_risktable.md)

## Examples

``` r
library(survival)
lung |>
  er_tte(time, status == 2) |>
  er_tte_add_curve() |>
  er_tte_add_risktable() |>
  plot()

```
