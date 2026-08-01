# Tag a builder with structural/aesthetic metadata

Attaches the self-declared metadata a custom `er_style_*()`-style
function can carry.

## Usage

``` r
er_style_tag(
  style,
  layout = NULL,
  fill_role = NULL,
  y_role = NULL,
  layer = NULL,
  zorder = NULL,
  response_types = NULL,
  plot_by_types = NULL
)
```

## Arguments

- style:

  A function matching the standard `er_style_*()` signature (see
  [`er_style()`](https://erplots.djnavarro.net/reference/er_style.md)).

- layout:

  One of `"overlay"`, `"panel"`, `"categorical"`, or `"continuous"`, or
  `NULL` (the default) to leave this tag unset. The
  `"overlay"`/`"panel"` pair is for a data-layer builder
  ([`er_plot_add_data()`](https://erplots.djnavarro.net/reference/er_plot_add_data.md)
  documents what each structural family means); the `"categorical"`/
  `"continuous"` pair is for a VPC observed/simulated builder
  ([`er_vpc_add_observed()`](https://erplots.djnavarro.net/reference/er_vpc_add_observed.md)/[`er_vpc_add_simulated()`](https://erplots.djnavarro.net/reference/er_vpc_add_simulated.md))
  and marks whether it plots at discrete bin locations or at each bin's
  numeric exposure midpoint – see
  [`er_style_vpc_observed()`](https://erplots.djnavarro.net/reference/er_style_vpc_observed.md)/[`er_style_vpc_simulated()`](https://erplots.djnavarro.net/reference/er_style_vpc_simulated.md).

- fill_role:

  A string naming what the builder's `fill` aesthetic represents, or
  `NULL` (the default) to leave this tag unset.

- y_role:

  A string naming what the builder's y-axis represents, or `NULL` (the
  default) to leave this tag unset.

- layer:

  One of `"model"`, `"summary"`, `"quantile"`, `"data"`, `"group"`,
  `"observed"`, or `"simulated"`, naming which
  `er_plot_add_*()`/`er_vpc_add_*()` layer the builder is meant to be
  used with, or `NULL` (the default) to leave this tag unset. See
  "Details".

- zorder:

  One of `"foreground"` or `"background"`, or `NULL` (the default,
  equivalent to `"foreground"`) to leave this tag unset. Only meaningful
  for an overlay-layout data builder; see "Details".

- response_types:

  A character vector with one or more of `"binary"`, `"continuous"`,
  `"count"`, or `NULL` (the default) to leave this tag unset (no
  restriction declared). For a VPC observed/simulated builder, declares
  which of
  [`er_vpc()`](https://erplots.djnavarro.net/reference/er_vpc.md)'s
  `response_type` values the builder supports; see "Details".

- plot_by_types:

  A character vector with one or more of `"continuous"`, `"discrete"`,
  or `NULL` (the default) to leave this tag unset. For a VPC
  observed/simulated builder, declares which of `object$group$type`
  values (see
  [`er_vpc()`](https://erplots.djnavarro.net/reference/er_vpc.md)'s
  `plot_by` argument) the builder supports; see "Details".

## Value

`style`, with whichever of the `"er_style_layout"`/
`"er_style_fill_role"`/`"er_style_y_role"`/`"er_style_layer"`/
`"er_style_zorder"`/`"er_style_response_types"`/
`"er_style_plot_by_types"` attributes were requested attached.

## Details

The metadata to be supplied indicate which *structural* family a
data-layer builder belongs to (`layout`), what a builder's `fill`
aesthetic means when it isn't strata (`fill_role`), what a group-layer
builder's y-axis means when it isn't the group variable itself
(`y_role`), which layer a builder is meant to be plugged into (`layer`),
and where an overlay-layout data builder's geoms sit relative to the
model/summary/quantile layers when they share the main panel (`zorder`).
All five arguments are optional and independent – pass only the ones a
given builder needs, in one call, rather than chaining separate setters.

`layout` is a required tag for a data-layer builder:
[`er_plot_add_data()`](https://erplots.djnavarro.net/reference/er_plot_add_data.md)
reads it off `style` to decide whether to place the output geoms into
the main panel (`layout = "overlay"`) or to put them into separate
strip-like panels above and below the main panel (`layout = "panel"`)

For a VPC observed/simulated builder, `layout` is optional but, when
present on both the observed and simulated builder passed to a given
`er_vpc` object, is checked for agreement:
[`er_vpc_add_simulated()`](https://erplots.djnavarro.net/reference/er_vpc_add_simulated.md)
errors if the simulated builder's `layout` (`"categorical"`, discrete
bin locations; or `"continuous"`, numeric bin-midpoint locations, e.g.
[`er_style_vpc_simulated_quantile_ribbon()`](https://erplots.djnavarro.net/reference/er_style_vpc_simulated.md))
disagrees with the observed builder's own. This catches the case where
the two families would otherwise silently plot at different x-positions
for the same bin – e.g. pairing a builder that always plots at discrete
bin labels with
[`er_style_vpc_simulated_quantile_ribbon()`](https://erplots.djnavarro.net/reference/er_style_vpc_simulated.md)'s
numeric midpoints. Use a layout-matched pair instead (built-ins already
are), or leave `layout` untagged – as
[`er_style_vpc_observed_mean_errorbar()`](https://erplots.djnavarro.net/reference/er_style_vpc_observed.md)/
[`er_style_vpc_simulated_mean_errorbar()`](https://erplots.djnavarro.net/reference/er_style_vpc_simulated.md)
and
[`er_style_vpc_observed_quantile_errorbar()`](https://erplots.djnavarro.net/reference/er_style_vpc_observed.md)/
[`er_style_vpc_simulated_quantile_errorbar()`](https://erplots.djnavarro.net/reference/er_style_vpc_simulated.md)
do, since both pairs adapt their x-position to `plot_by`'s type at build
time rather than declaring one family statically – to skip the check
entirely, the same opt-in treatment `layer` gets.

`fill_role` and `y_role` are both optional, and can be used to title a
legend/axis correctly: `fill_role = "density"` (used by
[`er_style_data_hex()`](https://erplots.djnavarro.net/reference/er_style_data.md))
says a builder's `fill` aesthetic encodes bin density rather than
strata; `y_role = "count"` (used by
[`er_style_group_histogram()`](https://erplots.djnavarro.net/reference/er_style_group.md))
says a group-layer builder's y-axis means counts rather than the group
variable itself. A builder that omits either tag keeps the default
behaviour (`fill` means strata; the y-axis is titled with the group
variable's label), which is correct for most builders.

`layer` is also optional, but unlike `fill_role`/`y_role` it isn't read
for labelling. It's read by every `er_plot_add_*()` function
([`er_plot_add_model()`](https://erplots.djnavarro.net/reference/er_plot_add_model.md)
checks `style` against `"model"`;
[`er_plot_add_summary()`](https://erplots.djnavarro.net/reference/er_plot_add_summary.md)
checks `style` against `"summary"`;
[`er_plot_add_quantiles()`](https://erplots.djnavarro.net/reference/er_plot_add_quantiles.md)
against `"quantile"`;
[`er_plot_add_data()`](https://erplots.djnavarro.net/reference/er_plot_add_data.md)
against `"data"`;
[`er_plot_add_groups()`](https://erplots.djnavarro.net/reference/er_plot_add_groups.md)
against `"group"`) to catch a builder plugged into the wrong layer –
e.g. passing a quantile builder to
[`er_plot_add_data()`](https://erplots.djnavarro.net/reference/er_plot_add_data.md)
– with an informative error instead of whatever failure results from
that layer's `config` shape not matching what the builder expects. All
built-in builders carry this tag. A custom builder that omits it is
never checked: `layer` is opt-in, not a requirement like `layout` is for
a data-layer builder.

`zorder` only applies to an overlay-layout data builder
(`layout = "overlay"`), and controls whether its geoms are drawn before
or after the model/summary/quantile layers when they share the main
panel. `"foreground"`, the default for a builder that omits this tag
(e.g.
[`er_style_data_overlay()`](https://erplots.djnavarro.net/reference/er_style_data.md)),
draws the data geoms last, on top of everything else – appropriate for a
sparse layer like individual points, which should never be hidden behind
a model ribbon. `"background"` (used by
[`er_style_data_hex()`](https://erplots.djnavarro.net/reference/er_style_data.md))
draws the data geoms first, so a builder whose geoms cover the whole
panel (leaving no gaps for what's underneath to show through) doesn't
bury the model curve or summary annotation. `zorder` has no effect on a
panel-layout data builder (e.g.
[`er_style_data_boxjitter()`](https://erplots.djnavarro.net/reference/er_style_data.md)),
since those geoms are drawn in their own separate panels, never sharing
space with the model/ summary/quantile layers.

`response_types` and `plot_by_types` are both optional, and – unlike
every other tag above – are checked against the *data*, not another
builder:
[`er_vpc_add_observed()`](https://erplots.djnavarro.net/reference/er_vpc_add_observed.md)/[`er_vpc_add_simulated()`](https://erplots.djnavarro.net/reference/er_vpc_add_simulated.md)
each check `style`'s declared `response_types` against
`object$response$type` and `plot_by_types` against `object$group$type`,
erroring immediately if the object's data isn't one the builder declared
support for – e.g.
[`er_style_vpc_observed_quantile_line()`](https://erplots.djnavarro.net/reference/er_style_vpc_observed.md)
declares `response_types = c("continuous", "count")` (it needs
`config$percentiles`, never computed for a binary response) and
`plot_by_types = "continuous"` (it draws a `geom_line()` connecting bins
along the numeric midpoint, meaningless for an unordered categorical
`plot_by`). This catches an incompatible builder/data pairing at the
`er_vpc_add_*()` call site, before any binning or summarising happens,
rather than only when the builder itself is finally invoked by
[`plot()`](https://rdrr.io/r/graphics/plot.default.html)/[`er_vpc_build()`](https://erplots.djnavarro.net/reference/er_vpc_build.md).
As with `layer`, both tags are opt-in – an untagged builder is never
checked against either, so a custom builder that doesn't declare them
keeps working unchanged (though it's then responsible for guarding
against its own incompatible inputs, the way every built-in VPC builder
still does internally as a fallback).

## See also

[`er_plot_add_data()`](https://erplots.djnavarro.net/reference/er_plot_add_data.md),
[`er_style()`](https://erplots.djnavarro.net/reference/er_style.md)

## Examples

``` r
build_data_density <- er_style_tag(
  function(data, config, stratify, exposure, response, strata, theme, ...) {
    ggplot2::geom_density_2d(
      data = data,
      mapping = ggplot2::aes(x = .data[[exposure$name]], y = .data[[response$name]])
    )
  },
  layout = "overlay",
  layer = "data"
)
```
