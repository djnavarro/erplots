# Tag a builder with structural/aesthetic metadata

Attaches the self-declared metadata a custom `er_builder_*()`-style
function can carry, in a single call: which *structural* family a
data-layer builder belongs to (`layout`), what a builder's `fill`
aesthetic means when it isn't strata (`fill_role`), what a group-layer
builder's y-axis means when it isn't the group variable itself
(`y_role`), and which layer a builder is meant to be plugged into
(`layer`). All four arguments are optional and independent – pass only
the ones a given builder needs, in one call, rather than chaining
separate setters. See
[`er_partial()`](https://erplots.djnavarro.net/reference/er_partial.md)'s
"Writing your own builder" section for the full contract.

## Usage

``` r
er_builder_tag(
  builder,
  layout = NULL,
  fill_role = NULL,
  y_role = NULL,
  layer = NULL
)
```

## Arguments

- builder:

  A function matching the standard `er_builder_*()` signature (see
  [`er_partial()`](https://erplots.djnavarro.net/reference/er_partial.md))

- layout:

  One of `"overlay"` or `"panel"`, or `NULL` (the default) to leave this
  tag unset – see
  [`er_plot_add_data()`](https://erplots.djnavarro.net/reference/er_plot_add_data.md)
  for what each structural family means

- fill_role:

  A string naming what the builder's `fill` aesthetic represents
  (currently only `"density"` is read by `.polish_labels()`, but any
  string is accepted), or `NULL` (the default) to leave this tag unset

- y_role:

  A string naming what the builder's y-axis represents (currently only
  `"count"` is read by `.polish_labels()`), or `NULL` (the default) to
  leave this tag unset

- layer:

  One of `"model"`, `"summary"`, `"quantile"`, `"data"`, or `"group"`,
  naming which `er_plot_add_*()` layer (or, for `"summary"`, which
  argument of
  [`er_plot_add_model()`](https://erplots.djnavarro.net/reference/er_plot_add_model.md))
  the builder is meant to be used with, or `NULL` (the default) to leave
  this tag unset – see "Details"

## Value

`builder`, with whichever of the `"er_builder_layout"`/
`"er_builder_fill_role"`/`"er_builder_y_role"`/`"er_builder_layer"`
attributes were requested attached

## Details

`layout` is the one required tag for a data-layer builder:
[`er_plot_add_data()`](https://erplots.djnavarro.net/reference/er_plot_add_data.md)
reads it off `builder` to decide whether to route through
`.part_overlay()` (`"overlay"`: a single call merged into the main
panel, at the observations' true `(exposure, response)` coordinates) or
`.part_data()` (`"panel"`: one-or-more panels stacked below the base
plot), *before* it can call the builder – so the choice can't be
inferred from the builder's return value. Both built-in data builders
([`er_builder_data_overlay()`](https://erplots.djnavarro.net/reference/er_builder_data.md),
[`er_builder_data_boxjitter()`](https://erplots.djnavarro.net/reference/er_builder_data.md))
already carry this tag.

`fill_role` and `y_role` are both optional, read by `.polish_labels()`
to title a legend/axis correctly: `fill_role = "density"` (used by
[`er_builder_data_hex()`](https://erplots.djnavarro.net/reference/er_builder_data.md))
says a builder's `fill` aesthetic encodes bin density rather than
strata; `y_role = "count"` (used by
[`er_builder_group_histogram()`](https://erplots.djnavarro.net/reference/er_builder_group.md))
says a group-layer builder's y-axis means counts rather than the group
variable itself. A builder that omits either tag keeps the default
behaviour (`fill` means strata; the y-axis is titled with the group
variable's label), which is correct for most builders.

`layer` is also optional, but unlike `fill_role`/`y_role` it isn't read
for labelling – it's read by every `er_plot_add_*()` function
([`er_plot_add_model()`](https://erplots.djnavarro.net/reference/er_plot_add_model.md)
checks both `builder` against `"model"` and `summary_builder` against
`"summary"`;
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
never checked – `layer` is opt-in, not a requirement like `layout` is
for a data-layer builder.

## See also

[`er_plot_add_data()`](https://erplots.djnavarro.net/reference/er_plot_add_data.md),
[`er_partial()`](https://erplots.djnavarro.net/reference/er_partial.md)

## Examples

``` r
build_data_density <- er_builder_tag(
  function(data, config, stratify, exposure, response, strata, style) {
    ggplot2::geom_density_2d(
      data = data,
      mapping = ggplot2::aes(x = .data[[exposure$name]], y = .data[[response$name]])
    )
  },
  layout = "overlay",
  layer = "data"
)
```
