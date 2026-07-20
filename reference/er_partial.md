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

## Details

Things we can have partials for:

- model

- summary

- quantile

- data

- overlay

- group

Arguments are standardised to allow users to write their own as needed
