# Group panel builders for exposure-response plots

Group panel builders for exposure-response plots

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

- alpha:

  Transparency of the geom. For `er_style_group_boxplot()` and
  `er_style_group_violin()`, a single number; default `0.5`. For
  `er_style_group_histogram()`, `NULL` (default: `0.5` when stratified,
  `0.8` when unstratified, matching the previous conditional behaviour)
  or an explicit number that overrides that conditional default.

- ...:

  Additional named arguments forwarded from
  [`er_plot_add_groups()`](https://erplots.djnavarro.net/reference/er_plot_add_groups.md)'s
  own `...`; see
  [`er_style()`](https://erplots.djnavarro.net/reference/er_style.md)'s
  "Passing extra arguments to a builder" section.

- bins:

  (for `er_style_group_histogram()` only) Number of histogram bins,
  passed to
  [`ggplot2::geom_histogram()`](https://ggplot2.tidyverse.org/reference/geom_histogram.html)'s
  own `bins`. Default `30`.

- quantiles, quantile_linetype:

  (for `er_style_group_violin()` only) Probabilities at which to draw
  quantile lines on the violin, passed to
  [`ggplot2::geom_violin()`](https://ggplot2.tidyverse.org/reference/geom_violin.html)'s
  own `draw_quantiles`; and the linetype for those lines, passed to
  `quantile.linetype`. Default `NULL` (no lines drawn) and `"solid"`
  respectively.

## Value

A geom, or a list of geoms; see
[`er_style()`](https://erplots.djnavarro.net/reference/er_style.md).

## Details

Builders for the `group` layer
([`er_plot_add_groups()`](https://erplots.djnavarro.net/reference/er_plot_add_groups.md)),
which draws the exposure distribution for a grouping variable (e.g.
treatment arm) below the main panel: `er_style_group_boxplot()` (the
default), `er_style_group_violin()`, and `er_style_group_histogram()`.
The first two put the group levels on the y-axis;
`er_style_group_histogram()` instead puts them on facet strips
(`facet_grid(rows = vars(lvl), switch = "y")`) and frees the y-axis for
counts. All three are tagged `er_style_tag(fn, layer = "group")`, so
[`er_plot_add_groups()`](https://erplots.djnavarro.net/reference/er_plot_add_groups.md)
errors informatively if handed a builder tagged for a different layer.

See [`er_style()`](https://erplots.djnavarro.net/reference/er_style.md)
for the shared builder interface these functions implement, including
how to write a custom builder of your own.

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
}



```
