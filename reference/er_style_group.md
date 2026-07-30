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

- ...:

  Additional named arguments forwarded from
  [`er_plot_add_groups()`](https://erplots.djnavarro.net/reference/er_plot_add_groups.md)'s
  own `...`.

- bins:

  Number of histogram bins for `er_style_group_histogram()`.

- quantiles, quantile_linetype:

  Violin quantile positions and linetype for `er_style_group_violin()`.

## Value

A geom, or a list of geoms; see
[`er_style()`](https://erplots.djnavarro.net/reference/er_style.md).

## Details

Builders for the `group` layer
([`er_plot_add_groups()`](https://erplots.djnavarro.net/reference/er_plot_add_groups.md))
draw exposure distributions for grouping variables.
`er_style_group_boxplot()` and `er_style_group_violin()` put group
levels on the y-axis; `er_style_group_histogram()` puts them on facet
strips and frees the y-axis for counts. All built-in group builders are
tagged `layer = "group"`, so
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
}



```
