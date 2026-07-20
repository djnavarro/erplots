# Partial builders for exposure-response plots

Partial builders for exposure-response plots

## Usage

``` r
build_data_jitter(data, config, stratify, exposure, response, strata, style)

build_data_overlay(data, config, stratify, exposure, response, strata, style)

build_data_color(data, config, stratify, exposure, response, strata, style)

build_group_boxplot(data, config, stratify, exposure, response, strata, style)

build_group_violin(data, config, stratify, exposure, response, strata, style)

build_model_ribbonline(
  data,
  config,
  stratify,
  exposure,
  response,
  strata,
  style
)

build_model_spaghetti(
  data,
  config,
  stratify,
  exposure,
  response,
  strata,
  style
)

build_quantile_errorbar(
  data,
  config,
  stratify,
  exposure,
  response,
  strata,
  style
)

build_summary_pvalue(data, config, stratify, exposure, response, strata, style)
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

A geom, or a list of geoms. More precisely, a list of objects that can
be added to a ggplot2 plot. The expectation is that these objects will
be added to a partially-constructed plot which, at a minimum, already
has the base theme applied. For "model", "summary", "quantile", and
"overlay", the pieces will be added to a plot that already has a coord
that sets the axis limits (the base plot; see `.build_overlay_geoms()`).
For the "data" (jitter/ color panel) and "group" plots, the plot object
does not yet have a coord. The expectation, however, is that the builder
will supply an x-axis limit that is consistent with the base plot. That
is, since all component plots use the exposure variable for the x-axis,
they should use the values stored in `exposure$limits` tp set the x-axis
limits.

All of the builders above feed a **singleton** layer: `model`,
`summary`, `quantile`, `data`, and `overlay` each occupy a single named
slot (`object$part$model`, `object$part$data`, etc.), so calling the
corresponding `er_plot_show_*()` function again overwrites the slot
rather than combining builders. `group` (`build_group_boxplot()`/
`build_group_violin()`) is the one **additive** exception – each call to
[`er_plot_show_groups()`](https://erplots.djnavarro.net/reference/er_plot_show_groups.md)
adds another named entry rather than replacing the previous one. See
[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md)'s
"Layers are either singleton or additive" section for the full
discussion, including the one flagged future exception (an additive
`model` layer, for overlaying two fitted curves).

The `data` slot has two mutually exclusive builders, selected by
response type rather than by name: `build_data_jitter()` for a binary
response (color, when mapped, always means strata) and
`build_data_color()` for a continuous/count response (color always means
the response value itself). Because `build_data_color()`'s color
aesthetic is already spoken for, `config$color_role` (set by
`.part_data()`, consulted by `.polish_labels()`/`.polish_legends()` in
`R/er-plot-compose.R`) tags which meaning applies – `"strata"` for
`build_data_jitter()`, `"response"` for `build_data_color()` – so the
composition machinery knows whether a builder's legend is the shared
strata legend or a standalone response colorbar. `build_data_overlay()`
needs no such tag: its color aesthetic (when stratified) is always
strata, since the response is already shown via y-position, so it shares
the base plot's own strata legend directly. See
[`er_plot_show_data()`](https://erplots.djnavarro.net/reference/er_plot_show_data.md)
for the user-facing version of this rule.

## Details

Things we can have partials for:

- model

- summary

- quantile

- data

- overlay

- group

Arguments are standardised to allow users to write their own as needed
