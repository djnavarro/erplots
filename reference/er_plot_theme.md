# Adjust theme/labels for an `er_plot` object

Set axis/legend labels, plot titles/captions, axis limits, theme
objects, discrete and continuous scale objects, formatters, legend key
glyph, and relative panel heights. This does not change which variable
is mapped to which aesthetic.

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

  Exposure/response axis label (single string).

- strata_lab:

  Stratification legend label (single string). Errors if `stratify_by`
  wasn't set in
  [`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md) –
  there's no stratification legend to label.

- title, subtitle, caption:

  Plot-level annotation text (single strings), applied via
  [`patchwork::plot_annotation()`](https://patchwork.data-imaginist.com/reference/plot_annotation.html)
  in
  [`er_plot_build()`](https://erplots.djnavarro.net/reference/er_plot_build.md).

- xlim, ylim:

  Exposure/response axis limits (length-2, increasing numeric vectors).
  These are read lazily by every builder at build time, so it doesn't
  matter whether `er_plot_theme()` is called before or after the layers
  that use them.

- theme_base:

  A ggplot2 theme object (e.g.
  [`ggplot2::theme_minimal()`](https://ggplot2.tidyverse.org/reference/ggtheme.html))
  – the swappable overall visual theme, defaulting to
  [`ggplot2::theme_bw()`](https://ggplot2.tidyverse.org/reference/ggtheme.html)

- theme_extra:

  A ggplot2 theme object (e.g. from
  [`ggplot2::theme()`](https://ggplot2.tidyverse.org/reference/theme.html)),
  – additional theme tweaks layered on top of `theme_base`, defaulting
  to a panel border plus `legend.position = "bottom"`. Supplying a new
  value fully replaces this default rather than merging with it, so
  re-include the border/ legend-position settings too if you want to
  keep them alongside your own additions.

- color_discrete, fill_discrete:

  A discrete ggplot2 scale object (e.g.
  [`ggplot2::scale_color_brewer()`](https://ggplot2.tidyverse.org/reference/scale_brewer.html),
  [`ggplot2::scale_fill_viridis_d()`](https://ggplot2.tidyverse.org/reference/scale_viridis.html)),
  applied to every plot whose `colour`/`fill` aesthetic is mapped to the
  stratification variable – see "Details".

- color_continuous, fill_continuous:

  A continuous ggplot2 scale object (e.g.
  [`ggplot2::scale_color_viridis_c()`](https://ggplot2.tidyverse.org/reference/scale_viridis.html),
  [`ggplot2::scale_fill_gradient()`](https://ggplot2.tidyverse.org/reference/scale_gradient.html)),
  applied to every plot whose `colour`/`fill` aesthetic is mapped to
  something continuous other than the stratification variable – see
  "Details".

- format_p, format_percent, format_number:

  Formatter functions (typically from `scales::label_*()`). Used by the
  summary/quantile layers to format p-values/rates/means for display.

- draw_key:

  A key-glyph function (e.g.
  [`ggplot2::draw_key_point()`](https://ggplot2.tidyverse.org/reference/draw_key.html)),
  passed as every geom's `key_glyph` argument.

- dodge_width:

  Spacing between adjacent strata's horizontal offset in the quantile
  layer (see
  [`er_style_quantile_errorbar()`](https://erplots.djnavarro.net/reference/er_style_quantile.md)/
  [`er_style_quantile_pointrange()`](https://erplots.djnavarro.net/reference/er_style_quantile.md)),
  as a fraction of the exposure range. A single positive number. Default
  is `0.015` (set in
  [`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md)).

- height_base, height_data, height_group:

  Relative panel heights (single positive numbers). Supplying only one
  leaves the other two unchanged.

## Value

The input `object`, with the requested theme fields updated

## Details

`dodge_width` is a stratification-layout setting used by
[`er_style_quantile_errorbar()`](https://erplots.djnavarro.net/reference/er_style_quantile.md)/[`er_style_quantile_pointrange()`](https://erplots.djnavarro.net/reference/er_style_quantile.md)
(and their `_vlines` variants) to separate strata horizontally within
each quantile bin. It belongs in `er_plot_theme()` because dodging is
about stratification layout, not an individual builder's visual style.

Every argument defaults to `NULL`, meaning "leave whatever was set
before unchanged". This allows repeated calls to `er_plot_theme()` to
update only the supplied fields, like
[`ggplot2::theme()`](https://ggplot2.tidyverse.org/reference/theme.html).
There is no implicit way to reset a field to the
[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md)
default.

`color_discrete`/`fill_discrete` apply only when a layer's `colour`/
`fill` aesthetic is mapped to stratification. Their continuous
counterparts, `color_continuous`/`fill_continuous`, apply only when the
aesthetic is mapped to a continuous quantity such as density or a
continuous/count response value. If a custom builder adds its own scale,
supplying one of these four will add a second scale and let ggplot2
choose the later one.

## See also

[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md),
[`er_style()`](https://erplots.djnavarro.net/reference/er_style.md)
