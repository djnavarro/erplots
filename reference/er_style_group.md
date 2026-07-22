# Group panel builders for exposure-response plots

Group panel builders for exposure-response plots

## Usage

``` r
er_style_group_boxplot(
  data,
  config,
  stratify,
  exposure,
  response,
  strata,
  theme
)

er_style_group_histogram(
  data,
  config,
  stratify,
  exposure,
  response,
  strata,
  theme
)

er_style_group_violin(
  data,
  config,
  stratify,
  exposure,
  response,
  strata,
  theme
)
```

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

## Value

A geom, or a list of geoms; see
[`er_style()`](https://erplots.djnavarro.net/reference/er_style.md).

## Details

Builders for the `group` layer
([`er_plot_add_groups()`](https://erplots.djnavarro.net/reference/er_plot_add_groups.md)),
which draws the exposure distribution for a grouping variable (e.g.
treatment arm) below the main panel: `er_style_group_boxplot()` (the
default), `er_style_group_violin()`, and `er_style_group_histogram()`.
The first two put the group levels on the y-axis;
`er_style_group_histogram()` instead puts them on facet strips and frees
the y-axis for counts (see `Details` in the package's
`AGENTS.md`/`PLAN.md` for the rationale). All three are tagged
`er_style_tag(fn, layer = "group")`, so
[`er_plot_add_groups()`](https://erplots.djnavarro.net/reference/er_plot_add_groups.md)
errors informatively if handed a builder tagged for a different layer.

See [`er_style()`](https://erplots.djnavarro.net/reference/er_style.md)
for the shared builder interface these functions implement, including
how to write a custom builder of your own.

## See also

[`er_style()`](https://erplots.djnavarro.net/reference/er_style.md)
