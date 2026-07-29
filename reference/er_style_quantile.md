# Quantile summary builders for exposure-response plots

Quantile summary builders for exposure-response plots

## Usage

``` r
er_style_quantile_errorbar(
  data,
  config,
  stratify,
  exposure,
  response,
  strata,
  theme,
  point_size = 2,
  errorbar_width = 0.025,
  label_size = 3,
  ...
)

er_style_quantile_errorbar_vlines(
  data,
  config,
  stratify,
  exposure,
  response,
  strata,
  theme,
  point_size = 2,
  errorbar_width = 0.025,
  label_size = 3,
  vline_colour = "grey50",
  vline_linetype = "dotted",
  ...
)

er_style_quantile_pointrange(
  data,
  config,
  stratify,
  exposure,
  response,
  strata,
  theme,
  label_size = 3,
  pointrange_size = NULL,
  pointrange_linewidth = NULL,
  ...
)

er_style_quantile_pointrange_vlines(
  data,
  config,
  stratify,
  exposure,
  response,
  strata,
  theme,
  label_size = 3,
  pointrange_size = NULL,
  pointrange_linewidth = NULL,
  vline_colour = "grey50",
  vline_linetype = "dotted",
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

- point_size:

  Point size for `er_style_quantile_errorbar()`'s per-bin point. Default
  `2`.

- errorbar_width:

  Width of `er_style_quantile_errorbar()`'s error bars, as a fraction of
  the exposure range (not an absolute value). Default `0.025`.

- label_size:

  Text size for the per-bin value label drawn by all four builders.
  Default `3`.

- ...:

  Additional named arguments forwarded from
  [`er_plot_add_quantiles()`](https://erplots.djnavarro.net/reference/er_plot_add_quantiles.md)'s
  own `...`; see
  [`er_style()`](https://erplots.djnavarro.net/reference/er_style.md)'s
  "Passing extra arguments to a builder" section.

- vline_colour, vline_linetype:

  Colour/linetype of the interior quantile-bin boundary lines drawn by
  `er_style_quantile_errorbar_vlines()`/
  `er_style_quantile_pointrange_vlines()`. Defaults
  `"grey50"`/`"dotted"`.

- pointrange_size, pointrange_linewidth:

  [`ggplot2::geom_pointrange()`](https://ggplot2.tidyverse.org/reference/geom_linerange.html)'s
  own `size`/`linewidth` arguments, for
  `er_style_quantile_pointrange()`. Default `NULL` (ggplot2's own
  defaults, unchanged from before).

## Value

A geom, or a list of geoms; see
[`er_style()`](https://erplots.djnavarro.net/reference/er_style.md).

## Details

Builders for the `quantile` layer
([`er_plot_add_quantiles()`](https://erplots.djnavarro.net/reference/er_plot_add_quantiles.md)),
which bins exposure into quantile groups and plots a response summary
(rate, mean, or count-mean, depending on response type) with an
uncertainty interval per bin: `er_style_quantile_errorbar()` (point plus
error bar, the default) and `er_style_quantile_pointrange()` (point
range). `er_style_quantile_errorbar_vlines()` and
`er_style_quantile_pointrange_vlines()` are minor variants of each,
additionally drawing a dotted
[`ggplot2::geom_vline()`](https://ggplot2.tidyverse.org/reference/geom_abline.html)
at each interior quantile cutpoint (i.e. every bin boundary except the
exposure variable's overall min/max) – a common way exposure-response
bin plots are annotated in practice, so that the reader can see exactly
where one quantile bin ends and the next begins without inferring it
from the point/error bar spacing alone. All four are tagged
`er_style_tag(fn, layer = "quantile")`, so
[`er_plot_add_quantiles()`](https://erplots.djnavarro.net/reference/er_plot_add_quantiles.md)
errors informatively if handed a builder tagged for a different layer.

When stratified, all four builders horizontally dodge each quantile
bin's points/bars/labels apart by
[`er_plot_theme()`](https://erplots.djnavarro.net/reference/er_plot_theme.md)'s
`dodge_width` (a fraction of the exposure range, default `0.05`) – a
cross-layer, stratification-wide setting controlled via
[`er_plot_theme()`](https://erplots.djnavarro.net/reference/er_plot_theme.md)
rather than a per-builder argument here, since it's about how
stratification lays out a dodged layer, not one builder's own visual
style.

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

  # er_style_quantile_errorbar(): point + error bar, the default
  erglm_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(mod) |>
    er_plot_add_quantiles(style = er_style_quantile_errorbar) |>
    plot()

  # er_style_quantile_pointrange(): a pointrange instead
  erglm_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(mod) |>
    er_plot_add_quantiles(style = er_style_quantile_pointrange) |>
    plot()

  # er_style_quantile_errorbar_vlines(): the default, plus dotted
  # lines marking the interior quantile-bin boundaries
  erglm_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(mod) |>
    er_plot_add_quantiles(style = er_style_quantile_errorbar_vlines) |>
    plot()

  # Customize the quantile builder's appearance.
  erglm_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(mod) |>
    er_plot_add_quantiles(
      style = er_style_quantile_errorbar,
      point_size = 4,
      errorbar_width = 0.08,
      label_size = 4
    ) |>
    plot()

  erglm_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(mod) |>
    er_plot_add_quantiles(
      style = er_style_quantile_pointrange,
      label_size = 4,
      pointrange_size = 2,
      pointrange_linewidth = 1.2
    ) |>
    plot()

  # widening the stratum-dodge spacing via er_plot_theme(), rather than
  # a per-builder argument -- see "Details"
  mod2 <- erglm_model(ae1 ~ aucss + sex, erglm_data, family = binomial())
  erglm_data |>
    er_plot(aucss, ae1, stratify_by = sex) |>
    er_plot_add_model(mod2) |>
    er_plot_add_quantiles(style = er_style_quantile_errorbar) |>
    er_plot_theme(dodge_width = 0.15) |>
    plot()
}






```
