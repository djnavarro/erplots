# Add a grouped exposure-distribution panel

Adds a group layer: a boxplot/violin panel showing the *exposure*
distribution, split by one or more grouping variables (continuous
grouping variables are binned into quantiles first, via
[`cut_quantile()`](https://erplots.djnavarro.net/reference/cut_quantile.md)).
This layer only looks at the exposure variable, not the response, so it
needs no `response_type` dispatch.

## Usage

``` r
er_plot_show_groups(
  object,
  group_by,
  builder = NULL,
  bins = NULL,
  keep_strata = NULL
)
```

## Arguments

- object:

  Partially constructed plot (has S3 class `er_plot`)

- group_by:

  Grouping variables to define groups for distribution plots (a
  tidyselection of variables)

- builder:

  Function drawing each group panel – defaults to
  [`build_group_boxplot()`](https://erplots.djnavarro.net/reference/build_group.md).
  [`build_group_violin()`](https://erplots.djnavarro.net/reference/build_group.md)
  is the other built-in option; any function matching the standard
  `(data, config, stratify, exposure, response, strata, style)`
  signature can be supplied instead – see
  [`er_partial()`](https://erplots.djnavarro.net/reference/er_partial.md).
  Applied to every grouping variable added by this call.

- bins:

  Number of quantile bins used for continuous grouping variables
  (`NULL`, the default, uses
  [`cut_quantile()`](https://erplots.djnavarro.net/reference/cut_quantile.md)'s
  own default)

- keep_strata:

  Logical, indicating whether this layer should be split by the plot's
  stratification variable; defaults to `TRUE` if `stratify_by` was set
  in [`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md),
  `FALSE` otherwise

## Value

The input `object`, with a group panel added

## Details

Unlike the other three layers, this one is **additive** – see
[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md)'s
"Layers are either singleton or additive" – each call adds another panel
alongside any already added by a previous call, rather than replacing
it.

## See also

[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md),
[`er_plot_show_model()`](https://erplots.djnavarro.net/reference/er_plot_show_model.md),
[`er_plot_show_quantiles()`](https://erplots.djnavarro.net/reference/er_plot_show_quantiles.md),
[`er_plot_show_data()`](https://erplots.djnavarro.net/reference/er_plot_show_data.md),
[`er_partial()`](https://erplots.djnavarro.net/reference/er_partial.md)

## Examples

``` r
if (FALSE) { # \dontrun{
library(erglm)
mod <- erglm_model(ae1 ~ aucss, erglm_data, family = binomial())
erglm_data |>
  er_plot(aucss, ae1) |>
  er_plot_show_model(mod) |>
  er_plot_show_groups(aucss) |>
  plot()

# additive: a second call adds a second panel rather than replacing the first
erglm_data |>
  er_plot(aucss, ae1) |>
  er_plot_show_model(mod) |>
  er_plot_show_groups(aucss) |>
  er_plot_show_groups(treatment) |>
  plot()
} # }
```
