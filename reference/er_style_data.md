# Data layer builders for exposure-response plots

Builder functions for the `data` layer
([`er_plot_add_data()`](https://erplots.djnavarro.net/reference/er_plot_add_data.md)),
drawing raw observations either as an overlay on the main panel or as
separate boxplot/jitter panels.

## Usage

``` r
er_style_data_boxjitter(
  data,
  config,
  stratify,
  exposure,
  response,
  strata,
  theme,
  ...,
  box_width = 0.6,
  box_alpha = 0.4,
  show_outliers = FALSE,
  jitter_height = NULL,
  jitter_size = 1,
  jitter_alpha = 0.6
)

er_style_data_overlay(
  data,
  config,
  stratify,
  exposure,
  response,
  strata,
  theme,
  ...,
  jitter_height = NULL,
  alpha = 0.4,
  size = 1
)

er_style_data_hex(
  data,
  config,
  stratify,
  exposure,
  response,
  strata,
  theme,
  ...,
  bins = 30,
  alpha = 0.85
)
```

## Arguments

- data:

  The original data frame.

- config:

  Configuration for the specific plot.

- stratify:

  Logical: whether to stratify.

- exposure:

  Exposure variable.

- response:

  Response variable.

- strata:

  Stratification variable.

- theme:

  Theme components.

- ...:

  Additional named arguments forwarded from
  [`er_plot_add_data()`](https://erplots.djnavarro.net/reference/er_plot_add_data.md)'s
  own `...`. `er_style_data_overlay()`/`er_style_data_boxjitter()` read
  a `seed` from here (via `config$seed`, `NULL` when not supplied) and
  pass it to
  [`ggplot2::position_jitter()`](https://ggplot2.tidyverse.org/reference/position_jitter.html),
  letting a caller make the jitter reproducible across repeated
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html) calls on the
  same object; with no `seed`, each render draws a fresh jitter, as for
  any other jittered geom.

- box_width:

  Width of `er_style_data_boxjitter()`'s boxplot.

- box_alpha:

  Transparency of `er_style_data_boxjitter()`'s boxplot fill.

- show_outliers:

  Logical: whether `er_style_data_boxjitter()` draws outlier points.

- jitter_height:

  Vertical jitter applied to raw points.

- jitter_size:

  Point size for `er_style_data_boxjitter()`'s jittered points.

- jitter_alpha:

  Transparency of `er_style_data_boxjitter()`'s jittered points.

- alpha:

  Point transparency for `er_style_data_overlay()`; fill transparency
  for `er_style_data_hex()`.

- size:

  Point size for `er_style_data_overlay()`.

- bins:

  Number of hex bins for `er_style_data_hex()`.

## Value

A geom, or a list of geoms; see
[`er_style()`](https://erplots.djnavarro.net/reference/er_style.md).

## Details

Builders for the `data` layer
([`er_plot_add_data()`](https://erplots.djnavarro.net/reference/er_plot_add_data.md))
are tagged with the structural family they belong to via
[`er_style_tag()`](https://erplots.djnavarro.net/reference/er_style_tag.md).
`er_style_data_overlay()` and `er_style_data_hex()` use the overlay
layout, drawing in the main panel; `er_style_data_boxjitter()` uses the
panel layout and is binary-response only. All built-in data builders are
also tagged `layer = "data"`, so
[`er_plot_add_data()`](https://erplots.djnavarro.net/reference/er_plot_add_data.md)
errors if given a builder tagged for another layer.

`er_style_data_hex()` defaults to a light-grey-to-navy (`"grey90"` to
`"#132B43"`) fill gradient, so a cell's fill fades toward the panel
background as its count approaches zero rather than starting at
ggplot2's own default mid-intensity blue. Override it with
`er_plot_theme(fill_continuous = ...)`.

Because its geoms cover the whole panel, `er_style_data_hex()` is tagged
`er_style_tag(fn, zorder = "background")` (see
[`er_style_tag()`](https://erplots.djnavarro.net/reference/er_style_tag.md)),
so it's drawn before the model/summary/quantile layers rather than on
top of them; its default `alpha = 0.85` gives those layers a little
extra visibility through even a densely populated hex cell.

See [`er_style()`](https://erplots.djnavarro.net/reference/er_style.md)
for the shared builder interface these functions implement.

## See also

[`er_style()`](https://erplots.djnavarro.net/reference/er_style.md),
[`er_style_tag()`](https://erplots.djnavarro.net/reference/er_style_tag.md)

## Examples

``` r
if (requireNamespace("erglm", quietly = TRUE)) {
  library(erglm)
  mod2 <- erglm_model(ae2 ~ aucss + sex, erglm_data, family = binomial())

  # er_style_data_overlay(): the default, raw points on the main panel
  erglm_data |>
    er_plot(aucss, ae2, stratify_by = sex) |>
    er_plot_add_model(mod2) |>
    er_plot_add_data(style = er_style_data_overlay) |>
    plot()

  # er_style_data_boxjitter(): binary-response only, boxplot + jitter
  # panels above/below the main panel instead of an overlay
  erglm_data |>
    er_plot(aucss, ae2, stratify_by = sex) |>
    er_plot_add_model(mod2) |>
    er_plot_add_data(style = er_style_data_boxjitter) |>
    plot()

  # overriding a builder's own visual defaults, e.g. larger/more
  # opaque points and a wider jitter
  erglm_data |>
    er_plot(aucss, ae2, stratify_by = sex) |>
    er_plot_add_model(mod2) |>
    er_plot_add_data(
      style = er_style_data_overlay,
      jitter_height = 0.1,
      alpha = 0.7,
      size = 2
    ) |>
    plot()
}



```
