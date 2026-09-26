# Number-at-risk builders for the TTE grammar

Builder functions for the `risktable` layer
([`er_tte_add_risktable()`](https://erplots.djnavarro.net/reference/er_tte_add_risktable.md)),
drawing a row of risk counts per stratum at a grid of time points.
Unlike every other TTE-grammar builder, this one's geoms are drawn into
their own patchwork panel below the curve, not onto the curve's panel
directly – see
[`er_tte_build()`](https://erplots.djnavarro.net/reference/er_tte_build.md).

## Usage

``` r
er_style_tte_risktable_text(
  data,
  config,
  stratify,
  time,
  strata,
  theme,
  ...,
  text_size = 3.5
)
```

## Arguments

- data:

  The original data frame (`object$data`).

- config:

  Configuration for the risktable layer (populated by
  [`er_tte_add_risktable()`](https://erplots.djnavarro.net/reference/er_tte_add_risktable.md)):
  `config$table` (`time`/`n_risk`/`strata`, one row per requested time
  break per stratum) and `config$breaks` (the time breaks themselves,
  also used as the curve panel's x-axis ticks).

- stratify:

  Logical: whether the fit is stratified (`!is.null(object$strata)`).

- time:

  `object$time` (`name`/`label`/`limits`).

- strata:

  `object$strata` (`var`/`label`), or `NULL` when unstratified.

- theme:

  `object$theme`.

- ...:

  Additional named arguments forwarded from
  [`er_tte_add_risktable()`](https://erplots.djnavarro.net/reference/er_tte_add_risktable.md)'s
  own `...`.

- text_size:

  Size of the risk-count text. Default `3.5`.

## Value

A geom, or a list of geoms.

## Details

Rows are ordered top-to-bottom in the same order strata first appear in
`config$table` (reversed, since a ggplot2 discrete y-axis plots its
first level at the bottom); an unstratified fit gets a single `"All"`
row.

`er_style_tte_risktable_text()` is tagged
`er_style_tag(fn, layer = "risktable")`, so
[`er_tte_add_risktable()`](https://erplots.djnavarro.net/reference/er_tte_add_risktable.md)
errors informatively if handed a builder tagged for a different layer.

## See also

[`er_tte_add_risktable()`](https://erplots.djnavarro.net/reference/er_tte_add_risktable.md)

## Examples

``` r
library(survival)
lung |>
  er_tte(time, status == 2) |>
  er_tte_add_curve() |>
  er_tte_add_risktable(style = er_style_tte_risktable_text, text_size = 4) |>
  plot()

```
