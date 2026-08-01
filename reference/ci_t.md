# t-interval confidence interval for the mean of continuous data

Computes a t-distribution confidence interval for a sample mean.

## Usage

``` r
ci_t(x, conf_level = 0.95)
```

## Arguments

- x:

  Numeric vector of observations

- conf_level:

  Confidence level

## Value

Named numeric vector (`lower`, `upper`), with confidence level stored as
an attribute. Returns `c(lower = NA, upper = NA)` if fewer than 2
non-missing values are supplied.

## Details

Used by the quantile-binned summary layer (see
[`er_plot_add_quantiles()`](https://erplots.djnavarro.net/reference/er_plot_add_quantiles.md))
and
[`er_vpc_add_observed()`](https://erplots.djnavarro.net/reference/er_vpc_add_observed.md)/
[`er_vpc_add_simulated()`](https://erplots.djnavarro.net/reference/er_vpc_add_simulated.md)
to compute a confidence interval for the mean response within an
exposure bin, for continuous (and, as an approximation, count)
responses. This is the continuous-response analogue of
[`ci_clopper_pearson()`](https://erplots.djnavarro.net/reference/ci_clopper_pearson.md).
`NA`s in `x` are dropped before computing the interval.

## Examples

``` r
ci_t(rnorm(20))
#>      lower      upper 
#> -0.6760526  0.2365877 
#> attr(,"conf_level")
#> [1] 0.95
```
