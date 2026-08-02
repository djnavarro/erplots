# Simulated-layer builders for VPC plots

Builder functions for the `simulated` layer
([`er_vpc_add_simulated()`](https://erplots.djnavarro.net/reference/er_vpc_add_simulated.md)),
drawing the simulated side of a visual predictive check as a mean +
percentile interval per bin (the default, adaptive to `plot_by`'s type),
continuous-x percentile bands, or a point/interval per bin *and* per
requested percentile.

## Usage

``` r
er_style_vpc_simulated_quantile_ribbon(
  data,
  config,
  exposure,
  response,
  theme,
  ribbon_alpha = 0.3,
  ribbon_edges = FALSE,
  edge_linetype = "dotted",
  edge_linewidth = 0.5,
  edge_colour = "grey50",
  median_linetype = "dashed",
  median_linewidth = 0.5,
  median_colour = "grey30",
  ...
)

er_style_vpc_simulated_quantile_errorbar(
  data,
  config,
  exposure,
  response,
  theme,
  point_size = 1.5,
  errorbar_width = NULL,
  dodge = 0,
  prob_dodge_width = 0,
  ...
)

er_style_vpc_simulated_mean_errorbar(
  data,
  config,
  exposure,
  response,
  theme,
  point_size = 2,
  errorbar_width = NULL,
  dodge = 0,
  ...
)
```

## Arguments

- data:

  The original data frame.

- config:

  Configuration for the simulated layer.

- exposure:

  Exposure variable.

- response:

  Response variable.

- theme:

  Theme components.

- ribbon_alpha:

  Fill transparency for `er_style_vpc_simulated_quantile_ribbon()`'s
  bands.

- ribbon_edges:

  Whether `er_style_vpc_simulated_quantile_ribbon()` additionally draws
  a line along each band's own `ci_lower`/`ci_upper` bounds, on top of
  the shaded ribbon fill – mirrors
  [`er_style_model_ribbonline()`](https://erplots.djnavarro.net/reference/er_style_model.md)'s
  own `ribbon_edges` argument. Default `FALSE` (ribbon fill only).
  Useful when several requested percentiles' bands overlap: the edge
  lines stay legible even where the fills merge into an
  indistinguishable blob.

- edge_linetype, edge_linewidth, edge_colour:

  Styling for `er_style_vpc_simulated_quantile_ribbon()`'s optional edge
  lines (only drawn when `ribbon_edges = TRUE`). Defaults to a thin,
  light dotted line (`"dotted"`, `0.5`, `"grey50"`) that stays
  unobtrusive even when several bands' edges overlap.

- median_linetype, median_linewidth, median_colour:

  Styling for `er_style_vpc_simulated_quantile_ribbon()`'s median line,
  drawn at each band's `y_mid`. Defaults match the previous fixed
  styling (`"dashed"`, `0.5`, `"grey30"`).

- ...:

  Additional named arguments forwarded from
  [`er_vpc_add_simulated()`](https://erplots.djnavarro.net/reference/er_vpc_add_simulated.md)'s
  own `...`.

- point_size:

  Point size for both point/interval builders.

- errorbar_width:

  Width of `er_style_vpc_simulated_mean_errorbar()`'s and
  `er_style_vpc_simulated_quantile_errorbar()`'s error bars. Interpreted
  differently depending on `plot_by`'s type: for a categorical
  `plot_by`, it's a bar width in the same implied unit-scaled
  category-gap units
  [`ggplot2::geom_errorbar()`](https://ggplot2.tidyverse.org/reference/geom_linerange.html)
  normally expects; for a numeric `plot_by`, it's a fraction of
  `plot_by`'s own range (`config$group_limits`), so `1` would span the
  full range. Defaults to `NULL`, which resolves to `0.15`
  (`er_style_vpc_simulated_quantile_errorbar()`) or `0.2`
  (`er_style_vpc_simulated_mean_errorbar()`) for a categorical
  `plot_by`, or `0.025` for a numeric one.

- dodge:

  Horizontal offset (as a fraction of `plot_by`'s own range, like
  `errorbar_width` for a numeric `plot_by`) applied to all of this
  builder's error bars/points, for both
  `er_style_vpc_simulated_mean_errorbar()` and
  `er_style_vpc_simulated_quantile_errorbar()`. Default `0` (no offset,
  the previous behaviour); pair with an opposite-signed `dodge` on the
  corresponding observed builder to manually separate the two layers
  where they'd otherwise overlap at the same bin. See
  [`er_style_vpc_observed()`](https://erplots.djnavarro.net/reference/er_style_vpc_observed.md)'s
  own `dodge` docs for the full explanation, including the
  categorical-`plot_by` restriction.

- prob_dodge_width:

  Horizontal spread (as a fraction of `plot_by`'s own range) applied to
  `er_style_vpc_simulated_quantile_errorbar()`'s requested `probs`
  within a single bin. Default `0` (the previous behaviour); see
  [`er_style_vpc_observed()`](https://erplots.djnavarro.net/reference/er_style_vpc_observed.md)'s
  own `prob_dodge_width` docs.

## Value

A list of geoms; see
[`er_style()`](https://erplots.djnavarro.net/reference/er_style.md).

## Details

`er_style_vpc_simulated_mean_errorbar()` (the default) plots
`config$summary`'s mean + percentile interval (of the mean, across
replicates), adapting its x-position to `plot_by`'s type
(`config$is_numeric_group`): equally spaced at each bin's categorical
(or quantile-bin) label when `plot_by` is categorical, or at each bin's
numeric median (`x_median`, from `config$summary`) on the `plot_by`'s
own numeric scale when `plot_by` is numeric. Because it adapts its
x-position family at build time rather than declaring one statically, it
carries no `layout` tag – pair it with
[`er_style_vpc_observed_mean_errorbar()`](https://erplots.djnavarro.net/reference/er_style_vpc_observed.md),
which mirrors the same adaptive logic.

`er_style_vpc_simulated_quantile_ribbon()` plots `config$percentiles` –
one shaded band (median line + interval) per requested percentile – at
each bin's numeric midpoint on `plot_by`'s own numeric scale, for
pairing with
[`er_style_vpc_observed_quantile_line()`](https://erplots.djnavarro.net/reference/er_style_vpc_observed.md).
`config$percentiles` is only computed for a continuous/count response
(see [`er_vpc()`](https://erplots.djnavarro.net/reference/er_vpc.md)'s
`probs` argument); calling `er_style_vpc_simulated_quantile_ribbon()`
without it errors.

`er_style_vpc_simulated_quantile_errorbar()` plots `config$percentiles`
– a point + across-replicate percentile interval for each requested
percentile – for pairing with
[`er_style_vpc_observed_quantile_errorbar()`](https://erplots.djnavarro.net/reference/er_style_vpc_observed.md).
Like that builder (and like `er_style_vpc_simulated_mean_errorbar()`),
it adapts its x-position to `plot_by`'s type, carries no `layout` tag,
supports both a numeric and a categorical `plot_by`, and requires a
continuous/count response, erroring informatively without
`config$percentiles`. As with the observed-layer counterpart, when more
than one percentile is requested they are currently all plotted at the
same x-position within a bin rather than dodged apart.

`er_style_vpc_simulated_mean_errorbar()`/`er_style_vpc_simulated_quantile_errorbar()`
map a constant `color = "Simulated"`;
`er_style_vpc_simulated_quantile_ribbon()` maps a constant
`fill = "Simulated"`. ggplot2 merges either into the paired observed
builder's own `"Observed"` legend entry (same aesthetic) into one
combined legend; the ribbon's `fill` legend is separate from the
point/errorbar builders' `color` legend.

When several requested percentiles' bands sit close together (small
per-bin samples, few simulated replicates, or `probs` values close to
one another), `er_style_vpc_simulated_quantile_ribbon()`'s bands can
overlap enough that the shaded fills merge into a single
indistinguishable region, and its median lines – all styled identically
– become the only way to tell the bands apart, which fails wherever two
of them cross. `ribbon_edges = TRUE` mitigates this by drawing each
band's own `ci_lower`/`ci_upper` bounds as a line (see
`edge_linetype`/`edge_linewidth`/`edge_colour`), which stays legible
even where the fills themselves are illegible.

## See also

[`er_style()`](https://erplots.djnavarro.net/reference/er_style.md),
[`er_style_vpc_observed()`](https://erplots.djnavarro.net/reference/er_style_vpc_observed.md)
