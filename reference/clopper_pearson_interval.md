# Clopper-Pearson confidence interval for binary data

Clopper-Pearson confidence interval for binary data

## Usage

``` r
clopper_pearson_interval(x, n, conf_level = 0.95)
```

## Arguments

- x:

  Number of successes

- n:

  Total number of trials

- conf_level:

  Confidence level

## Value

Named numeric vector, with confidence level stored as an attribute

## Details

Used by the quantile-binned summary layer (see
[`er_plot_show_quantiles()`](https://erplots.djnavarro.net/reference/er_plot_show_quantiles.md))
to compute empirical response-rate confidence intervals. This assumes a
binary (0/1) response.

## Examples

``` r
clopper_pearson_interval(1, 10)
#>       lower       upper 
#> 0.002528579 0.445016117 
#> attr(,"conf_level")
#> [1] 0.95
```
