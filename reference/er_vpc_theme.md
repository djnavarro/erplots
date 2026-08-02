# Adjust theme/labels for an `er_vpc` object

Set axis/legend labels, plot titles/captions, axis limits, theme
objects, and formatters for a VPC. This does not change which variable
is mapped to which aesthetic – that's the builder's job via `style` (see
[`er_style()`](https://erplots.djnavarro.net/reference/er_style.md)).

## Usage

``` r
er_vpc_theme(
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
  format_percent = NULL,
  format_number = NULL
)
```

## Arguments

- object:

  Partially constructed VPC (has S3 class `er_vpc`).

- xlab:

  Label for the VPC's x-axis (single string) – see "Details" for why
  this labels `plot_by`, not `exposure`.

- ylab:

  Response axis label (single string).

- strata_lab:

  Facet strip label prefix (single string), e.g. the `"Sex"` in a
  `"Sex: Female"` strip. Errors if `stratify_by` wasn't set in
  [`er_vpc()`](https://erplots.djnavarro.net/reference/er_vpc.md) –
  there's no facet strip to relabel.

- title, subtitle, caption:

  Plot-level annotation text (single strings).

- xlim, ylim:

  Axis limits (length-2, increasing numeric vectors), applied via
  `ggplot2::coord_cartesian(clip = "off")`.

- theme_base:

  A ggplot2 theme object (e.g.
  [`ggplot2::theme_minimal()`](https://ggplot2.tidyverse.org/reference/ggtheme.html))
  – the swappable overall visual theme, defaulting to
  [`ggplot2::theme_bw()`](https://ggplot2.tidyverse.org/reference/ggtheme.html).

- theme_extra:

  A ggplot2 theme object (e.g. from
  [`ggplot2::theme()`](https://ggplot2.tidyverse.org/reference/theme.html))
  with additional theme tweaks layered on top of `theme_base`. See
  "Details" for its default and replacement semantics.

- format_percent, format_number:

  Formatter functions (typically from `scales::label_*()`), used to
  format the rate/mean displayed in the observed/simulated summaries for
  a binary response (`format_percent`) or a continuous/count response
  (`format_number`).

## Value

The input `object`, with the requested theme fields updated.

## Details

Every argument defaults to `NULL`, meaning "leave whatever was set
before unchanged". This allows repeated calls to `er_vpc_theme()` to
update only the supplied fields, like
[`ggplot2::theme()`](https://ggplot2.tidyverse.org/reference/theme.html).
There is no implicit way to reset a field to the
[`er_vpc()`](https://erplots.djnavarro.net/reference/er_vpc.md) default.

`xlab` labels `plot_by` (stored on `object$group$label`), not `exposure`
– `plot_by` drives the VPC's actual x-axis, and the two only coincide
when the caller didn't override `plot_by` in
[`er_vpc()`](https://erplots.djnavarro.net/reference/er_vpc.md).

`theme_extra` defaults to a panel border plus
`legend.position = "bottom"`. Supplying a new value fully replaces this
default rather than merging with it, so re-include the
border/legend-position settings too if you want to keep them alongside
your own additions.

Unlike
[`er_plot_theme()`](https://erplots.djnavarro.net/reference/er_plot_theme.md),
there is no `color_discrete`/`fill_discrete` argument here: the
observed-vs-simulated colour/fill distinction uses a fixed, shared scale
(see the "Gotchas" section of `AGENTS.md`) to keep the two aligned
across builders that mix colour and fill for the same idea, and swapping
it out is not yet supported. Adding
`+ ggplot2::scale_colour_manual(...)`/`+ ggplot2::scale_fill_manual(...)`
to the built/returned ggplot2 object remains the escape hatch for this,
and for any other tweak not covered by this function's arguments (e.g.
`draw_key`, which isn't wired up for any built-in VPC builder).

## See also

[`er_vpc()`](https://erplots.djnavarro.net/reference/er_vpc.md),
[`er_style()`](https://erplots.djnavarro.net/reference/er_style.md)

## Examples

``` r
if (requireNamespace("erglm", quietly = TRUE)) {
  library(erglm)
  mod <- erglm_model(ae1 ~ aucss, erglm_data, family = binomial())

  erglm_data |>
    er_vpc(aucss, ae1) |>
    er_vpc_add_observed() |>
    er_vpc_add_simulated(model = mod, seed = 1234) |>
    er_vpc_theme(
      xlab = "AUC at steady state",
      ylab = "Probability of event",
      title = "Visual predictive check"
    ) |>
    plot()
}

```
