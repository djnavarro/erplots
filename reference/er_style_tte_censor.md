# Censoring-mark builders for the TTE grammar

Builder functions for the `censor` layer
([`er_tte_add_censor()`](https://erplots.djnavarro.net/reference/er_tte_add_censor.md)),
marking each censoring time directly on the Kaplan-Meier curve. See
[`er_style_tte()`](https://erplots.djnavarro.net/reference/er_style_tte.md)
for the shared interface every TTE-grammar builder implements.

## Usage

``` r
er_style_tte_censor_ticks(
  data,
  config,
  stratify,
  time,
  strata,
  theme,
  ...,
  shape = 3,
  size = 2,
  stroke = 0.75
)
```

## Arguments

- data:

  The original data frame (`object$data`).

- config:

  Configuration for the censor layer (populated by
  [`er_tte_add_censor()`](https://erplots.djnavarro.net/reference/er_tte_add_censor.md)):
  `config$table` (the subset of the tidy KM table where `n_censor > 0`,
  with a `strata` column when stratified).

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
  [`er_tte_add_censor()`](https://erplots.djnavarro.net/reference/er_tte_add_censor.md)'s
  own `...`.

- shape:

  Point shape for a censoring mark. Default `3` (a plus sign), the
  conventional Kaplan-Meier censoring glyph.

- size:

  Point size. Default `2`.

- stroke:

  Point stroke width. Default `0.75`.

## Value

A geom, or a list of geoms.

## Details

A censoring-only row of the KM table (`n_censor > 0`, `n_event == 0`)
carries the survival value the curve already had going into that time –
Kaplan-Meier survival only drops at an *event* time – so a mark drawn at
`(time, surv)` lands exactly on the step curve without any extra lookup.

Stratified colour maps to `config$table`'s own `strata` column, the same
already-cleaned stratum label
[`er_style_tte_curve_km()`](https://erplots.djnavarro.net/reference/er_style_tte_curve.md)
uses, so a censoring mark takes on the colour of the curve it sits on.
The marks never contribute their own legend entry
(`show.legend = FALSE`) – the curve layer's legend already identifies
each stratum.

`er_style_tte_censor_ticks()` is tagged
`er_style_tag(fn, layer = "censor")`, so
[`er_tte_add_censor()`](https://erplots.djnavarro.net/reference/er_tte_add_censor.md)
errors informatively if handed a builder tagged for a different layer.

## See also

[`er_tte_add_censor()`](https://erplots.djnavarro.net/reference/er_tte_add_censor.md),
[`er_style_tte()`](https://erplots.djnavarro.net/reference/er_style_tte.md)

## Examples

``` r
library(survival)
lung |>
  er_tte(time, status == 2) |>
  er_tte_add_curve() |>
  er_tte_add_censor(style = er_style_tte_censor_ticks, shape = 124, size = 3) |>
  plot()

```
