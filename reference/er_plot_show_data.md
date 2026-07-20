# Add a raw-data layer

Adds the data layer: individual observations jittered along the exposure
axis. Which builder is used dispatches automatically on the plot's
`response_type` (set in
[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md)):

- `"binary"` – responders (`response == 1`) are jittered in an upper
  panel and non-responders (`response == 0`) in a lower panel.

- `"continuous"`/`"count"` – a single panel, with points colored
  continuously by the response value in place of the upper/lower
  partition (there's no binary flag to split on). `panel` must be
  `"both"` (the default) for these response types – passing
  `"upper"`/`"lower"` errors, since that partition is binary-specific.

## Usage

``` r
er_plot_show_data(object, keep_strata = NULL, style = "jitter", panel = "both")
```

## Arguments

- object:

  Partially constructed plot (has S3 class `er_plot`)

- keep_strata:

  Logical, indicating whether this layer should be split by the plot's
  stratification variable; defaults to `TRUE` if `stratify_by` was set
  in [`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md),
  `FALSE` otherwise. For a continuous/count response this produces one
  panel per stratum level (see "Stratification" above) rather than a
  shared color aesthetic.

- style:

  Character string selecting the partial builder (currently only
  `"jitter"`, the default)

- panel:

  Character string: `"upper"`, `"lower"`, or `"both"` (the default).
  Only meaningful for a binary response; must be `"both"` for a
  continuous/count response (there's no upper/lower partition to select
  from).

## Value

The input `object`, with the data layer added

## Details

This layer is **singleton** – see
[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md)'s
"Layers are either singleton or additive". It's also the one layer whose
stratification behaviour is a partial exception to "always color/fill"
(see [`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md)'s
"Stratification" section): for a continuous/count response, the color
aesthetic is already spoken for by the response value, so stratification
instead produces one panel per stratum level (stacked below the base
plot, each colored by the response), rather than a shared strata legend.

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
  er_plot_show_data() |>
  plot()

# continuous response: a single color-encoded panel instead of the
# binary upper/lower partition
mod3 <- erglm_model(biomarker_change ~ aucss, erglm_data, family = gaussian())
erglm_data |>
  er_plot(aucss, biomarker_change) |>
  er_plot_show_model(mod3) |>
  er_plot_show_data() |>
  plot()
} # }
```
