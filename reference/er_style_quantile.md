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
  [`er_plot_add_quantiles()`](https://erplots.djnavarro.net/reference/er_plot_add_quantiles.md)'s
  own `...`; see
  [`er_style()`](https://erplots.djnavarro.net/reference/er_style.md)'s
  "Passing extra arguments to a builder" section.

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
}



```
