# Distribution-free confidence interval for a sample quantile

Computes a nonparametric confidence interval for a sample quantile using
the order-statistic method (Conover, *Practical Nonparametric
Statistics*): the interval endpoints are order statistics of `x`, chosen
via the binomial distribution of ranks so that no assumption is made
about the shape of `x`'s distribution.

## Usage

``` r
ci_quantile(x, prob = 0.5, conf_level = 0.95)
```

## Arguments

- x:

  Numeric vector of observations

- prob:

  Quantile probability (e.g. `0.1` for the 10th percentile)

- conf_level:

  Confidence level

## Value

Named numeric vector (`lower`, `upper`), with confidence level stored as
an attribute. Returns `c(lower = NA, upper = NA)` if fewer than 2
non-missing values are supplied.

## Details

Used by
[`er_vpc_add_observed()`](https://erplots.djnavarro.net/reference/er_vpc_add_observed.md)
to compute a confidence interval for each requested percentile of the
observed response within an exposure bin (the observed-side analogue of
the across-replicate percentile interval
[`er_vpc_add_simulated()`](https://erplots.djnavarro.net/reference/er_vpc_add_simulated.md)
gets from simulated data, powering
[`er_style_vpc_observed_pointrange_continuous()`](https://erplots.djnavarro.net/reference/er_style_vpc_observed.md)).
Like
[`ci_clopper_pearson()`](https://erplots.djnavarro.net/reference/ci_clopper_pearson.md),
this interval is exact for its target coverage but conservative – the
discreteness of the binomial rank distribution means the achieved
coverage can exceed the nominal `conf_level`, especially for a small bin
or an extreme `prob`. The candidate rank indices are clipped to
`[1, length(x)]`, so a very small or extreme-`prob` bin returns a (still
valid, but wider-than-nominal) interval built from the most extreme
order statistics available rather than `NA`.

## Examples

``` r
ci_quantile(rnorm(100), prob = 0.1)
#>      lower      upper 
#> -1.9100875 -0.9140748 
#> attr(,"conf_level")
#> [1] 0.95
```
