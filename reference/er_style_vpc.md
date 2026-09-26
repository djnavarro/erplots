# Builder functions for VPC plots

Documents the shared
`function(data, config, exposure, response, theme, ...)` signature every
`er_style_vpc_*()` builder implements, including how to write a custom
one. The VPC analogue of
[`er_style()`](https://erplots.djnavarro.net/reference/er_style.md)'s
shared interface for the
[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md)
grammar.

## Value

A geom, or a list of geoms. More precisely, a list of objects that can
be added to a ggplot2 plot, on top of a partially constructed plot that
already has the base theme and a coord applied.

## Details

This page documents the shared interface all `er_style_vpc_*()` builders
implement. The builders themselves are documented on their own
family-specific pages, one per side of the observed/simulated
comparison:

- [`er_style_vpc_observed()`](https://erplots.djnavarro.net/reference/er_style_vpc_observed.md)
  – the `observed` layer
  ([`er_vpc_add_observed()`](https://erplots.djnavarro.net/reference/er_vpc_add_observed.md))

- [`er_style_vpc_simulated()`](https://erplots.djnavarro.net/reference/er_style_vpc_simulated.md)
  – the `simulated` layer
  ([`er_vpc_add_simulated()`](https://erplots.djnavarro.net/reference/er_vpc_add_simulated.md))

## Arguments

Every `er_style_vpc_*()` builder receives:

- `data` – The original data frame passed to
  [`er_vpc()`](https://erplots.djnavarro.net/reference/er_vpc.md).

- `config` – Configuration for the specific layer (`observed` or
  `simulated`); see
  [`er_style_vpc_observed()`](https://erplots.djnavarro.net/reference/er_style_vpc_observed.md)/[`er_style_vpc_simulated()`](https://erplots.djnavarro.net/reference/er_style_vpc_simulated.md)
  for what each populates.

- `exposure` – The plot's `exposure` variable (`object$exposure`) – not
  necessarily the variable plotted on the x-axis; see "Exposure is not
  always the x-axis variable" below.

- `response` – The plot's `response` variable (`object$response`).

- `theme` – Theme components (`object$theme`).

- `...` – Additional named arguments forwarded from the corresponding
  `er_vpc_add_*()` call's own `...`; see "Passing extra arguments to a
  builder" below.

Unlike
[`er_style()`](https://erplots.djnavarro.net/reference/er_style.md)'s
signature, there is no `stratify`/`strata` pair:
[`er_vpc()`](https://erplots.djnavarro.net/reference/er_vpc.md)'s own
`stratify_by` is facet-only (no colour/fill precedence rule to thread
through a builder), so every builder-facing config table already carries
the faceting column it needs, and no builder ever has to branch on
stratification itself.

## Exposure is not always the x-axis variable

`plot_by` (`object$group`), not `exposure`, drives a VPC's x-axis; the
two only coincide when the caller didn't override `plot_by`. A builder
that needs the x-axis variable's own label or numeric range should read
`object$group$label`/`config$group_limits` instead of `exposure$label`/
`exposure$limits` – see
[`er_vpc()`](https://erplots.djnavarro.net/reference/er_vpc.md)'s
`plot_by` argument.

## Writing your own builder

Every `er_style_vpc_*()` function above shares the signature documented
in the "Arguments" section above, and that signature is a public part of
the API: any function
`function(data, config, exposure, response, theme, ...)` that returns a
geom or list of geoms can stand in for a built-in builder, passed as
`style` to
[`er_vpc_add_observed()`](https://erplots.djnavarro.net/reference/er_vpc_add_observed.md)/
[`er_vpc_add_simulated()`](https://erplots.djnavarro.net/reference/er_vpc_add_simulated.md).

A custom builder can self-declare metadata via
[`er_style_tag()`](https://erplots.djnavarro.net/reference/er_style_tag.md):
`vpc_layout` (`"categorical"`/`"continuous"`, checked for agreement
between the observed and simulated builders paired on one `er_vpc`
object – distinct from the data layer's own `layout` tag, which uses an
unrelated `"overlay"`/`"panel"` pair), `layer` (`"observed"`/
`"simulated"`, checked against the layer the builder was actually passed
to), `response_types`/`plot_by_types` (checked against
`object$response$type`/`object$group$type`), and `marker_source` (which
of `config$summary`/`config$percentiles` the builder actually draws
from, used by
[`er_vpc_theme()`](https://erplots.djnavarro.net/reference/er_vpc_theme.md)'s
`xlim`/`ylim` cropping). All five are optional and independent – see
[`er_style_tag()`](https://erplots.djnavarro.net/reference/er_style_tag.md)
for the full explanation of each, including which built-in builders use
them and why.

Both `observed` and `simulated` are **singleton** layers: calling
[`er_vpc_add_observed()`](https://erplots.djnavarro.net/reference/er_vpc_add_observed.md)/[`er_vpc_add_simulated()`](https://erplots.djnavarro.net/reference/er_vpc_add_simulated.md)
again replaces the previous builder rather than adding another one.

## Passing extra arguments to a builder

[`er_vpc_add_observed()`](https://erplots.djnavarro.net/reference/er_vpc_add_observed.md)/[`er_vpc_add_simulated()`](https://erplots.djnavarro.net/reference/er_vpc_add_simulated.md)
each take their own `...`, forwarded unchanged to `style` when it's
actually called at build time. Extra arguments must be named, since
they're appended positionally after the five standard arguments; an
unnamed one errors immediately rather than silently binding to the wrong
parameter. A builder that doesn't need any extra arguments simply
declares `...` and ignores it – every built-in VPC builder does exactly
this.

## See also

[`er_style()`](https://erplots.djnavarro.net/reference/er_style.md),
[`er_style_vpc_observed()`](https://erplots.djnavarro.net/reference/er_style_vpc_observed.md),
[`er_style_vpc_simulated()`](https://erplots.djnavarro.net/reference/er_style_vpc_simulated.md),
[`er_style_tag()`](https://erplots.djnavarro.net/reference/er_style_tag.md)
