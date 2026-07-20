# Add a raw-data layer

Adds the data layer: individual observations. By default
(`style = "overlay"`), points are drawn at their true
`(exposure, response)` coordinates in the *main* model panel – a plain
scatter for continuous/count responses, or a scatter with a small
vertical jitter for a binary response (whose y-values are exactly 0/1
and would otherwise overplot into two solid lines). This works uniformly
across all three response types, with no response-type dispatch on which
builder to use. `style = "jitter"` instead uses the older, panel-based
design, which *does* dispatch on `response_type` (set in
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
er_plot_show_data(
  object,
  keep_strata = NULL,
  style = "overlay",
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
  `FALSE` otherwise. For `style = "jitter"` on a continuous/count
  response this produces one panel per stratum level (see
  "Stratification" above) rather than a shared color aesthetic; for
  `style = "overlay"` it always means a shared color aesthetic, for any
  response type.

- style:

  Character string selecting the partial builder: `"overlay"` (default;
  a scatter in the main panel, at each point's true
  `(exposure, response)` coordinates) or `"jitter"` (the older
  panel-based design – see above)

- panel:

  Character string: `"upper"`, `"lower"`, or `"both"` (the default).
  Only meaningful for `style = "jitter"` on a binary response; must be
  `"both"` for `style = "overlay"` (no upper/lower partition exists) or
  for a continuous/count response under `style = "jitter"` (there's no
  upper/lower partition to select from either way).

## Value

The input `object`, with the data layer added

## Details

This layer is **singleton** – see
[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md)'s
"Layers are either singleton or additive" – calling it again (with
either style) fully replaces the previous data layer. `style = "jitter"`
is also the one case where stratification behaviour is a partial
exception to "always color/fill" (see
[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md)'s
"Stratification" section): for a continuous/count response, the color
aesthetic is already spoken for by the response value, so stratification
instead produces one panel per stratum level (stacked below the base
plot, each colored by the response), rather than a shared strata legend.
`style = "overlay"` has no such exception – its color aesthetic (when
stratified) is always strata, since the response is already shown via
y-position, and it shares the base plot's own strata legend (the same
one the model/ quantile layers use) rather than needing one of its own.

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

# continuous response: overlay works the same way, with no
# response-type-specific styling needed
mod3 <- erglm_model(biomarker_change ~ aucss, erglm_data, family = gaussian())
erglm_data |>
  er_plot(aucss, biomarker_change) |>
  er_plot_show_model(mod3) |>
  er_plot_show_data() |>
  plot()

# older panel-based design: a single color-encoded panel below the
# base plot, instead of an overlay in the main panel
erglm_data |>
  er_plot(aucss, biomarker_change) |>
  er_plot_show_model(mod3) |>
  er_plot_show_data(style = "jitter") |>
  plot()
} # }
```
