# Add a raw-data strip layer

Adds the data strip layer: individual observations jittered along the
exposure axis. Currently supports only a binary response – responders
(`response == 1`) are jittered in an upper panel and non-responders
(`response == 0`) in a lower panel. Calling this on an `er_plot` whose
`response_type` is `"continuous"` or `"count"` errors, since the
two-panel design has no direct analogue for those response types; see
`PLAN.md`'s "Continuous-response data strip" section for the planned
generalisation (a single, continuously colour-encoded panel) and
"Mini-language architecture review" for the naming change this layer is
expected to undergo (`er_plot_show_datastrip()` -\>
`er_plot_show_data()`).

## Usage

``` r
er_plot_show_datastrip(
  object,
  keep_strata = NULL,
  style = "jitter",
  panel = "both"
)
```

## Arguments

- object:

  Partially constructed plot (has S3 class `er_plot`)

- keep_strata:

  Logical, indicating whether this layer should be split by the plot's
  stratification variable; defaults to `TRUE` if `stratify_by` was set
  in [`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md),
  `FALSE` otherwise

- style:

  Character string selecting the partial builder (currently only
  `"jitter"`, the default)

- panel:

  Character string: `"upper"`, `"lower"`, or `"both"` (the default)

## Value

The input `object`, with the data strip layer added

## Details

This layer is **singleton** – see
[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md)'s
"Layers are either singleton or additive". It's also the one layer whose
stratification behaviour is expected to become a partial exception to
"always color/ fill" once it supports continuous/count responses – see
[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md)'s
"Stratification" section and `PLAN.md`.

## See also

[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md),
[`er_plot_show_model()`](https://erplots.djnavarro.net/reference/er_plot_show_model.md),
[`er_plot_show_quantiles()`](https://erplots.djnavarro.net/reference/er_plot_show_quantiles.md),
[`er_plot_show_groups()`](https://erplots.djnavarro.net/reference/er_plot_show_groups.md)

## Examples

``` r
if (FALSE) { # \dontrun{
library(erglm)
mod2 <- erglm_model(ae2 ~ aucss + sex, erglm_data, family = binomial())
erglm_data |>
  er_plot(aucss, ae2, stratify_by = sex) |>
  er_plot_show_model(mod2, keep_strata = FALSE) |>
  er_plot_show_quantiles() |>
  er_plot_show_datastrip() |>
  plot()
} # }
```
