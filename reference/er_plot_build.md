# Build and render an `er_plot` object

Assembles the layers into ggplot2 objects, applies shared theming and
legend deduplication across layers, and composes the final output with
patchwork.

## Usage

``` r
er_plot_build(object)
```

## Arguments

- object:

  Partially constructed plot (has S3 class `er_plot`).

## Value

The input `object`, with `object$plot` (per-layer ggplot2 objects) and
`object$output` (the final composed plot) populated.

## Details

The user does not typically invoke this function directly. Instead, it
is called automatically when
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) is called.

## See also

[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md)
