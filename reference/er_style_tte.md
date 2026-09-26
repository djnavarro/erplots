# Builder functions for time-to-event plots

Documents the shared
`function(data, config, stratify, time, strata, theme, ...)` signature
every `er_style_tte_*()` builder implements, including how to write a
custom one. The TTE analogue of
[`er_style()`](https://erplots.djnavarro.net/reference/er_style.md)'s
shared interface for the
[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md)
grammar, adapted for a time x-axis/ survival-probability y-axis instead
of exposure/response.

## Value

A geom, or a list of geoms. More precisely, a list of objects that can
be added to a ggplot2 plot, on top of a partially constructed panel that
already has the base theme and a coord applied (time on the x-axis,
survival probability on the y-axis for every layer except `risktable`,
whose panel has no such coord).

## Details

This page documents the shared interface all `er_style_tte_*()` builders
implement. The builders themselves are documented on their own
family-specific pages, one per layer:

- [`er_style_tte_curve()`](https://erplots.djnavarro.net/reference/er_style_tte_curve.md)
  – the `curve` layer
  ([`er_tte_add_curve()`](https://erplots.djnavarro.net/reference/er_tte_add_curve.md))

- [`er_style_tte_censor()`](https://erplots.djnavarro.net/reference/er_style_tte_censor.md)
  – the `censor` layer
  ([`er_tte_add_censor()`](https://erplots.djnavarro.net/reference/er_tte_add_censor.md))

- [`er_style_tte_risktable()`](https://erplots.djnavarro.net/reference/er_style_tte_risktable.md)
  – the `risktable` layer
  ([`er_tte_add_risktable()`](https://erplots.djnavarro.net/reference/er_tte_add_risktable.md))

- [`er_style_tte_summary()`](https://erplots.djnavarro.net/reference/er_style_tte_summary.md)
  – the `summary` layer
  ([`er_tte_add_summary()`](https://erplots.djnavarro.net/reference/er_tte_add_summary.md))

- [`er_style_tte_model()`](https://erplots.djnavarro.net/reference/er_style_tte_model.md)
  – the `model` layer
  ([`er_tte_add_model()`](https://erplots.djnavarro.net/reference/er_tte_add_model.md))

[`er_style_tte_risktable_text()`](https://erplots.djnavarro.net/reference/er_style_tte_risktable.md)
is the one family whose geoms are drawn into a separate patchwork panel
stacked below the curve, rather than onto the curve panel directly – its
builder still receives the same standard signature, but the returned
geoms are composed differently at build time.

## Arguments

Every `er_style_tte_*()` builder receives:

- `data` – The original data frame (`object$data`).

- `config` – Configuration for the specific layer; see each
  family-specific page below for what it populates.

- `stratify` – Logical: whether the fit is stratified
  (`!is.null(object$strata)`).

- `time` – `object$time` (`name`/`label`/`limits`).

- `strata` – `object$strata` (`var`/`label`), or `NULL` when
  unstratified.

- `theme` – Theme components (`object$theme`).

- `...` – Additional named arguments forwarded from the corresponding
  `er_tte_add_*()` call's own `...`; see "Passing extra arguments to a
  builder" below.

## Writing your own builder

Every `er_style_tte_*()` function above shares the signature documented
in the "Arguments" section above, and that signature is a public part of
the API: any function
`function(data, config, stratify, time, strata, theme, ...)` that
returns a geom or list of geoms can stand in for a built-in builder,
passed as `style` to the matching `er_tte_add_*()` function.

A custom builder can self-declare which layer it's meant for via
`er_style_tag(builder, layer = ...)`, one of `"curve"`, `"censor"`,
`"risktable"`, `"tte_summary"`, or `"tte_model"`. Every `er_tte_add_*()`
function checks a builder's `layer` tag, if it has one, against the
layer it was actually passed to, erroring immediately if they disagree.
`"tte_summary"`/`"tte_model"` are deliberately distinct from
[`er_plot_add_summary()`](https://erplots.djnavarro.net/reference/er_plot_add_summary.md)/[`er_plot_add_model()`](https://erplots.djnavarro.net/reference/er_plot_add_model.md)'s
own `"summary"`/`"model"` tags – the two grammars' summary/model
builders share no signature or `config` contents, so a builder written
for [`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md)
would otherwise silently pass the tag check if passed to
[`er_tte_add_summary()`](https://erplots.djnavarro.net/reference/er_tte_add_summary.md)/
[`er_tte_add_model()`](https://erplots.djnavarro.net/reference/er_tte_add_model.md)
instead. This tag is entirely optional; an untagged custom builder is
simply never checked. See
[`er_style_tag()`](https://erplots.djnavarro.net/reference/er_style_tag.md)
for the full set of attributes a builder can carry.

All five layers are **singleton**: calling the corresponding
`er_tte_add_*()` function again replaces that layer's builder rather
than adding another one. Unlike
[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md)'s
`group` layer, no TTE layer is additive.

## Passing extra arguments to a builder

Every `er_tte_add_*()` function
([`er_tte_add_curve()`](https://erplots.djnavarro.net/reference/er_tte_add_curve.md),
[`er_tte_add_censor()`](https://erplots.djnavarro.net/reference/er_tte_add_censor.md),
[`er_tte_add_risktable()`](https://erplots.djnavarro.net/reference/er_tte_add_risktable.md),
[`er_tte_add_summary()`](https://erplots.djnavarro.net/reference/er_tte_add_summary.md),
[`er_tte_add_model()`](https://erplots.djnavarro.net/reference/er_tte_add_model.md))
takes its own `...`, forwarded unchanged to `style` when it's actually
called at build time. Extra arguments must be named, since they're
appended positionally after the six standard arguments; an unnamed one
errors immediately rather than silently binding to the wrong parameter.
A builder that doesn't need any extra arguments simply declares `...`
and ignores it – every built-in TTE builder does exactly this.

## See also

[`er_style()`](https://erplots.djnavarro.net/reference/er_style.md),
[`er_style_tte_curve()`](https://erplots.djnavarro.net/reference/er_style_tte_curve.md),
[`er_style_tte_censor()`](https://erplots.djnavarro.net/reference/er_style_tte_censor.md),
[`er_style_tte_risktable()`](https://erplots.djnavarro.net/reference/er_style_tte_risktable.md),
[`er_style_tte_summary()`](https://erplots.djnavarro.net/reference/er_style_tte_summary.md),
[`er_style_tte_model()`](https://erplots.djnavarro.net/reference/er_style_tte_model.md),
[`er_style_tag()`](https://erplots.djnavarro.net/reference/er_style_tag.md)
