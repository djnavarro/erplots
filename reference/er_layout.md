# Declare a data-layer builder's structural layout

Tags a `build_data_*()`-style function with the *structural* family it
belongs to – `"overlay"` (a single call merged into the main panel) or
`"panel"` (one-or-more panels stacked below the base plot) – so
[`er_plot_show_data()`](https://erplots.djnavarro.net/reference/er_plot_show_data.md)
can route to the right internal assembly path (`.part_overlay()` vs.
`.part_data()`) just by inspecting the `builder` it was given, with no
separate `style`/`layout` argument needed. See
[`er_partial()`](https://erplots.djnavarro.net/reference/er_partial.md)'s
"Writing your own builder" section for the full contract; both built-in
data builders
([`build_data_overlay()`](https://erplots.djnavarro.net/reference/build_data.md),
[`build_data_boxjitter()`](https://erplots.djnavarro.net/reference/build_data.md))
already carry this tag.

## Usage

``` r
er_layout(builder, layout = c("overlay", "panel"))
```

## Arguments

- builder:

  A function matching the standard `build_*()` signature (see
  [`er_partial()`](https://erplots.djnavarro.net/reference/er_partial.md))

- layout:

  One of `"overlay"` or `"panel"` – see
  [`er_plot_show_data()`](https://erplots.djnavarro.net/reference/er_plot_show_data.md)
  for what each structural family means

## Value

`builder`, with an `"er_layout"` attribute attached

## See also

[`er_plot_show_data()`](https://erplots.djnavarro.net/reference/er_plot_show_data.md),
[`er_partial()`](https://erplots.djnavarro.net/reference/er_partial.md)

## Examples

``` r
build_data_density <- er_layout(
  function(data, config, stratify, exposure, response, strata, style) {
    ggplot2::geom_density_2d(
      data = data,
      mapping = ggplot2::aes(x = .data[[exposure$name]], y = .data[[response$name]])
    )
  },
  layout = "overlay"
)
```
