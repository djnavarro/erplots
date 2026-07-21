# Data layer builders for exposure-response plots

Data layer builders for exposure-response plots

## Usage

``` r
er_builder_data_boxjitter(
  data,
  config,
  stratify,
  exposure,
  response,
  strata,
  style
)

er_builder_data_overlay(
  data,
  config,
  stratify,
  exposure,
  response,
  strata,
  style
)

er_builder_data_hex(data, config, stratify, exposure, response, strata, style)
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

Builders for the `data` layer
([`er_plot_add_data()`](https://erplots.djnavarro.net/reference/er_plot_add_data.md)),
which shows the raw observations alongside the fitted curve. Each
builder is tagged, via
[`er_builder_tag()`](https://erplots.djnavarro.net/reference/er_builder_tag.md),
with the *structural* family it belongs to: `er_builder_data_overlay()`
(the default) and `er_builder_data_hex()` use the `"overlay"` layout,
plotting directly on the model panel at the raw `(exposure, response)`
coordinates (points or, for `er_builder_data_hex()`, a 2D density);
`er_builder_data_boxjitter()` uses the `"panel"` layout (binary response
only), stacking boxplot-plus-jitter panels for responders/non-responders
below the base plot. See
[`er_builder_tag()`](https://erplots.djnavarro.net/reference/er_builder_tag.md)
and
[`er_plot_add_data()`](https://erplots.djnavarro.net/reference/er_plot_add_data.md)
for how this tag is used. All three built-in data builders are also
tagged `layer = "data"`, so
[`er_plot_add_data()`](https://erplots.djnavarro.net/reference/er_plot_add_data.md)
errors informatively if handed a builder tagged for a different layer.

See
[`er_builder()`](https://erplots.djnavarro.net/reference/er_builder.md)
for the shared builder interface these functions implement, including
how to write a custom builder of your own.

## See also

[`er_builder()`](https://erplots.djnavarro.net/reference/er_builder.md),
[`er_builder_tag()`](https://erplots.djnavarro.net/reference/er_builder_tag.md)
