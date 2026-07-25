# Theming erplots

Every `er_plot_add_*()` function has a `style` argument that controls
*which builder draws a layer* – a ribbon vs. a spaghetti plot, a boxplot
vs. a violin, and so on (see [the plotting
grammar](https://erplots.djnavarro.net/articles/design.md) and
[extending
erplots](https://erplots.djnavarro.net/articles/extending.md)).
[`er_plot_theme()`](https://erplots.djnavarro.net/reference/er_plot_theme.md)
is a different, orthogonal knob: it controls *how the whole composed
plot looks*, without changing which variable is mapped to which
aesthetic in any layer. If `style` answers “what geom draws this layer”,
[`er_plot_theme()`](https://erplots.djnavarro.net/reference/er_plot_theme.md)
answers the same questions you’d otherwise reach for
[`ggplot2::labs()`](https://ggplot2.tidyverse.org/reference/labs.html),
[`ggplot2::theme()`](https://ggplot2.tidyverse.org/reference/theme.html),
and `ggplot2::scale_color_*()` to answer.

``` r

library(erplots)
library(erglm)

mod <- erglm_model(ae1 ~ aucss, erglm_data, family = binomial())
mod_strat <- erglm_model(ae1 ~ aucss + sex, erglm_data, family = binomial())
```

Every example below reuses the same stratified plot:

``` r

erglm_data |>
  er_plot(aucss, ae1, stratify_by = sex) |>
  er_plot_add_model(mod_strat) |>
  er_plot_add_quantiles() |>
  er_plot_add_data() |>
  plot()
```

![](theming_files/figure-html/base-plot-1.png)

[`er_plot_theme()`](https://erplots.djnavarro.net/reference/er_plot_theme.md)
slots into the same pipeline anywhere after
[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md) – its
arguments are read lazily at build time, so it doesn’t matter whether it
comes before or after the layer functions. Every argument defaults to
`NULL`, meaning “leave whatever was set before unchanged”.

## Labels

`xlab`/`ylab` relabel the exposure/response axes; `strata_lab` relabels
the stratification legend (this errors if `stratify_by` wasn’t set in
[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md) –
there’s no legend to label):

``` r

erglm_data |>
  er_plot(aucss, ae1, stratify_by = sex) |>
  er_plot_add_model(mod_strat) |>
  er_plot_add_quantiles() |>
  er_plot_add_data() |>
  er_plot_theme(
    xlab = "Steady-state AUC",
    ylab = "Adverse event (1)",
    strata_lab = "Sex"
  ) |>
  plot()
```

![](theming_files/figure-html/labels-1.png)

## Plot-level text

`title`/`subtitle`/`caption` add the usual plot-level annotations, via
[`patchwork::plot_annotation()`](https://patchwork.data-imaginist.com/reference/plot_annotation.html):

``` r

erglm_data |>
  er_plot(aucss, ae1, stratify_by = sex) |>
  er_plot_add_model(mod_strat) |>
  er_plot_add_quantiles() |>
  er_plot_add_data() |>
  er_plot_theme(
    title = "Adverse event vs. exposure",
    subtitle = "Stratified by sex",
    caption = "Source: erglm_data"
  ) |>
  plot()
```

![](theming_files/figure-html/title-1.png)

## Axis limits

`xlim`/`ylim` override the exposure/response axis limits that
[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md)
otherwise computes automatically from the data:

``` r

erglm_data |>
  er_plot(aucss, ae1, stratify_by = sex) |>
  er_plot_add_model(mod_strat) |>
  er_plot_add_quantiles() |>
  er_plot_add_data() |>
  er_plot_theme(ylim = c(-0.1, 1.1)) |>
  plot()
```

![](theming_files/figure-html/limits-1.png)

## Visual theme

`theme_base` swaps out the overall ggplot2 theme (default
[`ggplot2::theme_bw()`](https://ggplot2.tidyverse.org/reference/ggtheme.html));
`theme_extra` replaces the small set of additional tweaks erplots
applies on top (by default, a panel border plus
`legend.position = "bottom"`). Supplying `theme_extra` **replaces** that
default rather than adding to it, so re-include anything you want to
keep:

``` r

erglm_data |>
  er_plot(aucss, ae1, stratify_by = sex) |>
  er_plot_add_model(mod_strat) |>
  er_plot_add_quantiles() |>
  er_plot_add_data() |>
  er_plot_theme(
    theme_base = ggplot2::theme_minimal(),
    theme_extra = ggplot2::theme(legend.position = "right")
  ) |>
  plot()
```

![](theming_files/figure-html/theme-1.png)

## Discrete color/fill palette

`color_discrete`/`fill_discrete` take a discrete ggplot2 scale object
(e.g. from
[`ggplot2::scale_color_brewer()`](https://ggplot2.tidyverse.org/reference/scale_brewer.html)
or
[`ggplot2::scale_color_viridis_d()`](https://ggplot2.tidyverse.org/reference/scale_viridis.html))
and apply it wherever `colour`/`fill` is genuinely mapped to the
stratification variable:

``` r

erglm_data |>
  er_plot(aucss, ae1, stratify_by = sex) |>
  er_plot_add_model(mod_strat) |>
  er_plot_add_quantiles() |>
  er_plot_add_data() |>
  er_plot_theme(
    color_discrete = ggplot2::scale_color_brewer(palette = "Dark2"),
    fill_discrete = ggplot2::scale_fill_brewer(palette = "Dark2")
  ) |>
  plot()
```

![](theming_files/figure-html/palette-1.png)

This is deliberately scoped to *discrete* palettes only – the palette
used for a continuous/response-colored data layer, or for
[`er_style_data_hex()`](https://erplots.djnavarro.net/reference/er_style_data.md)’s
density fill, isn’t controllable yet (`color_discrete`/`fill_discrete`
are left alone wherever `colour`/`fill` means something other than
strata).

## Formatters

`format_p`/`format_percent`/`format_number` control how the summary and
quantile layers format their labels – typically a `scales::label_*()`
call:

``` r

erglm_data |>
  er_plot(aucss, ae1) |>
  er_plot_add_model(mod) |>
  er_plot_add_quantiles() |>
  er_plot_add_summary(model = mod) |>
  er_plot_theme(
    format_p = scales::label_pvalue(accuracy = .0001),
    format_percent = scales::label_percent(accuracy = .1)
  ) |>
  plot()
```

![](theming_files/figure-html/formatters-1.png)

## Legend key glyph

`draw_key` controls the glyph ggplot2 draws in the legend, e.g. a point
instead of the default filled rectangle:

``` r

erglm_data |>
  er_plot(aucss, ae1, stratify_by = sex) |>
  er_plot_add_model(mod_strat) |>
  er_plot_add_data() |>
  er_plot_theme(draw_key = ggplot2::draw_key_point) |>
  plot()
```

![](theming_files/figure-html/draw-key-1.png)

## Panel heights

`height_base`/`height_data`/`height_group` set the relative heights
patchwork gives to the main panel, any data panels, and any group panels
– supplying only one leaves the other two unchanged:

``` r

erglm_data |>
  er_plot(aucss, ae1) |>
  er_plot_add_model(mod) |>
  er_plot_add_quantiles() |>
  er_plot_add_groups(sex) |>
  er_plot_theme(height_group = 5) |>
  plot()
```

![](theming_files/figure-html/heights-1.png)

## Calling `er_plot_theme()` more than once

Every argument defaults to `NULL`, so repeated calls accumulate rather
than replace: each call only touches the arguments it actually supplies,
the same merging behaviour as
[`ggplot2::theme()`](https://ggplot2.tidyverse.org/reference/theme.html)
itself. This makes it natural to build up theming incrementally,
e.g. once for labels and again later for the palette:

``` r

erglm_data |>
  er_plot(aucss, ae1, stratify_by = sex) |>
  er_plot_add_model(mod_strat) |>
  er_plot_add_data() |>
  er_plot_theme(xlab = "Steady-state AUC") |>
  er_plot_theme(color_discrete = ggplot2::scale_color_brewer(palette = "Dark2")) |>
  plot()
```

![](theming_files/figure-html/accumulate-1.png)

## Where to next

- [The plotting
  grammar](https://erplots.djnavarro.net/articles/design.md) explains
  the layer-composition rules
  [`er_plot_theme()`](https://erplots.djnavarro.net/reference/er_plot_theme.md)
  deliberately doesn’t touch.
- [Extending
  erplots](https://erplots.djnavarro.net/articles/extending.md) shows
  how to write a custom `style` builder, if changing *what’s drawn* –
  rather than *how it looks* – is what you need.
