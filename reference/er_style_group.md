# Group panel builders for exposure-response plots

Builder functions for the `group` layer
([`er_plot_add_groups()`](https://erplots.djnavarro.net/reference/er_plot_add_groups.md)),
drawing the exposure distribution for a grouping variable as a boxplot,
violin, or histogram panel.

## Usage

``` r
er_style_group_boxplot(
  data,
  config,
  stratify,
  exposure,
  response,
  strata,
  theme,
  alpha = 0.5,
  show_outliers = TRUE,
  ...
)

er_style_group_histogram(
  data,
  config,
  stratify,
  exposure,
  response,
  strata,
  theme,
  bins = 30,
  alpha = NULL,
  ...
)

er_style_group_violin(
  data,
  config,
  stratify,
  exposure,
  response,
  strata,
  theme,
  alpha = 0.5,
  quantiles = NULL,
  quantile_linetype = "solid",
  ...
)

er_style_group_linerange(
  data,
  config,
  stratify,
  exposure,
  response,
  strata,
  theme,
  size = 1,
  inner_range = c(0.25, 0.75),
  outer_range = c(0.05, 0.95),
  alpha_dot = 1,
  alpha_inner = 0.8,
  alpha_outer = 0.4,
  ...
)

er_style_group_boxjitter(
  data,
  config,
  stratify,
  exposure,
  response,
  strata,
  theme,
  alpha = 0.5,
  jitter_height = 0.15,
  jitter_size = 1,
  jitter_alpha = 0.6,
  ...
)

er_style_group_violinjitter(
  data,
  config,
  stratify,
  exposure,
  response,
  strata,
  theme,
  alpha = 0.5,
  quantiles = NULL,
  quantile_linetype = "solid",
  jitter_height = 0.15,
  jitter_size = 1,
  jitter_alpha = 0.6,
  ...
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

- alpha:

  Transparency of the geom.

- show_outliers:

  Logical: whether `er_style_group_boxplot()` draws the boxplot's own
  outlier points. Defaults to `TRUE`; `er_style_group_boxjitter()` sets
  this to `FALSE` when it wraps this builder, since its own jittered
  points already show every raw value, outliers included.

- ...:

  Additional named arguments forwarded from
  [`er_plot_add_groups()`](https://erplots.djnavarro.net/reference/er_plot_add_groups.md)'s
  own `...`.
  `er_style_group_boxjitter()`/`er_style_group_violinjitter()` read a
  `seed` from here (`NULL` when not supplied) and use it to scope (via
  [`withr::with_seed()`](https://withr.r-lib.org/reference/with_seed.html))
  the vertical jitter draw, letting a caller make the jitter
  reproducible across repeated
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html) calls on the
  same object – the same opt-in-only mechanism
  [`er_style_data_overlay()`](https://erplots.djnavarro.net/reference/er_style_data.md)/[`er_style_data_boxjitter()`](https://erplots.djnavarro.net/reference/er_style_data.md)
  use for the data layer (see
  [`er_style_data()`](https://erplots.djnavarro.net/reference/er_style_data.md));
  with no `seed`, each render draws a fresh jitter.

- bins:

  Number of histogram bins for `er_style_group_histogram()`.

- quantiles, quantile_linetype:

  Violin quantile positions and linetype for `er_style_group_violin()`.

- size:

  Overall size multiplier for `er_style_group_linerange()`'s dot and
  lines.

- inner_range, outer_range:

  Quantile probabilities (length 2) for `er_style_group_linerange()`'s
  thick and thin lines.

- alpha_dot, alpha_inner, alpha_outer:

  Per-part transparency for `er_style_group_linerange()`'s dot, inner
  line, and outer line.

- jitter_height, jitter_size, jitter_alpha:

  Vertical jitter, point size, and transparency for
  `er_style_group_boxjitter()`/`er_style_group_violinjitter()`'s
  overlaid points.

## Value

A geom, or a list of geoms; see
[`er_style()`](https://erplots.djnavarro.net/reference/er_style.md).

## Details

Builders for the `group` layer
([`er_plot_add_groups()`](https://erplots.djnavarro.net/reference/er_plot_add_groups.md))
draw exposure distributions for grouping variables.
`er_style_group_boxplot()` and `er_style_group_violin()` put group
levels on the y-axis; `er_style_group_histogram()` puts them on facet
strips and frees the y-axis for counts; `er_style_group_linerange()`
also puts group levels on the y-axis, summarising each level's exposure
distribution as a median dot flanked by an inner-range and outer-range
line rather than a full boxplot/violin shape.
`er_style_group_boxjitter()`/`er_style_group_violinjitter()` are thin
wrappers around `er_style_group_boxplot()`/`er_style_group_violin()`
that additionally overlay jittered raw exposure values (vertical jitter
only – exposure position on the x-axis is never perturbed), the same
idea
[`er_style_data_boxjitter()`](https://erplots.djnavarro.net/reference/er_style_data.md)
applies to the data layer. All built-in group builders are tagged
`layer = "group"`, so
[`er_plot_add_groups()`](https://erplots.djnavarro.net/reference/er_plot_add_groups.md)
errors if given one tagged for another layer.

See [`er_style()`](https://erplots.djnavarro.net/reference/er_style.md)
for the shared builder interface these functions implement.

## See also

[`er_style()`](https://erplots.djnavarro.net/reference/er_style.md)

## Examples

``` r
if (requireNamespace("erglm", quietly = TRUE)) {
  library(erglm)
  mod <- erglm_model(ae1 ~ aucss, erglm_data, family = binomial())

  # er_style_group_boxplot(): the default
  erglm_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(mod) |>
    er_plot_add_groups(aucss, style = er_style_group_boxplot) |>
    plot()

  # er_style_group_violin(): a violin instead of a boxplot
  erglm_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(mod) |>
    er_plot_add_groups(aucss, style = er_style_group_violin) |>
    plot()

  # er_style_group_histogram(): group levels on facet strips, with
  # the y-axis freed for counts
  erglm_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(mod) |>
    er_plot_add_groups(aucss, style = er_style_group_histogram) |>
    plot()

  # er_style_group_linerange(): median dot + inner/outer range lines,
  # instead of a full boxplot/violin shape
  erglm_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(mod) |>
    er_plot_add_groups(aucss, style = er_style_group_linerange) |>
    plot()

  # er_style_group_boxjitter(): the boxplot, with jittered raw
  # exposure values overlaid on top
  erglm_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(mod) |>
    er_plot_add_groups(aucss, style = er_style_group_boxjitter) |>
    plot()

  # er_style_group_violinjitter(): the violin, with jittered raw
  # exposure values overlaid on top
  erglm_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(mod) |>
    er_plot_add_groups(aucss, style = er_style_group_violinjitter) |>
    plot()
}






```
