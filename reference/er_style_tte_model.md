# Model-curve builders for the TTE grammar

Builder functions for the `model` layer
([`er_tte_add_model()`](https://erplots.djnavarro.net/reference/er_tte_add_model.md)),
drawing a fitted parametric `S(t)` curve with an optional uncertainty
band. See
[`er_style_tte()`](https://erplots.djnavarro.net/reference/er_style_tte.md)
for the shared interface every TTE-grammar builder implements.

## Usage

``` r
er_style_tte_model_line(
  data,
  config,
  stratify,
  time,
  strata,
  theme,
  ...,
  show_ci = TRUE,
  ribbon_alpha = 0.15,
  linewidth = 1
)
```

## Arguments

- data:

  The original data frame (`object$data`).

- config:

  Configuration for the model layer (populated by
  [`er_tte_add_model()`](https://erplots.djnavarro.net/reference/er_tte_add_model.md)):
  `config$predictions` (the prediction tibble from
  [`er_predict_survival()`](https://erplots.djnavarro.net/reference/er_model_interface.md),
  with `time`/`fit_survival`/ `ci_lower`/`ci_upper` columns),
  `config$time_grid`, `config$conf_level`.

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
  [`er_tte_add_model()`](https://erplots.djnavarro.net/reference/er_tte_add_model.md)'s
  own `...`.

- show_ci:

  Whether to draw the confidence band. Default `TRUE`.

- ribbon_alpha:

  Transparency of the confidence band (`0`-`1`). Default `0.15`.

- linewidth:

  Width of the curve's line. Default `1`.

## Value

A geom, or a list of geoms.

## Details

Unlike
[`er_style_tte_curve_km()`](https://erplots.djnavarro.net/reference/er_style_tte_curve.md)'s
Kaplan-Meier step curve, `config$predictions` is a smooth prediction
grid (one row per `newdata` row x `config$time_grid` value), so
`er_style_tte_model_line()` draws an ordinary
[`ggplot2::geom_line()`](https://ggplot2.tidyverse.org/reference/geom_path.html)/[`ggplot2::geom_ribbon()`](https://ggplot2.tidyverse.org/reference/geom_ribbon.html)
pair rather than a step function.

Stratified colour/fill both map to `config$predictions`'s own strata
column (named after `strata$var`) rather than a fixed name – unlike
[`er_style_tte_curve_km()`](https://erplots.djnavarro.net/reference/er_style_tte_curve.md),
which always reads a column literally named `strata` (the tidied
Kaplan-Meier table's own naming).
[`er_tte_build()`](https://erplots.djnavarro.net/reference/er_tte_build.md)
still retitles the resulting legend with `strata$label` afterwards.

`er_style_tte_model_line()` is tagged
`er_style_tag(fn, layer = "tte_model")` – distinct from
[`er_plot_add_model()`](https://erplots.djnavarro.net/reference/er_plot_add_model.md)'s
own `"model"` tag, since the two grammars' model builders share no
signature or `config` contents – so
[`er_tte_add_model()`](https://erplots.djnavarro.net/reference/er_tte_add_model.md)
errors informatively if handed a builder tagged for a different layer
(including
[`er_plot_add_model()`](https://erplots.djnavarro.net/reference/er_plot_add_model.md)'s
own builders).

## See also

[`er_tte_add_model()`](https://erplots.djnavarro.net/reference/er_tte_add_model.md),
[`er_style_tte_curve_km()`](https://erplots.djnavarro.net/reference/er_style_tte_curve.md),
[`er_style_tte()`](https://erplots.djnavarro.net/reference/er_style_tte.md)

## Examples

``` r
if (requireNamespace("ertte", quietly = TRUE)) {
  library(survival)
  library(ertte)
  mod <- ertte_aft(Surv(time, status == 2) ~ age, lung)

  lung |>
    er_tte(time, status == 2) |>
    er_tte_add_curve() |>
    er_tte_add_model(mod, style = er_style_tte_model_line, ribbon_alpha = 0.3) |>
    plot()
}

```
