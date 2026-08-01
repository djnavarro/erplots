# Observed-layer builders for VPC plots

Builder functions for the `observed` layer
([`er_vpc_add_observed()`](https://erplots.djnavarro.net/reference/er_vpc_add_observed.md)),
drawing the observed side of a visual predictive check as a mean/rate +
confidence interval per bin (the default, adaptive to `plot_by`'s type),
a continuous-x line of empirical percentiles, or a point/interval per
bin *and* per requested percentile.

## Usage

``` r
er_style_vpc_observed_quantile_line(
  data,
  config,
  exposure,
  response,
  theme,
  point_size = 1.5,
  ...
)

er_style_vpc_observed_quantile_errorbar(
  data,
  config,
  exposure,
  response,
  theme,
  point_size = 1.5,
  errorbar_width = 0.15,
  errorbar_width_continuous = 0.025,
  dodge = 0,
  prob_dodge_width = 0,
  ...
)

er_style_vpc_observed_mean_errorbar(
  data,
  config,
  exposure,
  response,
  theme,
  point_size = 2,
  errorbar_width = 0.2,
  errorbar_width_continuous = 0.025,
  dodge = 0,
  ...
)
```

## Arguments

- data:

  The original data frame.

- config:

  Configuration for the observed layer.

- exposure:

  Exposure variable.

- response:

  Response variable.

- theme:

  Theme components.

- point_size:

  Point size for all three point/interval builders.

- ...:

  Additional named arguments forwarded from
  [`er_vpc_add_observed()`](https://erplots.djnavarro.net/reference/er_vpc_add_observed.md)'s
  own `...`.

- errorbar_width:

  Width of `er_style_vpc_observed_mean_errorbar()`'s and
  `er_style_vpc_observed_quantile_errorbar()`'s error bars when
  `plot_by` is categorical.

- errorbar_width_continuous:

  Width (as a fraction of `plot_by`'s own range, `config$group_limits`)
  of `er_style_vpc_observed_mean_errorbar()`'s and
  `er_style_vpc_observed_quantile_errorbar()`'s error bars when
  `plot_by` is numeric.

- dodge:

  Horizontal offset (as a fraction of `plot_by`'s own range, like
  `errorbar_width_continuous`) applied to all of this builder's error
  bars/points, for both `er_style_vpc_observed_mean_errorbar()` and
  `er_style_vpc_observed_quantile_errorbar()`. Default `0` (no offset,
  the previous behaviour). Useful for manually separating the observed
  layer from an overlapping simulated one at the same bin – e.g.
  `dodge = -0.01` on the observed builder paired with `dodge = 0.01` on
  the corresponding simulated builder. Only supported when `plot_by` is
  numeric; a nonzero value is ignored with a warning for a categorical
  `plot_by`, where dodging isn't implemented yet.

- prob_dodge_width:

  Horizontal spread (as a fraction of `plot_by`'s own range) applied to
  `er_style_vpc_observed_quantile_errorbar()`'s requested `probs` within
  a single bin, symmetrically centred on that bin's own position (added
  on top of `dodge`, if also supplied). Default `0` (all `probs` plotted
  at the same position, the previous behaviour). Useful when several
  `probs`' error bars overlap enough to be unreadable. Same
  numeric-`plot_by`-only restriction as `dodge`.

## Value

A list of geoms; see
[`er_style()`](https://erplots.djnavarro.net/reference/er_style.md).

## Details

`er_style_vpc_observed_mean_errorbar()` (the default) plots
`config$summary`'s rate/mean + confidence interval, adapting its
x-position to `plot_by`'s type (`config$is_numeric_group`): equally
spaced at each bin's categorical (or quantile-bin) label when `plot_by`
is categorical, or at each bin's numeric median (`x_median`, from
`config$summary`) on `plot_by`'s own numeric scale when `plot_by` is
numeric. Because it adapts its x-position family at build time rather
than declaring one statically, it carries no `layout` tag – pair it with
[`er_style_vpc_simulated_mean_errorbar()`](https://erplots.djnavarro.net/reference/er_style_vpc_simulated.md),
which mirrors the same adaptive logic.

`er_style_vpc_observed_quantile_line()` plots `config$percentiles` – one
line per requested percentile – at each bin's numeric midpoint on
`plot_by`'s own numeric scale, for pairing with
[`er_style_vpc_simulated_quantile_ribbon()`](https://erplots.djnavarro.net/reference/er_style_vpc_simulated.md).
`config$percentiles` is only computed for a continuous/count response
(see [`er_vpc()`](https://erplots.djnavarro.net/reference/er_vpc.md)'s
`probs` argument); calling `er_style_vpc_observed_quantile_line()`
without it errors.

`er_style_vpc_observed_quantile_errorbar()` plots `config$percentiles` –
a point + confidence interval (via
[`ci_quantile()`](https://erplots.djnavarro.net/reference/ci_quantile.md))
for each requested percentile – for pairing with
[`er_style_vpc_simulated_quantile_errorbar()`](https://erplots.djnavarro.net/reference/er_style_vpc_simulated.md).
Like `er_style_vpc_observed_mean_errorbar()`, it adapts its x-position
to `plot_by`'s type (`config$is_numeric_group`): equally spaced at each
bin's categorical (or quantile-bin) label when `plot_by` is categorical,
or at each bin's numeric median (`x_median`, from `config$percentiles`)
on `plot_by`'s own numeric scale when `plot_by` is numeric. Because it
adapts its x-position family at build time rather than declaring one
statically, it carries no `layout` tag. Unlike
`er_style_vpc_observed_quantile_line()`/
[`er_style_vpc_simulated_quantile_ribbon()`](https://erplots.djnavarro.net/reference/er_style_vpc_simulated.md),
it supports a categorical `plot_by` as well as a numeric one; like it,
it requires a continuous/count response (a binary response's
distribution is already fully described by its rate) and errors
informatively without `config$percentiles`. When more than one
percentile is requested, all of them are currently plotted at the same
x-position within a bin rather than dodged apart, so overlapping error
bars/points are only distinguishable by their y-position – dodging
support may be added in a future release.

Each builder maps a constant `color = "Observed"`, so ggplot2 merges its
legend entry with whatever the paired simulated-layer builder maps for
`"Simulated"` into a single combined legend.

In the worst case – `er_style_vpc_observed_quantile_errorbar()` paired
with
[`er_style_vpc_simulated_quantile_errorbar()`](https://erplots.djnavarro.net/reference/er_style_vpc_simulated.md)
for a numeric `plot_by` with several `probs` – up to `2 * length(probs)`
error bars land at the exact same x-position within a bin (every `probs`
value, for both the observed and simulated layers), which can be
unreadable. `dodge` (separating the observed and simulated layers) and
`prob_dodge_width` (spreading a single layer's own `probs` apart) are
both opt-in, manual escape hatches for this – see their own argument
docs above. Neither is automatic, because which collision is actually
occurring (source-vs-source, `probs`-vs-`probs`, or both) depends on the
data at hand.

## See also

[`er_style()`](https://erplots.djnavarro.net/reference/er_style.md),
[`er_style_vpc_simulated()`](https://erplots.djnavarro.net/reference/er_style_vpc_simulated.md)
