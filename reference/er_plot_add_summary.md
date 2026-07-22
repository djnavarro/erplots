# Add a summary annotation layer

Adds the summary layer: a text/label annotation placed in whichever
corner of the base panel is furthest from the observed data (see
[`er_style_tag()`](https://erplots.djnavarro.net/reference/er_style_tag.md)'s
`corner_distance`-based placement, computed from `object$data`'s raw
`(exposure, response)` coordinates – not any fitted curve). Unlike
[`er_plot_add_model()`](https://erplots.djnavarro.net/reference/er_plot_add_model.md),
this layer doesn't require a model:
[`er_style_summary_pvalue()`](https://erplots.djnavarro.net/reference/er_style_summary.md)
(the default) draws a p-value derived from a supplied model's own
[`er_summary()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
method, but
[`er_style_summary_n()`](https://erplots.djnavarro.net/reference/er_style_summary.md)
is purely descriptive (total observation count, or one count per stratum
level) and needs no `model` at all.

## Usage

``` r
er_plot_add_summary(
  object,
  model = NULL,
  keep_strata = NULL,
  style = NULL,
  ...
)
```

## Arguments

- object:

  Partially constructed plot (has S3 class `er_plot`)

- model:

  A fitted exposure-response model, or `NULL` (the default). Only needed
  by a model-summary builder (e.g.
  [`er_style_summary_pvalue()`](https://erplots.djnavarro.net/reference/er_style_summary.md),
  which calls
  [`er_summary()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
  on it); a purely descriptive builder (e.g.
  [`er_style_summary_n()`](https://erplots.djnavarro.net/reference/er_style_summary.md))
  ignores it.

- keep_strata:

  Logical, indicating whether this layer should be split by the plot's
  stratification variable; defaults to `TRUE` if `stratify_by` was set
  in [`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md),
  `FALSE` otherwise. Passed through to `style` as `stratify` –
  whether/how a builder changes its behaviour when `TRUE` is up to the
  builder itself (e.g.
  [`er_style_summary_pvalue()`](https://erplots.djnavarro.net/reference/er_style_summary.md)
  draws nothing at all, since one p-value doesn't unambiguously describe
  multiple curves).

- style:

  Function drawing the summary annotation – defaults to
  [`er_style_summary_pvalue()`](https://erplots.djnavarro.net/reference/er_style_summary.md).
  [`er_style_summary_n()`](https://erplots.djnavarro.net/reference/er_style_summary.md)
  is the other built-in option; any function matching the standard
  `(data, config, stratify, exposure, response, strata, theme, ...)`
  signature can be supplied instead – see
  [`er_style()`](https://erplots.djnavarro.net/reference/er_style.md).
  `config$p_value` (`NULL` unless `model` was supplied) and
  `config$corner_distance` are the pre-computed pieces specific to this
  layer. If `style` is tagged with a `layer` (via
  [`er_style_tag()`](https://erplots.djnavarro.net/reference/er_style_tag.md))
  other than `"summary"`, this errors informatively; an untagged builder
  is never checked.

- ...:

  Additional named arguments forwarded, unchanged, to `style` when it's
  called at build time – see
  [`er_style()`](https://erplots.djnavarro.net/reference/er_style.md)'s
  "Passing extra arguments to a builder" section. Must be named.

## Value

The input `object`, with the summary layer added

## Details

This layer is **singleton** – see
[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md)'s
"Layers are either singleton or additive" – so calling it twice replaces
the previous summary annotation rather than combining two. A builder
wanting to show several statistics at once composes them into one
label/one set of geoms itself, the way
[`er_style_summary_n()`](https://erplots.djnavarro.net/reference/er_style_summary.md)
does for multiple strata.

## See also

[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md),
[`er_plot_add_model()`](https://erplots.djnavarro.net/reference/er_plot_add_model.md),
[`er_plot_add_quantiles()`](https://erplots.djnavarro.net/reference/er_plot_add_quantiles.md),
[`er_plot_add_data()`](https://erplots.djnavarro.net/reference/er_plot_add_data.md),
[`er_plot_add_groups()`](https://erplots.djnavarro.net/reference/er_plot_add_groups.md),
[`er_style()`](https://erplots.djnavarro.net/reference/er_style.md)

## Examples

``` r
if (requireNamespace("erglm", quietly = TRUE)) {
library(erglm)
mod <- erglm_model(ae1 ~ aucss, erglm_data, family = binomial())
erglm_data |>
  er_plot(aucss, ae1) |>
  er_plot_add_model(mod) |>
  er_plot_add_summary(model = mod) |>
  plot()

# a purely descriptive annotation, with no model at all
erglm_data |>
  er_plot(aucss, ae1) |>
  er_plot_add_summary(style = er_style_summary_n) |>
  plot()
}


```
