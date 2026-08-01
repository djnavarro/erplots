# Cut a continuous variable into quantiles

`cut_quantile()` bins a numeric vector into `n` quantile groups.
`cut_exposure_quantile()` does the same for an exposure variable,
additionally keeping placebo (`0`) observations in their own bin.

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
`"breaks"` attribute holding the `n + 1` quantile cutpoints used to form
the bins.

## Details

Both functions error if `x` has fewer than 2 distinct non-missing
values, since quantile bins aren't well-defined in that case. If `x`
doesn't have enough resolution to distinguish all `n` requested bins
(e.g. many repeated values clustered at one end), both functions warn
and fall back to using as many bins as the data supports, rather than
erroring or silently showing fewer bins with no explanation.
`cut_exposure_quantile()`'s `"breaks"` attribute is read back out by
quantile-layer builders that draw bin-boundary separators (e.g.
[`er_style_quantile_errorbar_vlines()`](https://erplots.djnavarro.net/reference/er_style_quantile.md))
via `attr(exposure_bins, "breaks")`.

## Examples

``` r
x <- rnorm(100)
cut_quantile(x)
#>   [1] Q4 Q3 Q4 Q3 Q2 Q2 Q3 Q2 Q2 Q3 Q1 Q3 Q2 Q1 Q1 Q3 Q1 Q2 Q4 Q2 Q2 Q1 Q4 Q3 Q4
#>  [26] Q4 Q1 Q3 Q1 Q4 Q3 Q3 Q1 Q2 Q4 Q3 Q2 Q2 Q3 Q3 Q1 Q4 Q2 Q3 Q1 Q1 Q1 Q3 Q2 Q3
#>  [51] Q2 Q1 Q4 Q4 Q3 Q4 Q2 Q1 Q2 Q4 Q1 Q1 Q1 Q4 Q3 Q4 Q2 Q4 Q4 Q4 Q4 Q2 Q1 Q2 Q4
#>  [76] Q3 Q3 Q4 Q4 Q3 Q2 Q4 Q2 Q2 Q1 Q2 Q1 Q1 Q1 Q4 Q1 Q2 Q3 Q1 Q3 Q2 Q3 Q3 Q1 Q4
#> Levels: Q1 Q2 Q3 Q4
cut_exposure_quantile(abs(x))
#>   [1] Q4 Q2 Q4 Q2 Q1 Q1 Q2 Q1 Q2 Q1 Q3 Q3 Q1 Q4 Q3 Q2 Q3 Q1 Q3 Q1 Q1 Q3 Q4 Q2 Q3
#>  [26] Q4 Q3 Q2 Q4 Q4 Q2 Q1 Q3 Q2 Q3 Q2 Q1 Q1 Q2 Q3 Q4 Q3 Q1 Q1 Q4 Q2 Q3 Q1 Q1 Q2
#>  [51] Q1 Q3 Q4 Q3 Q2 Q3 Q2 Q4 Q1 Q4 Q3 Q3 Q4 Q4 Q2 Q4 Q1 Q4 Q3 Q3 Q3 Q2 Q3 Q2 Q4
#>  [76] Q1 Q1 Q3 Q4 Q2 Q2 Q4 Q1 Q1 Q4 Q1 Q3 Q2 Q4 Q4 Q4 Q1 Q2 Q4 Q2 Q1 Q2 Q2 Q4 Q3
#> attr(,"breaks")
#>         0%        25%        50%        75%       100% 
#> 0.02229473 0.39187595 0.79633523 1.14824248 2.64893203 
#> Levels: Placebo Q1 Q2 Q3 Q4
```
