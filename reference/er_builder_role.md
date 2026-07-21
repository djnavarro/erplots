# Declare a builder's fill/y-axis role

Companion setters to
[`er_builder_layout()`](https://erplots.djnavarro.net/reference/er_builder_layout.md)
for the two other pieces of builder self-declared metadata in the
package: `er_builder_fill_role()` tags a data-layer builder whose `fill`
aesthetic means something other than strata (currently only `"density"`,
used by
[`er_builder_data_hex()`](https://erplots.djnavarro.net/reference/er_builder_data.md)),
and `er_builder_y_role()` tags a group-layer builder whose y-axis means
something other than the group variable itself (currently only
`"count"`, used by
[`er_builder_group_histogram()`](https://erplots.djnavarro.net/reference/er_builder_group.md)).
Both follow the same wrapper-function pattern as
[`er_builder_layout()`](https://erplots.djnavarro.net/reference/er_builder_layout.md)
rather than requiring a custom builder author to call
[`attr()`](https://rdrr.io/r/base/attr.html) directly with a hand-typed
string constant.

## Usage

``` r
er_builder_fill_role(builder, role)

er_builder_y_role(builder, role)
```

## Arguments

- builder:

  A function matching the standard `er_builder_*()` signature (see
  [`er_partial()`](https://erplots.djnavarro.net/reference/er_partial.md))

- role:

  For `er_builder_fill_role()`: currently only `"density"` is read by
  `.polish_labels()`, but any string is accepted. For
  `er_builder_y_role()`: currently only `"count"` is read.

## Value

`builder`, with an `"er_builder_fill_role"`/`"er_builder_y_role"`
attribute attached

## See also

[`er_builder_layout()`](https://erplots.djnavarro.net/reference/er_builder_layout.md),
[`er_partial()`](https://erplots.djnavarro.net/reference/er_partial.md)
