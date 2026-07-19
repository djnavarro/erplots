# Visual predictive check plot for an exposure-response model

Compares observed response rates against simulated response rates from a
model, stratified by a grouping variable. This function is
model-agnostic: it operates purely on data frames. The `sim` data frame
is expected to contain one row per simulated observation per replicate,
with a `sim_id` column identifying each replicate (see e.g.
[`erglm::erglm_vpc_sim()`](https://erglm.djnavarro.net/reference/erglm_vpc_sim.html)
for one way to generate such simulations from a fitted model).

## Usage

``` r
er_vpc_plot(data, sim, exposure, response, group_by, conf_level = 0.95)
```

## Arguments

- data:

  Observed data

- sim:

  Simulated data, with the same `exposure`/`response`/`group_by` columns
  as `data`, plus a `sim_id` column identifying each replicate

- exposure:

  Exposure variable (one variable, unquoted)

- response:

  Response variable (one variable, unquoted). Assumed to be binary (0/1)

- group_by:

  Variable (unquoted) to stratify predictions

- conf_level:

  Confidence level

## Value

A ggplot2 object

## Examples

``` r
if (FALSE) { # \dontrun{
library(erglm)
mod <- erglm_model(ae2 ~ aucss + sex, erglm_data, family = binomial())
sim <- erglm_vpc_sim(mod)
er_vpc_plot(erglm_data, sim, aucss, ae2, group_by = aucss)
er_vpc_plot(erglm_data, sim, aucss, ae2, group_by = sex)
} # }
```
