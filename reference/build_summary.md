# Summary annotation builders for exposure-response plots

Summary annotation builders for exposure-response plots

## Usage

``` r
build_summary_pvalue(data, config, stratify, exposure, response, strata, style)
```

## Arguments

- data:

  The original data frame

- config:

  Configuration for the specific plot

- stratify:

  Logical indicating whether to stratify

- exposure:

  Exposure variable

- response:

  Response variable

- strata:

  Stratification variable

- style:

  Style components

## Value

A geom, or a list of geoms; see
[`er_partial()`](https://erplots.djnavarro.net/reference/er_partial.md).

## Details

Builders for the `summary_builder` argument of
[`er_plot_show_model()`](https://erplots.djnavarro.net/reference/er_plot_show_model.md),
which annotate the model panel with a summary statistic rather than
drawing the curve itself: `build_summary_pvalue()` (the default) places
a formatted p-value in whichever corner of the panel is furthest from
the data.

See
[`er_partial()`](https://erplots.djnavarro.net/reference/er_partial.md)
for the shared builder interface these functions implement, including
how to write a custom builder of your own.

## See also

[`er_partial()`](https://erplots.djnavarro.net/reference/er_partial.md)
