# Build and render an `er_plot` object

Assembles whichever layers have been added (via the `er_plot_show_*()`
functions) into ggplot2 objects, applies shared theming and legend
deduplication across layers, and composes the final output with
patchwork. Usually invoked indirectly, via
[`plot()`](https://rdrr.io/r/graphics/plot.default.html)/[`print()`](https://rdrr.io/r/base/print.html)
on an `er_plot` object, rather than called directly.

## Usage

``` r
er_plot_build(object)
```

## Arguments

- object:

  Partially constructed plot (has S3 class `er_plot`)

## Value

The input `object`, with `object$plot` (per-layer ggplot2 objects) and
`object$output` (the final composed plot) populated

## See also

[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md)
