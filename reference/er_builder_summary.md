# Summary annotation builders for exposure-response plots

Summary annotation builders for exposure-response plots

## Usage

``` r
er_builder_summary_pvalue(
  data,
  config,
  stratify,
  exposure,
  response,
  strata,
  style
)
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
[`er_builder()`](https://erplots.djnavarro.net/reference/er_builder.md).

## Details

Builders for the `summary_builder` argument of
[`er_plot_add_model()`](https://erplots.djnavarro.net/reference/er_plot_add_model.md),
which annotate the model panel with a summary statistic rather than
drawing the curve itself: `er_builder_summary_pvalue()` (the default)
places a formatted p-value in whichever corner of the panel is furthest
from the data. It's tagged `er_builder_tag(fn, layer = "summary")`, so
[`er_plot_add_model()`](https://erplots.djnavarro.net/reference/er_plot_add_model.md)
errors informatively if it's passed as `builder` (the curve/ribbon
argument) rather than `summary_builder`.

See
[`er_builder()`](https://erplots.djnavarro.net/reference/er_builder.md)
for the shared builder interface these functions implement, including
how to write a custom builder of your own.

## See also

[`er_builder()`](https://erplots.djnavarro.net/reference/er_builder.md)
