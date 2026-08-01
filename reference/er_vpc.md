# The exposure-response VPC mini-language

Create an `er_vpc` specification for a visual predictive check. Build
the plot by adding an observed layer and a simulated layer, and render
with
[`plot()`](https://rdrr.io/r/graphics/plot.default.html)/[`print()`](https://rdrr.io/r/base/print.html)
or
[`er_vpc_build()`](https://erplots.djnavarro.net/reference/er_vpc_build.md).

## Usage

``` r
er_vpc(data, exposure, response, response_type = "auto")
```

## Arguments

- data:

  Data frame or tibble containing the observed data.

- exposure:

  Exposure variable (one variable, unquoted).

- response:

  Response variable (one variable, unquoted).

- response_type:

  One of `"auto"`, `"binary"`, `"continuous"`, or `"count"`.

## Value

An (empty) plot object of class `er_vpc`.

## Details

[`er_vpc_add_observed()`](https://erplots.djnavarro.net/reference/er_vpc_add_observed.md)
bins the observed data and computes its response summary;
[`er_vpc_add_simulated()`](https://erplots.djnavarro.net/reference/er_vpc_add_simulated.md)
must be added afterwards, since it reuses the observed layer's own
binning decision so both sides share identical bin boundaries. Both
layers are singletons (a second call replaces the previous one).

Unlike
[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md),
`er_vpc()` has no stratification concept and always renders a single
panel – see
[`er_vpc_add_observed()`](https://erplots.djnavarro.net/reference/er_vpc_add_observed.md)
for `group_by`, the (orthogonal) variable used to bin/group the
comparison.

## See also

[`er_vpc_add_observed()`](https://erplots.djnavarro.net/reference/er_vpc_add_observed.md),
[`er_vpc_add_simulated()`](https://erplots.djnavarro.net/reference/er_vpc_add_simulated.md),
[`er_vpc_build()`](https://erplots.djnavarro.net/reference/er_vpc_build.md),
[er_model_interface](https://erplots.djnavarro.net/reference/er_model_interface.md)

## Examples

``` r
if (requireNamespace("erglm", quietly = TRUE)) {
library(erglm)
mod <- erglm_model(ae2 ~ aucss + sex, erglm_data, family = binomial())

erglm_data |>
  er_vpc(aucss, ae2) |>
  er_vpc_add_observed(group_by = aucss) |>
  er_vpc_add_simulated(model = mod, seed = 9984) |>
  plot()
}

```
