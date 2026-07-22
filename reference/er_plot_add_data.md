# Add a raw-data layer

Adds the data layer: individual observations. By default
(`style = er_style_data_overlay`), points are drawn at their true
`(exposure, response)` coordinates in the *main* model panel – a plain
scatter for continuous/count responses, or a scatter with a small
vertical jitter for a binary response (whose y-values are exactly 0/1
and would otherwise overplot into two solid lines). This works uniformly
across all three response types, with no response-type dispatch on which
builder to use.
[`er_style_data_boxjitter()`](https://erplots.djnavarro.net/reference/er_style_data.md)
instead uses the older, panel-based design, and is binary-response-only:
responders (`response == 1`) get a boxplot + jittered points in an upper
panel and non-responders (`response == 0`) get the same in a lower
panel, so the panel shows the exposure *distribution* conditional on
response, not just raw points. There is no built-in "panel"-layout
builder for a continuous/count response – the older `build_data_color()`
(a single panel with points colored continuously by the response value)
was removed once
[`er_style_data_overlay()`](https://erplots.djnavarro.net/reference/er_style_data.md)
turned out to cover its typical use case more simply; `panel` must be
`"both"` (the default) for these response types regardless of builder,
since there's no upper/lower partition to select from.

## Usage

``` r
er_plot_add_data(object, keep_strata = NULL, style = NULL, panel = "both", ...)
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

- style:

  Function drawing the data layer – defaults to
  [`er_style_data_overlay()`](https://erplots.djnavarro.net/reference/er_style_data.md).
  [`er_style_data_boxjitter()`](https://erplots.djnavarro.net/reference/er_style_data.md)
  (binary response only: a boxplot + jittered points per panel) is the
  other built-in option; any function matching the standard
  `(data, config, stratify, exposure, response, strata, theme, ...)`
  signature and tagged with
  [`er_style_tag()`](https://erplots.djnavarro.net/reference/er_style_tag.md)
  can be supplied instead – see
  [`er_style()`](https://erplots.djnavarro.net/reference/er_style.md)
  for the full contract, e.g. a 2D density in the main panel, a
  continuous/ count response's color-encoded panel, or per-panel
  histograms. If `style` is tagged with a `layer` other than `"data"`,
  this errors informatively; an untagged builder is never checked (only
  `layout` is a hard requirement).

- panel:

  Character string: `"upper"`, `"lower"`, or `"both"` (the default).
  Only meaningful for
  [`er_style_data_boxjitter()`](https://erplots.djnavarro.net/reference/er_style_data.md)
  on a binary response; must be `"both"` for an "overlay"-layout builder
  (no upper/lower partition exists) or for a continuous/count response
  under a "panel"-layout builder (there's no upper/lower partition to
  select from either way).

- ...:

  Additional named arguments forwarded, unchanged, to `style` when it's
  called at build time – see
  [`er_style()`](https://erplots.djnavarro.net/reference/er_style.md)'s
  "Passing extra arguments to a builder" section. Must be named.

## Value

The input `object`, with the data layer added

## Details

Every data-layer builder declares which of these two *structural*
families it belongs to via
[`er_style_tag()`](https://erplots.djnavarro.net/reference/er_style_tag.md)
– `"overlay"` (a single call merged into the main panel) or `"panel"`
(one-or-more panels stacked below the base plot) – which
`er_plot_add_data()` reads off `style` to decide how to assemble the
layer, rather than taking a separate argument for it. This makes the
pairing structural rather than incidental:
[`er_style_data_overlay()`](https://erplots.djnavarro.net/reference/er_style_data.md)
can never be routed into upper/lower panels, and
[`er_style_data_boxjitter()`](https://erplots.djnavarro.net/reference/er_style_data.md)
can never be merged into the main panel. See
[`er_style_tag()`](https://erplots.djnavarro.net/reference/er_style_tag.md)
and [`er_style()`](https://erplots.djnavarro.net/reference/er_style.md)
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
[`er_plot_add_model()`](https://erplots.djnavarro.net/reference/er_plot_add_model.md),
[`er_plot_add_summary()`](https://erplots.djnavarro.net/reference/er_plot_add_summary.md),
[`er_plot_add_quantiles()`](https://erplots.djnavarro.net/reference/er_plot_add_quantiles.md),
[`er_plot_add_groups()`](https://erplots.djnavarro.net/reference/er_plot_add_groups.md),
[`er_style()`](https://erplots.djnavarro.net/reference/er_style.md)

## Examples

``` r
if (requireNamespace("erglm", quietly = TRUE)) {
library(erglm)
mod2 <- erglm_model(ae2 ~ aucss + sex, erglm_data, family = binomial())
erglm_data |>
  er_plot(aucss, ae2, stratify_by = sex) |>
  er_plot_add_model(mod2) |>
  er_plot_add_quantiles() |>
  er_plot_add_data() |>
  plot()

# continuous response: overlay works the same way, with no
# response-type-specific styling needed
mod3 <- erglm_model(biomarker_change ~ aucss, erglm_data, family = gaussian())
erglm_data |>
  er_plot(aucss, biomarker_change) |>
  er_plot_add_model(mod3) |>
  er_plot_add_data() |>
  plot()

# older panel-based design, binary-response only: a boxplot + jittered
# points per panel (responders above, non-responders below), instead
# of an overlay in the main panel
erglm_data |>
  er_plot(aucss, ae2, stratify_by = sex) |>
  er_plot_add_model(mod2) |>
  er_plot_add_data(style = er_style_data_boxjitter) |>
  plot()

# plug in a 2D density in the main panel instead of a scatter; tagging
# it "overlay" via `er_style_tag()` keeps it in the single main-panel
# layout -- see `?er_style`
build_data_density <- er_style_tag(
  function(data, config, stratify, exposure, response, strata, theme, ...) {
    ggplot2::geom_density_2d(
      data = data,
      mapping = ggplot2::aes(x = .data[[exposure$name]], y = .data[[response$name]])
    )
  },
  layout = "overlay"
)
erglm_data |>
  er_plot(aucss, biomarker_change) |>
  er_plot_add_model(mod3) |>
  er_plot_add_data(style = build_data_density) |>
  plot()
}




```
