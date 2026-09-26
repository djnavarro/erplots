# Cut a continuous variable into quantiles

`cut_quantile()` bins a numeric vector into `n` quantile groups.
`cut_exposure_quantile()` does the same for an exposure variable,
additionally keeping placebo (`0`) observations in their own bin.

## Usage

``` r
cut_exposure_quantile(
  x,
  n = 4,
  is_placebo = NULL,
  ties = c("upward", "downward", "split-even"),
  seed = NULL,
  quantile_type = 7,
  labeller = NULL
)

cut_quantile(
  x,
  n = 4,
  ties = c("upward", "downward", "split-even"),
  seed = NULL,
  quantile_type = 7,
  labeller = NULL
)
```

## Arguments

- x:

  Numeric vector

- n:

  Number of bins

- is_placebo:

  Logical vector indicating placebo samples

- ties:

  Rule for assigning a value that sits exactly on an interior break
  point, where the bin membership would otherwise be ambiguous.
  `"upward"` (the default, matching prior behaviour) is equivalent to
  [`cut()`](https://rdrr.io/r/base/cut.html) with `right = TRUE`;
  `"downward"` is equivalent to `right = FALSE`; `"split-even"` randomly
  divides each tied group between its two candidate bins so that final
  bin sizes are as equal as possible, rather than sending every tied
  value the same direction.

- seed:

  Optional single number used to seed the random tie-break used by
  `ties = "split-even"` (ignored for `"upward"`/`"downward"`, which
  involve no randomness). `NULL` (the default) draws from the ambient
  RNG stream and so is not reproducible across calls; pass a seed for
  reproducible bin assignment.

- quantile_type:

  Integer between 1 and 9, passed straight through as
  [`stats::quantile()`](https://rdrr.io/r/stats/quantile.html)'s own
  `type` argument to compute the quantile break points. Defaults to `7`,
  matching
  [`stats::quantile()`](https://rdrr.io/r/stats/quantile.html)'s own
  default.

- labeller:

  Controls the labels used for the `n` quantile bins
  (`cut_exposure_quantile()`'s separate `"Placebo"` level is always used
  as-is, regardless of `labeller`). `NULL` (the default) labels bins
  `"Q1"`, `"Q2"`, etc. A function is called as `labeller(n, breaks)`
  (the actual bin count and the `n + 1` quantile cutpoints, after any
  resolution-driven fallback – see `@details` below) and must return a
  character vector of length `n`; this is the hook for, e.g.,
  range-style labels built from `breaks`. A character vector is used
  directly as the `n` labels.

## Value

A factor with `"ties"` and `"quantile_type"` attributes recording those
two arguments. `cut_exposure_quantile()`'s result additionally carries a
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
via `attr(exposure_bins, "breaks")`. Because that fallback can lower `n`
below what was originally requested, a character-vector `labeller` is
length-checked against the *actual* bin count, not the requested one,
and errors informatively on a mismatch.

## Examples

``` r
x <- rnorm(100)
cut_quantile(x)
#>   [1] Q4 Q3 Q4 Q3 Q2 Q2 Q3 Q2 Q2 Q3 Q1 Q3 Q2 Q1 Q1 Q3 Q1 Q2 Q4 Q2 Q2 Q1 Q4 Q3 Q4
#>  [26] Q4 Q1 Q3 Q1 Q4 Q3 Q3 Q1 Q2 Q4 Q3 Q2 Q2 Q3 Q3 Q1 Q4 Q2 Q3 Q1 Q1 Q1 Q3 Q2 Q3
#>  [51] Q2 Q1 Q4 Q4 Q3 Q4 Q2 Q1 Q2 Q4 Q1 Q1 Q1 Q4 Q3 Q4 Q2 Q4 Q4 Q4 Q4 Q2 Q1 Q2 Q4
#>  [76] Q3 Q3 Q4 Q4 Q3 Q2 Q4 Q2 Q2 Q1 Q2 Q1 Q1 Q1 Q4 Q1 Q2 Q3 Q1 Q3 Q2 Q3 Q3 Q1 Q4
#> attr(,"ties")
#> [1] upward
#> attr(,"quantile_type")
#> [1] 7
#> Levels: Q1 Q2 Q3 Q4
cut_exposure_quantile(abs(x))
#>   [1] Q4 Q2 Q4 Q2 Q1 Q1 Q2 Q1 Q2 Q1 Q3 Q3 Q1 Q4 Q3 Q2 Q3 Q1 Q3 Q1 Q1 Q3 Q4 Q2 Q3
#>  [26] Q4 Q3 Q2 Q4 Q4 Q2 Q1 Q3 Q2 Q3 Q2 Q1 Q1 Q2 Q3 Q4 Q3 Q1 Q1 Q4 Q2 Q3 Q1 Q1 Q2
#>  [51] Q1 Q3 Q4 Q3 Q2 Q3 Q2 Q4 Q1 Q4 Q3 Q3 Q4 Q4 Q2 Q4 Q1 Q4 Q3 Q3 Q3 Q2 Q3 Q2 Q4
#>  [76] Q1 Q1 Q3 Q4 Q2 Q2 Q4 Q1 Q1 Q4 Q1 Q3 Q2 Q4 Q4 Q4 Q1 Q2 Q4 Q2 Q1 Q2 Q2 Q4 Q3
#> attr(,"breaks")
#>         0%        25%        50%        75%       100% 
#> 0.02229473 0.39187595 0.79633523 1.14824248 2.64893203 
#> attr(,"ties")
#> [1] upward
#> attr(,"quantile_type")
#> [1] 7
#> Levels: Placebo Q1 Q2 Q3 Q4
cut_quantile(x, ties = "split-even", seed = 8213)
#>   [1] Q4 Q3 Q4 Q3 Q2 Q2 Q3 Q2 Q2 Q3 Q1 Q3 Q2 Q1 Q1 Q3 Q1 Q2 Q4 Q2 Q2 Q1 Q4 Q3 Q4
#>  [26] Q4 Q1 Q3 Q1 Q4 Q3 Q3 Q1 Q2 Q4 Q3 Q2 Q2 Q3 Q3 Q1 Q4 Q2 Q3 Q1 Q1 Q1 Q3 Q2 Q3
#>  [51] Q2 Q1 Q4 Q4 Q3 Q4 Q2 Q1 Q2 Q4 Q1 Q1 Q1 Q4 Q3 Q4 Q2 Q4 Q4 Q4 Q4 Q2 Q1 Q2 Q4
#>  [76] Q3 Q3 Q4 Q4 Q3 Q2 Q4 Q2 Q2 Q1 Q2 Q1 Q1 Q1 Q4 Q1 Q2 Q3 Q1 Q3 Q2 Q3 Q3 Q1 Q4
#> attr(,"ties")
#> [1] split-even
#> attr(,"quantile_type")
#> [1] 7
#> Levels: Q1 Q2 Q3 Q4
cut_quantile(x, quantile_type = 1)
#>   [1] Q4 Q3 Q4 Q3 Q2 Q2 Q3 Q2 Q2 Q3 Q1 Q3 Q2 Q1 Q1 Q3 Q1 Q2 Q4 Q2 Q2 Q1 Q4 Q3 Q4
#>  [26] Q4 Q1 Q3 Q1 Q4 Q3 Q3 Q1 Q2 Q4 Q3 Q2 Q2 Q3 Q3 Q1 Q4 Q2 Q3 Q1 Q1 Q1 Q3 Q2 Q3
#>  [51] Q2 Q1 Q4 Q4 Q3 Q4 Q2 Q1 Q2 Q4 Q1 Q1 Q1 Q4 Q3 Q4 Q2 Q4 Q4 Q4 Q4 Q2 Q1 Q2 Q4
#>  [76] Q3 Q3 Q4 Q4 Q3 Q2 Q4 Q2 Q2 Q1 Q2 Q1 Q1 Q1 Q4 Q1 Q2 Q3 Q1 Q3 Q2 Q3 Q3 Q1 Q4
#> attr(,"ties")
#> [1] upward
#> attr(,"quantile_type")
#> [1] 1
#> Levels: Q1 Q2 Q3 Q4
cut_quantile(x, labeller = function(n, breaks) paste0("Group ", 1:n))
#>   [1] Group 4 Group 3 Group 4 Group 3 Group 2 Group 2 Group 3 Group 2 Group 2
#>  [10] Group 3 Group 1 Group 3 Group 2 Group 1 Group 1 Group 3 Group 1 Group 2
#>  [19] Group 4 Group 2 Group 2 Group 1 Group 4 Group 3 Group 4 Group 4 Group 1
#>  [28] Group 3 Group 1 Group 4 Group 3 Group 3 Group 1 Group 2 Group 4 Group 3
#>  [37] Group 2 Group 2 Group 3 Group 3 Group 1 Group 4 Group 2 Group 3 Group 1
#>  [46] Group 1 Group 1 Group 3 Group 2 Group 3 Group 2 Group 1 Group 4 Group 4
#>  [55] Group 3 Group 4 Group 2 Group 1 Group 2 Group 4 Group 1 Group 1 Group 1
#>  [64] Group 4 Group 3 Group 4 Group 2 Group 4 Group 4 Group 4 Group 4 Group 2
#>  [73] Group 1 Group 2 Group 4 Group 3 Group 3 Group 4 Group 4 Group 3 Group 2
#>  [82] Group 4 Group 2 Group 2 Group 1 Group 2 Group 1 Group 1 Group 1 Group 4
#>  [91] Group 1 Group 2 Group 3 Group 1 Group 3 Group 2 Group 3 Group 3 Group 1
#> [100] Group 4
#> attr(,"ties")
#> [1] upward
#> attr(,"quantile_type")
#> [1] 7
#> Levels: Group 1 Group 2 Group 3 Group 4
cut_quantile(x, labeller = c("Low", "Mid-low", "Mid-high", "High"))
#>   [1] High     Mid-high High     Mid-high Mid-low  Mid-low  Mid-high Mid-low 
#>   [9] Mid-low  Mid-high Low      Mid-high Mid-low  Low      Low      Mid-high
#>  [17] Low      Mid-low  High     Mid-low  Mid-low  Low      High     Mid-high
#>  [25] High     High     Low      Mid-high Low      High     Mid-high Mid-high
#>  [33] Low      Mid-low  High     Mid-high Mid-low  Mid-low  Mid-high Mid-high
#>  [41] Low      High     Mid-low  Mid-high Low      Low      Low      Mid-high
#>  [49] Mid-low  Mid-high Mid-low  Low      High     High     Mid-high High    
#>  [57] Mid-low  Low      Mid-low  High     Low      Low      Low      High    
#>  [65] Mid-high High     Mid-low  High     High     High     High     Mid-low 
#>  [73] Low      Mid-low  High     Mid-high Mid-high High     High     Mid-high
#>  [81] Mid-low  High     Mid-low  Mid-low  Low      Mid-low  Low      Low     
#>  [89] Low      High     Low      Mid-low  Mid-high Low      Mid-high Mid-low 
#>  [97] Mid-high Mid-high Low      High    
#> attr(,"ties")
#> [1] upward
#> attr(,"quantile_type")
#> [1] 7
#> Levels: Low Mid-low Mid-high High
```
