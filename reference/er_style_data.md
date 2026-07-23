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
  ...
)

er_style_data_overlay(
  data,
  config,
  stratify,
  exposure,
  response,
  strata,
  theme,
  ...
)

er_style_data_hex(
  data,
  config,
  stratify,
  exposure,
  response,
  strata,
  theme,
  ...
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
}


```
