# Data layer builders for exposure-response plots

Data layer builders for exposure-response plots

## Usage

``` r
build_data_boxjitter(data, config, stratify, exposure, response, strata, style)

build_data_overlay(data, config, stratify, exposure, response, strata, style)

build_data_hex(data, config, stratify, exposure, response, strata, style)
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
[`er_partial()`](https://erplots.djnavarro.net/reference/er_partial.md).

## Details

Builders for the `data` layer
([`er_plot_show_data()`](https://erplots.djnavarro.net/reference/er_plot_show_data.md)),
which shows the raw observations alongside the fitted curve. Each
builder is tagged, via
[`er_layout()`](https://erplots.djnavarro.net/reference/er_layout.md),
with the *structural* family it belongs to: `build_data_overlay()` (the
default) and `build_data_hex()` use the `"overlay"` layout, plotting
directly on the model panel at the raw `(exposure, response)`
coordinates (points or, for `build_data_hex()`, a 2D density);
`build_data_boxjitter()` uses the `"panel"` layout (binary response
only), stacking boxplot-plus-jitter panels for responders/non-responders
below the base plot. See
[`er_layout()`](https://erplots.djnavarro.net/reference/er_layout.md)
and
[`er_plot_show_data()`](https://erplots.djnavarro.net/reference/er_plot_show_data.md)
for how this tag is used.

See
[`er_partial()`](https://erplots.djnavarro.net/reference/er_partial.md)
for the shared builder interface these functions implement, including
how to write a custom builder of your own.

## See also

[`er_partial()`](https://erplots.djnavarro.net/reference/er_partial.md),
[`er_layout()`](https://erplots.djnavarro.net/reference/er_layout.md)
