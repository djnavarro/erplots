# Build and render an `er_vpc` object

Assembles the observed/simulated layers into a single ggplot2 object.

## Usage

``` r
er_vpc_build(object)
```

## Arguments

- object:

  Partially constructed VPC (has S3 class `er_vpc`).

## Value

The input `object`, with `object$output` (the composed ggplot2 plot)
populated.

## Details

The user does not typically invoke this function directly. Instead, it
is called automatically when
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) is called.

## See also

[`er_vpc()`](https://erplots.djnavarro.net/reference/er_vpc.md)
