# Builder functions for exposure-response plots

Builder functions for exposure-response plots

## Arguments

- data:

  The original data frame

- config:

  Configuration for the specific plot

- stratify:

  Logical indicating whether to stratify

- exposure:

  Exposure variable

- response:

  Response variable

- strata:

  Stratification variable

- theme:

  Theme components

- ...:

  Additional named arguments forwarded from the corresponding
  `er_plot_add_*()` call's own `...`; see "Passing extra arguments to a
  builder" below.

## Value

A geom, or a list of geoms. More precisely, a list of objects that can
be added to a ggplot2 plot. The expectation is that these objects will
be added to a partially constructed plot which, at a minimum, already
has the base theme applied. For "model", "summary", "quantile", and
"overlay", the pieces will be added to a plot that already has a coord
that sets the axis limits (the base plot; see `.build_overlay_geoms()`).
For the "data" (panel-based, e.g.
[`er_style_data_boxjitter()`](https://erplots.djnavarro.net/reference/er_style_data.md))
and "group" plots, the plot object does not yet have a coord. The
expectation, however, is that the builder will supply an x-axis limit
that is consistent with the base plot. That is, since all layer plots
use the exposure variable for the x-axis, they should use the values
stored in `exposure$limits` tp set the x-axis limits.

## Details

This page documents the shared interface all `er_style_*()` builders
implement. The builders themselves are documented on their own
family-specific pages, one per layer:

- [`er_style_model()`](https://erplots.djnavarro.net/reference/er_style_model.md)
  – the `model` layer
  ([`er_plot_add_model()`](https://erplots.djnavarro.net/reference/er_plot_add_model.md))

- [`er_style_summary()`](https://erplots.djnavarro.net/reference/er_style_summary.md)
  – the `summary` layer
  ([`er_plot_add_summary()`](https://erplots.djnavarro.net/reference/er_plot_add_summary.md))

- [`er_style_quantile()`](https://erplots.djnavarro.net/reference/er_style_quantile.md)
  – the `quantile` layer
  ([`er_plot_add_quantiles()`](https://erplots.djnavarro.net/reference/er_plot_add_quantiles.md))

- [`er_style_data()`](https://erplots.djnavarro.net/reference/er_style_data.md)
  – the `data` layer
  ([`er_plot_add_data()`](https://erplots.djnavarro.net/reference/er_plot_add_data.md))

- [`er_style_group()`](https://erplots.djnavarro.net/reference/er_style_group.md)
  – the `group` layer
  ([`er_plot_add_groups()`](https://erplots.djnavarro.net/reference/er_plot_add_groups.md))

Arguments are standardised to allow users to write their own as needed

## Writing your own builder

Every `er_style_*()` function above shares the signature documented in
`@param`s, and that signature is a public part of the API, not an
implementation detail: any function
`function(data, config, stratify, exposure, response, strata, theme, ...)`
that returns a geom or list of geoms can stand in for a built-in
builder. This is the officially supported way to draw a layer
differently from any of the built-in `style` options – e.g. a 2D density
instead of a scatter for the data overlay, per-panel histograms instead
of jittered points for the panel-based data layer, or a
`geom_crossbar()` instead of a `geom_errorbar()`/`geom_pointrange()` for
the quantile summary.
([`er_style_quantile_pointrange()`](https://erplots.djnavarro.net/reference/er_style_quantile.md)
started life as exactly this kind of custom builder – it was promoted to
a built-in option once it proved to be a natural, low-risk alternative
to
[`er_style_quantile_errorbar()`](https://erplots.djnavarro.net/reference/er_style_quantile.md),
with no new config requirements.)

Each `er_plot_add_*()` function takes a `style` argument that defaults
to one built-in `er_style_*()` function and can be set to any other –
built-in or custom – matching the standard signature: a custom builder
can be plugged in without forking the package or reaching into
`object$layer` internals. For the data layer specifically, `style` also
has to declare which *structural* family it belongs to – a single call
merged into the main panel, or one or more panels stacked below the base
plot – via
[`er_style_tag()`](https://erplots.djnavarro.net/reference/er_style_tag.md),
since
[`er_plot_add_data()`](https://erplots.djnavarro.net/reference/er_plot_add_data.md)
reads that tag off `style` to decide how to assemble the layer; the
other three layers have only one structural call site, so no such
tagging is needed there. See the `@examples` on
[`er_plot_add_model()`](https://erplots.djnavarro.net/reference/er_plot_add_model.md),
[`er_plot_add_quantiles()`](https://erplots.djnavarro.net/reference/er_plot_add_quantiles.md),
and
[`er_plot_add_data()`](https://erplots.djnavarro.net/reference/er_plot_add_data.md)
for worked custom builders (a dashed model curve, a quantile crossbar,
and a data-overlay density, respectively).

A custom builder receives the same pre-computed `config` a built-in
builder would have received for that layer (e.g. `config$predictions`
for `model`, `config$summary` for `quantile`) – it does not need to
recompute anything the corresponding `.layer_*()` function already
derived from `data`/`exposure`/`response`/`strata`; it only needs to
turn that `config` into ggplot2 layers.

A custom builder can optionally self-declare which layer it's meant for
via `er_style_tag(builder, layer = ...)` (one of `"model"`, `"summary"`,
`"quantile"`, `"data"`, `"group"`). Every `er_plot_add_*()` function
checks a builder's `layer` tag, if it has one, against the layer it was
actually passed to, erroring immediately if they disagree – e.g. passing
a builder tagged `layer = "quantile"` to
[`er_plot_add_data()`](https://erplots.djnavarro.net/reference/er_plot_add_data.md)
errors rather than calling the builder with a `config` shape it wasn't
written for. This tag is entirely optional (unlike `layout`, which is
mandatory for a data-layer builder specifically) – an untagged custom
builder is simply never checked, so existing custom builders keep
working unchanged. All built-in builders carry this tag.

All of the builders above feed a **singleton** layer: `model`,
`summary`, `quantile`, `data`, and `overlay` each occupy a single named
slot (`object$layer$model`, `object$layer$data`, etc.), so calling the
corresponding `er_plot_add_*()` function again overwrites the slot
rather than combining builders. `group`
([`er_style_group_boxplot()`](https://erplots.djnavarro.net/reference/er_style_group.md)/
[`er_style_group_violin()`](https://erplots.djnavarro.net/reference/er_style_group.md))
is the one **additive** exception – each call to
[`er_plot_add_groups()`](https://erplots.djnavarro.net/reference/er_plot_add_groups.md)
adds another named entry rather than replacing the previous one. See
[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md)'s
"Layers are either singleton or additive" section for the full
discussion, including the one flagged future exception (an additive
`model` layer, for overlaying two fitted curves).

The `data` slot's default,
[`er_style_data_overlay()`](https://erplots.djnavarro.net/reference/er_style_data.md),
needs no `color_role` tag: its color aesthetic (when stratified) is
always strata, since the response is already shown via y-position, so it
shares the base plot's own strata legend directly. `config$color_role`
(set by `.layer_data()`, consulted by `.polish_labels()`/
`.polish_legends()` in `R/er-plot-compose.R`) matters for the
"panel"-layout family instead, where it's `"strata"` for a binary
response (as used by the built-in
[`er_style_data_boxjitter()`](https://erplots.djnavarro.net/reference/er_style_data.md),
whose color aesthetic still means strata) or `"response"` for a
continuous/count response, where the color channel is already spoken for
by the response value itself – there's no built-in "panel"-layout
builder for that case (the older `build_data_color()` was removed once
[`er_style_data_overlay()`](https://erplots.djnavarro.net/reference/er_style_data.md)
covered its typical use case more simply), but a custom builder tagged
`er_style_tag(builder, layout = "panel")` can still opt into it; see
[`er_plot_add_data()`](https://erplots.djnavarro.net/reference/er_plot_add_data.md)
for the user-facing version of this rule.

## Passing extra arguments to a builder

Every `er_plot_add_*()` function
([`er_plot_add_model()`](https://erplots.djnavarro.net/reference/er_plot_add_model.md),
[`er_plot_add_summary()`](https://erplots.djnavarro.net/reference/er_plot_add_summary.md),
[`er_plot_add_quantiles()`](https://erplots.djnavarro.net/reference/er_plot_add_quantiles.md),
[`er_plot_add_data()`](https://erplots.djnavarro.net/reference/er_plot_add_data.md),
[`er_plot_add_groups()`](https://erplots.djnavarro.net/reference/er_plot_add_groups.md))
takes its own `...`, which is forwarded unchanged to `style` when it's
actually called at build time. Extra arguments must be named, since
they're appended positionally after the seven standard arguments; an
unnamed one errors immediately rather than silently binding to the wrong
parameter. This is how a builder that needs a piece of information
beyond what `config` already carries – something genuinely per-call
rather than a fixed part of the layer's configuration – can accept it
without a bespoke argument on every `er_plot_add_*()` function. The
motivating built-in example is
[`er_style_model_spaghetti()`](https://erplots.djnavarro.net/reference/er_style_model.md),
which calls
[`er_simulate()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
and, for models (like erglm's) that auto-select and report a seed when
none is supplied, would otherwise always trigger that message:

    erglm_data |>
      er_plot(aucss, ae1) |>
      er_plot_add_model(mod, style = er_style_model_spaghetti, seed = 9626) |>
      plot()

A builder that doesn't need any extra arguments simply declares `...`
and ignores it – every built-in builder does exactly this except
[`er_style_model_spaghetti()`](https://erplots.djnavarro.net/reference/er_style_model.md).
A custom builder can read whichever named arguments it recognizes out of
its own `...` (e.g. via `rlang::list2(...)`) and ignore the rest;
unrecognized extra arguments are never an error at the builder itself,
only at the `er_plot_add_*()` call site if they weren't named.

## See also

[`er_style_model()`](https://erplots.djnavarro.net/reference/er_style_model.md),
[`er_style_summary()`](https://erplots.djnavarro.net/reference/er_style_summary.md),
[`er_style_quantile()`](https://erplots.djnavarro.net/reference/er_style_quantile.md),
[`er_style_data()`](https://erplots.djnavarro.net/reference/er_style_data.md),
[`er_style_group()`](https://erplots.djnavarro.net/reference/er_style_group.md),
[`er_style_tag()`](https://erplots.djnavarro.net/reference/er_style_tag.md)
