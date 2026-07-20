# Add a raw-data layer

Adds the data layer: individual observations. By default
(`builder = build_data_overlay`), points are drawn at their true
`(exposure, response)` coordinates in the *main* model panel – a plain
scatter for continuous/count responses, or a scatter with a small
vertical jitter for a binary response (whose y-values are exactly 0/1
and would otherwise overplot into two solid lines). This works uniformly
across all three response types, with no response-type dispatch on which
builder to use.
[`build_data_jitter()`](https://erplots.djnavarro.net/reference/er_partial.md)/[`build_data_color()`](https://erplots.djnavarro.net/reference/er_partial.md)
instead use the older, panel-based design, which *does* dispatch on
`response_type` (set in
[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md)):

- [`build_data_jitter()`](https://erplots.djnavarro.net/reference/er_partial.md)
  (binary response) – responders (`response == 1`) are jittered in an
  upper panel and non-responders (`response == 0`) in a lower panel.

- [`build_data_color()`](https://erplots.djnavarro.net/reference/er_partial.md)
  (continuous/count response) – a single panel, with points colored
  continuously by the response value in place of the upper/lower
  partition (there's no binary flag to split on). `panel` must be
  `"both"` (the default) for these response types – passing
  `"upper"`/`"lower"` errors, since that partition is binary-specific.

## Usage

``` r
er_plot_show_data(object, keep_strata = NULL, builder = NULL, panel = "both")
```

## Arguments

- object:

  Partially constructed plot (has S3 class `er_plot`)

- keep_strata:

  Logical, indicating whether this layer should be split by the plot's
  stratification variable; defaults to `TRUE` if `stratify_by` was set
  in [`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md),
  `FALSE` otherwise. For a "panel"-layout builder on a continuous/count
  response this produces one panel per stratum level (see
  "Stratification" above) rather than a shared color aesthetic; for an
  "overlay"-layout builder it always means a shared color aesthetic, for
  any response type.

- builder:

  Function drawing the data layer – defaults to
  [`build_data_overlay()`](https://erplots.djnavarro.net/reference/er_partial.md).
  [`build_data_jitter()`](https://erplots.djnavarro.net/reference/er_partial.md)
  (binary response) and
  [`build_data_color()`](https://erplots.djnavarro.net/reference/er_partial.md)
  (continuous/count response) are the other built-in options; any
  function matching the standard
  `(data, config, stratify, exposure, response, strata, style)`
  signature and tagged with
  [`er_layout()`](https://erplots.djnavarro.net/reference/er_layout.md)
  can be supplied instead – see
  [`er_partial()`](https://erplots.djnavarro.net/reference/er_partial.md)
  for the full contract, e.g. a 2D density in the main panel, or
  per-panel histograms.

- panel:

  Character string: `"upper"`, `"lower"`, or `"both"` (the default).
  Only meaningful for
  [`build_data_jitter()`](https://erplots.djnavarro.net/reference/er_partial.md)
  on a binary response; must be `"both"` for an "overlay"-layout builder
  (no upper/lower partition exists) or for a continuous/count response
  under a "panel"-layout builder (there's no upper/lower partition to
  select from either way).

## Value

The input `object`, with the data layer added

## Details

Every data-layer builder declares which of these two *structural*
families it belongs to via
[`er_layout()`](https://erplots.djnavarro.net/reference/er_layout.md) –
`"overlay"` (a single call merged into the main panel) or `"panel"`
(one-or-more panels stacked below the base plot) – which
`er_plot_show_data()` reads off `builder` to decide how to assemble the
layer, rather than taking a separate argument for it. This makes the
pairing structural rather than incidental:
[`build_data_overlay()`](https://erplots.djnavarro.net/reference/er_partial.md)
can never be routed into upper/lower panels, and
[`build_data_jitter()`](https://erplots.djnavarro.net/reference/er_partial.md)/[`build_data_color()`](https://erplots.djnavarro.net/reference/er_partial.md)
can never be merged into the main panel. See
[`er_layout()`](https://erplots.djnavarro.net/reference/er_layout.md)
and
[`er_partial()`](https://erplots.djnavarro.net/reference/er_partial.md)
for how to tag a custom builder the same way.

This layer is **singleton** – see
[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md)'s
"Layers are either singleton or additive" – calling it again (with any
builder) fully replaces the previous data layer. A "panel"-layout
builder is also the one case where stratification behaviour is a partial
exception to "always color/fill" (see
[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md)'s
"Stratification" section): for a continuous/count response, the color
aesthetic is already spoken for by the response value, so stratification
instead produces one panel per stratum level (stacked below the base
plot, each colored by the response), rather than a shared strata legend.
An "overlay"-layout builder has no such exception – its color aesthetic
(when stratified) is always strata, since the response is already shown
via y-position, and it shares the base plot's own strata legend (the
same one the model/quantile layers use) rather than needing one of its
own.

## See also

[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md),
[`er_plot_show_model()`](https://erplots.djnavarro.net/reference/er_plot_show_model.md),
[`er_plot_show_quantiles()`](https://erplots.djnavarro.net/reference/er_plot_show_quantiles.md),
[`er_plot_show_groups()`](https://erplots.djnavarro.net/reference/er_plot_show_groups.md),
[`er_partial()`](https://erplots.djnavarro.net/reference/er_partial.md)

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
  er_plot_show_data(builder = build_data_color) |>
  plot()

# plug in a 2D density in the main panel instead of a scatter; tagging
# it "overlay" via `er_layout()` keeps it in the single main-panel
# layout -- see `?er_partial`
build_data_density <- er_layout(
  function(data, config, stratify, exposure, response, strata, style) {
    ggplot2::geom_density_2d(
      data = data,
      mapping = ggplot2::aes(x = .data[[exposure$name]], y = .data[[response$name]])
    )
  },
  layout = "overlay"
)
erglm_data |>
  er_plot(aucss, biomarker_change) |>
  er_plot_show_model(mod3) |>
  er_plot_show_data(builder = build_data_density) |>
  plot()
} # }
```
