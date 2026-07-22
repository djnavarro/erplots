# Summary annotation builders for exposure-response plots

Summary annotation builders for exposure-response plots

## Usage

``` r
er_style_summary_pvalue(
  data,
  config,
  stratify,
  exposure,
  response,
  strata,
  theme
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

- theme:

  Theme components

## Value

A geom, or a list of geoms; see
[`er_style()`](https://erplots.djnavarro.net/reference/er_style.md).

## Details

Builders for the `summary_style` argument of
[`er_plot_add_model()`](https://erplots.djnavarro.net/reference/er_plot_add_model.md),
which annotate the model panel with a summary statistic rather than
drawing the curve itself: `er_style_summary_pvalue()` (the default)
places a formatted p-value in whichever corner of the panel is furthest
from the data. It's tagged `er_style_tag(fn, layer = "summary")`, so
[`er_plot_add_model()`](https://erplots.djnavarro.net/reference/er_plot_add_model.md)
errors informatively if it's passed as `style` (the curve/ribbon
argument) rather than `summary_style`.

See [`er_style()`](https://erplots.djnavarro.net/reference/er_style.md)
for the shared builder interface these functions implement, including
how to write a custom builder of your own.

## See also

[`er_style()`](https://erplots.djnavarro.net/reference/er_style.md)
