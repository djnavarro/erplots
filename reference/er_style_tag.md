# Register a builder's structural/aesthetic metadata

`er_style_tag()` is the shared self-declaration mechanism every
`er_style_*()` builder – across all three grammars,
[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md)/
[`er_vpc()`](https://erplots.djnavarro.net/reference/er_vpc.md)/[`er_tte()`](https://erplots.djnavarro.net/reference/er_tte.md)
alike – can opt into, attaching metadata that the relevant `_add_*()`
function later reads back off it and checks itself against.

## Usage

``` r
er_style_tag(
  style,
  layout = NULL,
  vpc_layout = NULL,
  fill_role = NULL,
  y_role = NULL,
  layer = NULL,
  draw_order = NULL,
  response_types = NULL,
  plot_by_types = NULL,
  marker_source = NULL,
  label = NULL,
  overwrite = FALSE
)
```

## Arguments

- style:

  A function matching the standard signature for the grammar it's meant
  for – see
  [`er_style()`](https://erplots.djnavarro.net/reference/er_style.md)
  ([`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md)),
  [`er_style_vpc()`](https://erplots.djnavarro.net/reference/er_style_vpc.md)
  ([`er_vpc()`](https://erplots.djnavarro.net/reference/er_vpc.md)), or
  [`er_style_tte()`](https://erplots.djnavarro.net/reference/er_style_tte.md)
  ([`er_tte()`](https://erplots.djnavarro.net/reference/er_tte.md)).

- layout:

  One of `"overlay"` or `"panel"`, or `NULL` (the default) to leave this
  tag unset. Data-layer
  ([`er_plot_add_data()`](https://erplots.djnavarro.net/reference/er_plot_add_data.md))
  builders only – see "Details".

- vpc_layout:

  One of `"categorical"` or `"continuous"`, or `NULL` (the default) to
  leave this tag unset. VPC observed/simulated
  ([`er_vpc_add_observed()`](https://erplots.djnavarro.net/reference/er_vpc_add_observed.md)/[`er_vpc_add_simulated()`](https://erplots.djnavarro.net/reference/er_vpc_add_simulated.md))
  builders only – see "Details".

- fill_role:

  A string naming what the builder's `fill` aesthetic represents, or
  `NULL` (the default) to leave this tag unset.

- y_role:

  A string naming what the builder's y-axis represents, or `NULL` (the
  default) to leave this tag unset.

- layer:

  One of `"plot_model"`, `"plot_summary"`, `"plot_quantile"`,
  `"plot_data"`, `"plot_group"`, `"vpc_observed"`, `"vpc_simulated"`,
  `"tte_curve"`, `"tte_censor"`, `"tte_risktable"`, `"tte_model"`, or
  `"tte_summary"`, naming which
  `er_plot_add_*()`/`er_vpc_add_*()`/`er_tte_add_*()` layer the builder
  is meant to be used with, or `NULL` (the default) to leave this tag
  unset. Each value is prefixed with the grammar it belongs to
  (`plot_`/`vpc_`/`tte_`) – see "Details".

- draw_order:

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

- marker_source:

  One of `"summary"` or `"percentiles"`, naming which of a VPC
  observed/simulated builder's two config tables (`config$summary` or
  `config$percentiles`) it actually draws its marker(s) from, or `NULL`
  (the default) to leave this tag unset. See "Details".

- label:

  A single string, or `NULL` (the default) to leave this tag unset.
  Requires `layer` to also be set in the same call. Registers `style` so
  it can be selected by this short string (e.g. `style = "logrank"`)
  instead of the function itself, wherever the corresponding `_add_*()`
  function looks it up. See
  [`er_style_labels()`](https://erplots.djnavarro.net/reference/er_style_labels.md).

- overwrite:

  Logical, default `FALSE`. Only meaningful together with `label`;
  ignored otherwise. Controls what happens when the `(layer, label)`
  pair is already registered to a *different* function: `FALSE` (the
  default) errors; `TRUE` replaces the existing registration
  unconditionally. Re-registering the identical function is always a
  silent no-op regardless of `overwrite`. See "Details".

## Value

`style`, with whichever of the `"er_style_layout"`/
`"er_style_vpc_layout"`/`"er_style_fill_role"`/`"er_style_y_role"`/
`"er_style_layer"`/`"er_style_draw_order"`/`"er_style_response_types"`/
`"er_style_plot_by_types"`/`"er_style_vpc_marker_source"`/
`"er_style_label"` attributes were requested attached. When `label` is
supplied, `style` is also registered as a side effect – see
[`er_style_labels()`](https://erplots.djnavarro.net/reference/er_style_labels.md).

## Details

In that sense it functions as an informal builder registry – not a
lookup table you register *into*, but a way of stamping a function with
metadata another function can later read back off it and act on,
entirely by attribute, with no central list anywhere. Every built-in
builder carries a tag; nothing requires a custom builder to.

Ten tags exist today, each optional and independent – pass only the ones
a given builder needs, in one call, rather than chaining separate
setters. They fall into four groups, one per section below:

- Structural tags (`layout`, `vpc_layout`) – which structural family a
  builder belongs to.

- The layer tag (`layer`) – which layer a builder is meant to be plugged
  into.

- Rendering and labelling hints (`fill_role`, `y_role`, `draw_order`).

- Type-checking tags for VPC builders (`response_types`,
  `plot_by_types`, `marker_source`).

- Registering a label (`label`, `overwrite`).

## Structural tags

`layout` is a required tag for a data-layer builder specifically:
[`er_plot_add_data()`](https://erplots.djnavarro.net/reference/er_plot_add_data.md)
reads it off `style` to decide whether to place the output geoms into
the main panel (`layout = "overlay"`) or to put them into separate
strip-like panels above and below the main panel (`layout = "panel"`).
No other layer or grammar uses this tag.

`vpc_layout` is the VPC analogue, but optional rather than required, and
checked between two builders rather than read for a structural decision:
when present on both the observed and simulated builder passed to a
given `er_vpc` object,
[`er_vpc_add_simulated()`](https://erplots.djnavarro.net/reference/er_vpc_add_simulated.md)
errors if they disagree (`"categorical"`, discrete bin locations; or
`"continuous"`, numeric bin-midpoint locations, e.g.
[`er_style_vpc_simulated_quantile_ribbon()`](https://erplots.djnavarro.net/reference/er_style_vpc_simulated.md)).
This catches the case where the two families would otherwise silently
plot at different x-positions for the same bin – e.g. pairing a builder
that always plots at discrete bin labels with
[`er_style_vpc_simulated_quantile_ribbon()`](https://erplots.djnavarro.net/reference/er_style_vpc_simulated.md)'s
numeric midpoints. Use a layout-matched pair instead (built-ins already
are), or leave `vpc_layout` untagged – as
[`er_style_vpc_observed_mean_errorbar()`](https://erplots.djnavarro.net/reference/er_style_vpc_observed.md)/
[`er_style_vpc_simulated_mean_errorbar()`](https://erplots.djnavarro.net/reference/er_style_vpc_simulated.md)
and
[`er_style_vpc_observed_quantile_errorbar()`](https://erplots.djnavarro.net/reference/er_style_vpc_observed.md)/
[`er_style_vpc_simulated_quantile_errorbar()`](https://erplots.djnavarro.net/reference/er_style_vpc_simulated.md)
do, since both pairs adapt their x-position to `plot_by`'s type at build
time rather than declaring one family statically – to skip the check
entirely, the same opt-in treatment `layer` gets.

## The layer tag

`layer` is optional, but unlike `fill_role`/`y_role` it isn't read for
labelling. It's read by every `er_plot_add_*()`/`er_vpc_add_*()`/
`er_tte_add_*()` function to catch a builder plugged into the wrong
layer – e.g. passing a quantile builder to
[`er_plot_add_data()`](https://erplots.djnavarro.net/reference/er_plot_add_data.md),
or an [`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md)
summary builder to
[`er_tte_add_summary()`](https://erplots.djnavarro.net/reference/er_tte_add_summary.md)
– with an informative error instead of whatever failure results from
that layer's `config` shape not matching what the builder expects. All
built-in builders carry this tag. It is a flat namespace checked only by
string equality, but every value is grammar-prefixed by convention
(`plot_`/`vpc_`/`tte_`) – e.g. `"plot_model"`/`"plot_summary"` for
[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md) vs.
`"tte_model"`/`"tte_summary"` for
[`er_tte()`](https://erplots.djnavarro.net/reference/er_tte.md) – so two
grammars whose builders share neither a signature nor a `config` shape
can never collide by accident, and the prefix also makes a value's
owning grammar legible on sight, including in
[`er_style_labels()`](https://erplots.djnavarro.net/reference/er_style_labels.md)'s
own `layer` column. A custom builder that omits `layer` is never
checked: it is opt-in, not a requirement like `layout` is for a
data-layer builder.

## Rendering and labelling hints

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

`draw_order` only applies to an overlay-layout data builder
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
bury the model curve or summary annotation. `draw_order` has no effect
on a panel-layout data builder (e.g.
[`er_style_data_boxjitter()`](https://erplots.djnavarro.net/reference/er_style_data.md)),
since those geoms are drawn in their own separate panels, never sharing
space with the model/ summary/quantile layers.

## Type-checking tags for VPC builders

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

`marker_source` is also optional and VPC-specific. It's used when
cropping a built VPC to `xlim`/`ylim` (see
[`er_vpc_theme()`](https://erplots.djnavarro.net/reference/er_vpc_theme.md))
to decide which of a builder's two config tables to check for a marker
falling outside the plotted axis limits. A builder that plots
`config$summary` (e.g.
[`er_style_vpc_observed_mean_errorbar()`](https://erplots.djnavarro.net/reference/er_style_vpc_observed.md))
should tag `marker_source = "summary"`; one that plots
`config$percentiles` (e.g.
[`er_style_vpc_observed_quantile_line()`](https://erplots.djnavarro.net/reference/er_style_vpc_observed.md),
[`er_style_vpc_observed_quantile_errorbar()`](https://erplots.djnavarro.net/reference/er_style_vpc_observed.md))
should tag `marker_source = "percentiles"`. An untagged builder has both
tables checked, which is always safe but can produce a spurious warning
about a table the builder never actually draws from.

## Registering a label

`label` is unlike every tag above, in that it isn't purely descriptive:
supplying it registers `style` as a side effect, so that the
corresponding `_add_*()` function can accept the string in place of
`style` itself. It requires `layer` in the same call – the registry is
keyed by `(layer, label)`, not `label` alone, which is what lets two
different layers reuse the same label string with no ambiguity (each
`_add_*()` function only ever looks inside its own layer's partition).
Wired up for every `_add_*()` function in the package – see
[`er_style_labels()`](https://erplots.djnavarro.net/reference/er_style_labels.md)
for the full list of registered `(layer, label)` pairs.

Re-registering the same `(layer, label)` pair with the identical
function is always a silent no-op (this is what makes reloading the
package, which re-tags every built-in builder, safe). Re-registering it
with a *different* function errors by default – e.g. re-running a script
that edits a custom labelled builder's body and re-tags it hits this –
unless `overwrite = TRUE` is passed, which replaces the registration
unconditionally.

## See also

[`er_plot_add_data()`](https://erplots.djnavarro.net/reference/er_plot_add_data.md),
[`er_style()`](https://erplots.djnavarro.net/reference/er_style.md),
[`er_style_vpc()`](https://erplots.djnavarro.net/reference/er_style_vpc.md),
[`er_style_tte()`](https://erplots.djnavarro.net/reference/er_style_tte.md),
[`er_style_labels()`](https://erplots.djnavarro.net/reference/er_style_labels.md)

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
  layer = "plot_data"
)
```
