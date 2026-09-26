# List builders registered for string-based `style` dispatch

A builder tagged via `er_style_tag(fn, layer = ..., label = ...)` can be
selected with a short string (e.g. `style = "logrank"`) instead of the
function itself, wherever the corresponding `_add_*()` function supports
it. `er_style_labels()` lists what's currently registered, optionally
filtered to a single `layer`.

## Usage

``` r
er_style_labels(layer = NULL)
```

## Arguments

- layer:

  A single layer name (e.g. `"tte_summary"`), or `NULL` (the default) to
  list every registered label across all layers.

## Value

A tibble with one row per registered `(layer, label)` pair and columns
`layer`, `label`, and `style` (the builder function itself).

## Examples

``` r
er_style_labels("tte_summary")
#> # A tibble: 4 × 3
#>   layer       label        style       
#>   <chr>       <chr>        <named list>
#> 1 tte_summary coefficients <fn>        
#> 2 tte_summary gof          <fn>        
#> 3 tte_summary logrank      <fn>        
#> 4 tte_summary n            <fn>        
```
