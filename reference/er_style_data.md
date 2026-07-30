# Data layer builders for exposure-response plots

Data layer builders for exposure-response plots

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
  bins = 30
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

- ...:

  Additional named arguments forwarded from
  [`er_plot_add_data()`](https://erplots.djnavarro.net/reference/er_plot_add_data.md)'s
  own `...`; see
  [`er_style()`](https://erplots.djnavarro.net/reference/er_style.md)'s
  "Passing extra arguments to a builder" section.

- box_width:

  Width of `er_style_data_boxjitter()`'s boxplot. Default `0.6`,
  matching the previous fixed value.

- box_alpha:

  Transparency of `er_style_data_boxjitter()`'s boxplot fill (`0`-`1`).
  Default `0.4`, matching the previous fixed value.

- show_outliers:

  Whether `er_style_data_boxjitter()`'s boxplot should draw its own
  outlier points (`geom_boxplot()`'s usual default), rather than
  suppressing them. Default `FALSE` (outliers hidden), matching the
  previous fixed behaviour – raw points are already shown via the jitter
  layer, so a boxplot's own outlier points are normally redundant.

- jitter_height:

  Vertical jitter applied to the raw points, in response units
  (`er_style_data_overlay()`/`er_style_data_boxjitter()` only). Defaults
  to `NULL`, which produces `0.015` for a binary response and `0`
  otherwise; for `er_style_data_boxjitter()`, `0.3` when stratified and
  `0.15` otherwise. An explicit value overrides this for both cases
  uniformly.

- jitter_size:

  Point size for `er_style_data_boxjitter()`'s jittered points. Default
  `1`, matching the previous fixed value.

- jitter_alpha:

  Point transparency for `er_style_data_boxjitter()`'s jittered points
  (`0`-`1`). Default `0.6`, matching the previous fixed value.

- alpha:

  Point transparency for `er_style_data_overlay()`'s raw points
  (`0`-`1`). Default `0.4`, matching the previous fixed value.

- size:

  Point size for `er_style_data_overlay()`'s raw points. Default `1`,
  matching the previous fixed value.

- bins:

  Number of hex bins along each axis for `er_style_data_hex()`'s
  [`ggplot2::geom_hex()`](https://ggplot2.tidyverse.org/reference/geom_hex.html).
  Default `30`, matching the previous fixed value.

## Value

A geom, or a list of geoms; see
[`er_style()`](https://erplots.djnavarro.net/reference/er_style.md).

## Details

Builders for the `data` layer
([`er_plot_add_data()`](https://erplots.djnavarro.net/reference/er_plot_add_data.md)),
which shows the raw observations alongside the fitted curve. Each
builder is tagged, via
[`er_style_tag()`](https://erplots.djnavarro.net/reference/er_style_tag.md),
with the *structural* family it belongs to: `er_style_data_overlay()`
(the default) and `er_style_data_hex()` use the `"overlay"` layout,
plotting directly on the model panel at the raw `(exposure, response)`
coordinates (points or, for `er_style_data_hex()`, a 2D density);
`er_style_data_boxjitter()` uses the `"panel"` layout (binary response
only), stacking boxplot-plus-jitter panels for responders/non-responders
below the base plot. See
[`er_style_tag()`](https://erplots.djnavarro.net/reference/er_style_tag.md)
and
[`er_plot_add_data()`](https://erplots.djnavarro.net/reference/er_plot_add_data.md)
for how this tag is used. All three built-in data builders are also
tagged `layer = "data"`, so
[`er_plot_add_data()`](https://erplots.djnavarro.net/reference/er_plot_add_data.md)
errors informatively if handed a builder tagged for a different layer.

See [`er_style()`](https://erplots.djnavarro.net/reference/er_style.md)
for the shared builder interface these functions implement, including
how to write a custom builder of your own.

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
