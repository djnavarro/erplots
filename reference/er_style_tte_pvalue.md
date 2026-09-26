# Log-rank test annotation builders for the TTE grammar

Builder functions for the `pvalue` layer
([`er_tte_add_pvalue()`](https://erplots.djnavarro.net/reference/er_tte_add_pvalue.md)),
drawing a corner-placed text/label annotation from a log-rank test
comparing survival across `stratify_by`'s levels.

## Usage

``` r
er_style_tte_pvalue_logrank(
  data,
  config,
  stratify,
  time,
  strata,
  theme,
  ...,
  inset = 0.05,
  label_size = NULL,
  label_colour = NULL,
  label_fill = NULL
)
```

## Arguments

- data:

  The original data frame (`object$data`).

- config:

  Configuration for the pvalue layer (populated by
  [`er_tte_add_pvalue()`](https://erplots.djnavarro.net/reference/er_tte_add_pvalue.md)):
  `config$p_value` (the log-rank test's p-value) and
  `config$corner_distance` (how uncrowded each panel corner is, relative
  to the plotted survival curve(s) – see
  [`er_style()`](https://erplots.djnavarro.net/reference/er_style.md)'s
  `?er_plot_add_summary()`-analogous corner-placement idiom).

- stratify:

  Logical: always `TRUE` here, since
  [`er_tte_add_pvalue()`](https://erplots.djnavarro.net/reference/er_tte_add_pvalue.md)
  requires a stratified `er_tte` object.

- time:

  `object$time` (`name`/`label`/`limits`).

- strata:

  `object$strata` (`var`/`label`).

- theme:

  `object$theme` – `theme$format_p` formats the p-value.

- ...:

  Additional named arguments forwarded from
  [`er_tte_add_pvalue()`](https://erplots.djnavarro.net/reference/er_tte_add_pvalue.md)'s
  own `...`.

- inset:

  Distance from the panel edge for the annotation label, as a fraction
  of the panel's width/height. Default `0.05`.

- label_size:

  Label text size. Defaults to `NULL`
  ([`ggplot2::geom_label()`](https://ggplot2.tidyverse.org/reference/geom_text.html)'s
  own default).

- label_colour:

  Label text colour. Defaults to `NULL`
  ([`ggplot2::geom_label()`](https://ggplot2.tidyverse.org/reference/geom_text.html)'s
  own default).

- label_fill:

  Label background fill. Defaults to `NULL`
  ([`ggplot2::geom_label()`](https://ggplot2.tidyverse.org/reference/geom_text.html)'s
  own default).

## Value

A geom, or a list of geoms.

## Details

`er_style_tte_pvalue_logrank()` places its annotation in whichever of
the panel's 4 corners is currently furthest from the survival curve(s),
using the same `(0, 1)`-rescaled corner-distance calculation
[`er_plot_add_summary()`](https://erplots.djnavarro.net/reference/er_plot_add_summary.md)'s
own p-value annotation uses to avoid a plot's raw data points – here
applied to the curve's own `(time, surv)` coordinates instead, since
there's no raw per-subject scatter in this grammar for the annotation to
avoid.

`er_style_tte_pvalue_logrank()` is tagged
`er_style_tag(fn, layer = "pvalue")`, so
[`er_tte_add_pvalue()`](https://erplots.djnavarro.net/reference/er_tte_add_pvalue.md)
errors informatively if handed a builder tagged for a different layer.

## See also

[`er_tte_add_pvalue()`](https://erplots.djnavarro.net/reference/er_tte_add_pvalue.md)

## Examples

``` r
library(survival)
lung |>
  transform(sex = factor(sex, labels = c("Male", "Female"))) |>
  er_tte(time, status == 2, stratify_by = sex) |>
  er_tte_add_curve() |>
  er_tte_add_pvalue(style = er_style_tte_pvalue_logrank, label_fill = "white") |>
  plot()

```
