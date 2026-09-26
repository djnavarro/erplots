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
  text_size = 3.5,
  show_percent = FALSE
)
```

## Arguments

- data:

  The original data frame (`object$data`).

- config:

  Configuration for the risktable layer (populated by
  [`er_tte_add_risktable()`](https://erplots.djnavarro.net/reference/er_tte_add_risktable.md)):
  `config$table` (`time`/`n_risk`/`strata`/ `n_baseline` – the stratum's
  time-zero number at risk, used by `show_percent` below – one row per
  requested time break per stratum) and `config$breaks` (the time breaks
  themselves, also used as the curve panel's x-axis ticks).

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

- show_percent:

  Whether to append each break's `n_risk` as a percentage of that
  stratum's own baseline (time-zero) size, formatted via
  [`er_tte_theme()`](https://erplots.djnavarro.net/reference/er_tte_theme.md)'s
  `format_percent`. Default `FALSE` (a bare count, the previous
  behaviour).

## Value

A geom, or a list of geoms.

## Details

See
[`er_style_tte()`](https://erplots.djnavarro.net/reference/er_style_tte.md)
for the shared interface every TTE-grammar builder implements.

Rows are ordered top-to-bottom in the same order strata first appear in
`config$table` (reversed, since a ggplot2 discrete y-axis plots its
first level at the bottom); an unstratified fit gets a single `"All"`
row.

`show_percent = TRUE` displays `"<n_risk> (<percent>%)"` instead of a
bare `n_risk`, using
[`er_tte_theme()`](https://erplots.djnavarro.net/reference/er_tte_theme.md)'s
`format_percent` (defaulting to `scales::label_percent(accuracy = 1)`)
to format `n_risk / n_baseline` – see `config` above for where
`n_baseline` comes from.

`er_style_tte_risktable_text()` is tagged
`er_style_tag(fn, layer = "risktable")`, so
[`er_tte_add_risktable()`](https://erplots.djnavarro.net/reference/er_tte_add_risktable.md)
errors informatively if handed a builder tagged for a different layer.

## See also

[`er_tte_add_risktable()`](https://erplots.djnavarro.net/reference/er_tte_add_risktable.md),
[`er_style_tte()`](https://erplots.djnavarro.net/reference/er_style_tte.md)

## Examples

``` r
library(survival)
lung |>
  er_tte(time, status == 2) |>
  er_tte_add_curve() |>
  er_tte_add_risktable(style = er_style_tte_risktable_text, text_size = 4) |>
  plot()

```
