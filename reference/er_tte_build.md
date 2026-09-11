# Build and render an `er_tte` object

Assembles the layers into a ggplot2 object: a blank axes-only survival
panel (time x-axis, survival probability y-axis), plus the curve,
censor, pvalue, and model layers' geoms, when present
([`er_tte_add_curve()`](https://erplots.djnavarro.net/reference/er_tte_add_curve.md),
[`er_tte_add_censor()`](https://erplots.djnavarro.net/reference/er_tte_add_censor.md),
[`er_tte_add_pvalue()`](https://erplots.djnavarro.net/reference/er_tte_add_pvalue.md),
[`er_tte_add_model()`](https://erplots.djnavarro.net/reference/er_tte_add_model.md)).
When a risktable layer is also present
([`er_tte_add_risktable()`](https://erplots.djnavarro.net/reference/er_tte_add_risktable.md)),
the result is instead a
[`patchwork::wrap_plots()`](https://patchwork.data-imaginist.com/reference/wrap_plots.html)
composition of two panels – the curve panel described above, stacked
above a number-at-risk panel – with a shared,
[`patchwork::wrap_plots()`](https://patchwork.data-imaginist.com/reference/wrap_plots.html)-collected
x-axis.

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
[`er_tte_add_pvalue()`](https://erplots.djnavarro.net/reference/er_tte_add_pvalue.md)
