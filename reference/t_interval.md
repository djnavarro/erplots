# t-interval confidence interval for the mean of continuous data

t-interval confidence interval for the mean of continuous data

## Usage

``` r
t_interval(x, conf_level = 0.95)
```

## Arguments

- x:

  Numeric vector of observations

- conf_level:

  Confidence level

## Value

Named numeric vector (`lower`, `upper`), with confidence level stored as
an attribute. If fewer than 2 non-missing values are supplied, returns
`c(lower = NA, upper = NA)` (a standard deviation – and hence a
t-interval – isn't defined for a single observation).

## Details

Used by the quantile-binned summary layer (see
[`er_plot_show_quantiles()`](https://erplots.djnavarro.net/reference/er_plot.md))
and
[`er_vpc_plot()`](https://erplots.djnavarro.net/reference/er_vpc_plot.md)
to compute a confidence interval for the mean response within an
exposure bin, for continuous (and, as an approximation, count)
responses. This is the continuous-response analogue of
[`clopper_pearson()`](https://erplots.djnavarro.net/reference/clopper_pearson.md).
`NA`s in `x` are dropped before computing the interval.

## Examples

``` r
t_interval(rnorm(20))
#>      lower      upper 
#> -0.6760526  0.2365877 
#> attr(,"conf_level")
#> [1] 0.95
```
