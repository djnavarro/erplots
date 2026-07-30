# Adjust theme/labels for an `er_plot` object

Adjusts the styling knobs a ggplot2 user would expect to control –
axis/legend labels, plot title/subtitle/caption, axis limits, the
overall visual theme, the discrete color/fill palette used for
stratification, value formatters, the legend key glyph, the quantile
layer's stratum-dodge spacing, and relative panel heights – without
touching which variable is mapped to which aesthetic (that's controlled
by a layer's `style`; see
[`er_style()`](https://erplots.djnavarro.net/reference/er_style.md)).

## Usage

``` r
er_plot_theme(
  object,
  xlab = NULL,
  ylab = NULL,
  strata_lab = NULL,
  title = NULL,
  subtitle = NULL,
  caption = NULL,
  xlim = NULL,
  ylim = NULL,
  theme_base = NULL,
  theme_extra = NULL,
  color_discrete = NULL,
  fill_discrete = NULL,
  color_continuous = NULL,
  fill_continuous = NULL,
  format_p = NULL,
  format_percent = NULL,
  format_number = NULL,
  draw_key = NULL,
  dodge_width = NULL,
  height_base = NULL,
  height_data = NULL,
  height_group = NULL
)
```

## Arguments

- object:

  Partially constructed plot (has S3 class `er_plot`)

- xlab, ylab:

  Exposure/response axis label (single string), written to
  `object$exposure$label`/`object$response$label`.

- strata_lab:

  Stratification legend label (single string), written to
  `object$strata$label`. Errors if `stratify_by` wasn't set in
  [`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md) –
  there's no stratification legend to label.

- title, subtitle, caption:

  Plot-level annotation text (single strings), applied via
  [`patchwork::plot_annotation()`](https://patchwork.data-imaginist.com/reference/plot_annotation.html)
  in
  [`er_plot_build()`](https://erplots.djnavarro.net/reference/er_plot_build.md).

- xlim, ylim:

  Exposure/response axis limits (length-2, increasing numeric vectors),
  written to `object$exposure$limits`/ `object$response$limits`. These
  are read lazily by every builder at build time, so it doesn't matter
  whether `er_plot_theme()` is called before or after the layers that
  use them.

- theme_base:

  A ggplot2 theme object (e.g.
  [`ggplot2::theme_minimal()`](https://ggplot2.tidyverse.org/reference/ggtheme.html)),
  written to `object$theme$theme_base` – the swappable overall visual
  theme, defaulting to
  [`ggplot2::theme_bw()`](https://ggplot2.tidyverse.org/reference/ggtheme.html)

- theme_extra:

  A ggplot2 theme object (e.g. from
  [`ggplot2::theme()`](https://ggplot2.tidyverse.org/reference/theme.html)),
  written to `object$theme$theme_extra` – additional theme tweaks
  layered on top of `theme_base`, defaulting to a panel border plus
  `legend.position = "bottom"`. Supplying a new value fully replaces
  this default rather than merging with it, so re-include the border/
  legend-position settings too if you want to keep them alongside your
  own additions.

- color_discrete, fill_discrete:

  A discrete ggplot2 scale object (e.g.
  [`ggplot2::scale_color_brewer()`](https://ggplot2.tidyverse.org/reference/scale_brewer.html),
  [`ggplot2::scale_fill_viridis_d()`](https://ggplot2.tidyverse.org/reference/scale_viridis.html)),
  written to `object$theme$color_discrete`/`object$theme$fill_discrete`
  and applied to every plot whose `colour`/`fill` aesthetic is mapped to
  the stratification variable – see "Details".

- color_continuous, fill_continuous:

  A continuous ggplot2 scale object (e.g.
  [`ggplot2::scale_color_viridis_c()`](https://ggplot2.tidyverse.org/reference/scale_viridis.html),
  [`ggplot2::scale_fill_gradient()`](https://ggplot2.tidyverse.org/reference/scale_gradient.html)),
  written to
  `object$theme$color_continuous`/`object$theme$fill_continuous` and
  applied to every plot whose `colour`/`fill` aesthetic is mapped to
  something continuous other than the stratification variable – see
  "Details".

- format_p, format_percent, format_number:

  Formatter functions (typically from `scales::label_*()`), written to
  `object$theme$format_p` etc. Used by the summary/quantile layers to
  format p-values/rates/means for display.

- draw_key:

  A key-glyph function (e.g.
  [`ggplot2::draw_key_point()`](https://ggplot2.tidyverse.org/reference/draw_key.html)),
  written to `object$theme$draw_key` and passed as every geom's
  `key_glyph` argument.

- dodge_width:

  Spacing between adjacent strata's horizontal offset in the quantile
  layer (see
  [`er_style_quantile_errorbar()`](https://erplots.djnavarro.net/reference/er_style_quantile.md)/
  [`er_style_quantile_pointrange()`](https://erplots.djnavarro.net/reference/er_style_quantile.md)),
  as a fraction of the exposure range. A single positive number, written
  to `object$theme$dodge_width`. Default `0.015` (set in
  [`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md)).

- height_base, height_data, height_group:

  Relative panel heights (single positive numbers), merged into
  `object$theme$height` – supplying only one leaves the other two
  unchanged.

## Value

The input `object`, with the requested theme fields updated

## Details

`dodge_width` is the one setting here that's about stratification
*layout* rather than a single layer's visual style – it's read by
[`er_style_quantile_errorbar()`](https://erplots.djnavarro.net/reference/er_style_quantile.md)/[`er_style_quantile_pointrange()`](https://erplots.djnavarro.net/reference/er_style_quantile.md)
(and their `_vlines` variants) to horizontally separate strata within
each quantile bin. It lives in `er_plot_theme()`, rather than as an
argument to those builders, because dodging is a property of how
stratification lays out a layer, not something specific to any one
builder's own visual choices.

Every argument defaults to `NULL`, meaning "leave whatever was set
before unchanged" – so `er_plot_theme()` can be called more than once on
the same object, each call only touching the arguments it actually
supplies (the same accumulate-by-default behaviour as
[`ggplot2::theme()`](https://ggplot2.tidyverse.org/reference/theme.html)'s
own merging). There is no way to reset a field back to its
[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md)
default other than re-supplying that default's value explicitly.

`color_discrete`/`fill_discrete` only affect aesthetics that are
genuinely mapped to the stratification variable; `color_continuous`/
`fill_continuous` are the symmetric counterpart for aesthetics mapped to
something else continuous –
[`er_style_data_hex()`](https://erplots.djnavarro.net/reference/er_style_data.md)'s
density `fill`, or a continuous/count response's color-encoded data
layer (there's no built-in builder for the latter today; see
[`er_style_tag()`](https://erplots.djnavarro.net/reference/er_style_tag.md)'s
`layout` argument). Each of the four only ever touches the aesthetic
role it names – supplying `color_continuous` never affects a discrete
`colour` mapping, and vice versa. If a custom builder adds its own
`scale_color_*()`/`scale_fill_*()` directly, supplying any of these four
here will add a second scale on top (ggplot2 will emit a message and the
later one wins) rather than detecting and deferring to the builder's own
choice.

## See also

[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md),
[`er_style()`](https://erplots.djnavarro.net/reference/er_style.md)
