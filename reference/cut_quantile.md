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

A factor

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
#> Levels: Placebo Q1 Q2 Q3 Q4
```
