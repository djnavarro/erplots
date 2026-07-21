# Exact Poisson confidence interval for a count rate

Exact Poisson confidence interval for a count rate

## Usage

``` r
poisson_interval(x, n, conf_level = 0.95)
```

## Arguments

- x:

  Vector (or sum) of observed counts, e.g. all counts falling in one
  exposure bin

- n:

  Number of units the counts were accumulated over (e.g. the number of
  observations in the bin); the rate being estimated is `sum(x) / n`

- conf_level:

  Confidence level

## Value

Named numeric vector (`lower`, `upper`) for the rate `sum(x) / n`, with
confidence level stored as an attribute. Uses the standard exact
("Garwood") Poisson interval, derived from the chi-squared/gamma
relationship, rather than a normal approximation. If the total count is
0, the lower bound is 0 (there's no gamma quantile at `shape = 0`).

## Details

The count-response analogue of
[`clopper_pearson_interval()`](https://erplots.djnavarro.net/reference/clopper_pearson_interval.md),
used by the quantile-binned summary layer (see
[`er_plot_show_quantiles()`](https://erplots.djnavarro.net/reference/er_plot_show_quantiles.md))
and
[`er_vpc_plot()`](https://erplots.djnavarro.net/reference/er_vpc_plot.md)
when `response_type = "count"` is explicitly declared. Unlike
[`t_interval()`](https://erplots.djnavarro.net/reference/t_interval.md)
(the default, opt-in-required approximation used when a count response
auto-detects or is declared `"continuous"`), this interval is exact and
never produces a negative lower bound – see `PLAN.md` design decision
(4) for the rationale and history.

## Examples

``` r
poisson_interval(3, 10)
#>      lower      upper 
#> 0.06186721 0.87672731 
#> attr(,"conf_level")
#> [1] 0.95
```
