# Build and render a time-to-event plot

Assembles the layers for a time-to-event plot object: a survival panel
that displays the curve, censor, summary, and model layers' geoms, when
present. When a risk table layer is also present the result contains two
panels stacked vertically.

## Usage

``` r
er_tte_build(object)
```

## Arguments

- object:

  Partially constructed plot (has S3 class `er_tte`).

## Value

The input `object`, with `object$output` (the composed plot – a single
ggplot2 object, or a patchwork object when the risktable layer is
present) populated.

## Details

The user does not typically invoke this function directly. Instead, it
is called automatically when
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) is called.

## See also

[`er_tte()`](https://erplots.djnavarro.net/reference/er_tte.md),
[`er_tte_add_curve()`](https://erplots.djnavarro.net/reference/er_tte_add_curve.md),
[`er_tte_add_censor()`](https://erplots.djnavarro.net/reference/er_tte_add_censor.md),
[`er_tte_add_risktable()`](https://erplots.djnavarro.net/reference/er_tte_add_risktable.md),
[`er_tte_add_summary()`](https://erplots.djnavarro.net/reference/er_tte_add_summary.md)
