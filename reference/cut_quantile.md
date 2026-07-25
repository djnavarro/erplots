# Cut a continuous variable into quantiles

Cut a continuous variable into quantiles

## Usage

``` r
cut_exposure_quantile(x, n = 4, is_placebo = NULL)

cut_quantile(x, n = 4)
```

## Arguments

- x:

  Numeric vector

- n:

  Number of bins

- is_placebo:

  Logical vector indicating placebo samples

## Value

A factor. `cut_exposure_quantile()`'s result additionally carries a
`"breaks"` attribute – the `n + 1` quantile cutpoints (excluding
placebo) used to form the bins, as computed by
[`stats::quantile()`](https://rdrr.io/r/stats/quantile.html) – which
quantile-layer builders that draw bin-boundary separators (e.g.
[`er_style_quantile_errorbar_vlines()`](https://erplots.djnavarro.net/reference/er_style_quantile.md))
read back out via `attr(exposure_bins, "breaks")`. Both
`cut_exposure_quantile()` (excluding placebo and `NA` values) and
`cut_quantile()` (excluding `NA` values) error if `x` has fewer than 2
distinct values – e.g. a constant, all-`NA`, or single-observation
column – since quantile bins aren't well-defined in that case; without
this check, [`stats::quantile()`](https://rdrr.io/r/stats/quantile.html)
would silently produce non-unique/degenerate breaks and the error would
instead surface much later, opaquely, from inside
[`cut()`](https://rdrr.io/r/base/cut.html). If `x` has at least 2
distinct values but not enough resolution to distinguish all `n`
requested bins (e.g. many repeated values clustered at one end), both
functions warn and silently fall back to using as many bins as the data
actually supports, rather than crashing (duplicate
[`quantile()`](https://rdrr.io/r/stats/quantile.html) breaks otherwise
fail inside [`cut()`](https://rdrr.io/r/base/cut.html)) or showing fewer
bins than requested with no explanation.

## Examples

``` r
x <- rnorm(100)
cut_quantile(x)
#>   [1] Q3 Q3 Q1 Q4 Q4 Q2 Q1 Q2 Q1 Q1 Q4 Q3 Q3 Q4 Q2 Q2 Q1 Q2 Q2 Q4 Q2 Q1 Q2 Q2 Q3
#>  [26] Q4 Q2 Q3 Q3 Q1 Q4 Q2 Q2 Q2 Q2 Q3 Q1 Q4 Q2 Q3 Q4 Q1 Q4 Q2 Q1 Q1 Q4 Q3 Q3 Q1
#>  [51] Q1 Q3 Q4 Q3 Q4 Q3 Q3 Q2 Q3 Q2 Q4 Q4 Q4 Q3 Q1 Q4 Q1 Q2 Q3 Q2 Q3 Q4 Q4 Q2 Q3
#>  [76] Q4 Q2 Q4 Q4 Q2 Q2 Q1 Q1 Q1 Q1 Q1 Q1 Q1 Q3 Q4 Q2 Q1 Q3 Q1 Q3 Q4 Q3 Q1 Q3 Q4
#> Levels: Q1 Q2 Q3 Q4
cut_exposure_quantile(abs(x))
#>   [1] Q2 Q2 Q4 Q3 Q4 Q1 Q3 Q1 Q3 Q4 Q3 Q1 Q1 Q4 Q1 Q1 Q4 Q2 Q2 Q3 Q1 Q3 Q1 Q2 Q2
#>  [26] Q4 Q1 Q3 Q1 Q4 Q3 Q1 Q1 Q1 Q1 Q2 Q4 Q4 Q2 Q1 Q3 Q3 Q4 Q1 Q4 Q3 Q3 Q1 Q2 Q4
#>  [51] Q4 Q2 Q4 Q1 Q4 Q2 Q3 Q1 Q1 Q1 Q4 Q4 Q3 Q2 Q2 Q4 Q4 Q1 Q2 Q2 Q2 Q3 Q3 Q1 Q2
#>  [76] Q4 Q2 Q3 Q4 Q2 Q2 Q3 Q3 Q3 Q4 Q3 Q3 Q2 Q1 Q3 Q1 Q4 Q2 Q2 Q3 Q4 Q2 Q4 Q2 Q3
#> attr(,"breaks")
#>         0%        25%        50%        75%       100% 
#> 0.01595031 0.24852544 0.55738316 1.08339313 2.75541758 
#> Levels: Placebo Q1 Q2 Q3 Q4
```
