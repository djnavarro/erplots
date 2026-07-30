# Visual predictive check plot for an exposure-response model

Compare observed and simulated response summaries grouped by a
stratification variable.

## Usage

``` r
er_vpc_plot(
  data,
  sim = NULL,
  exposure,
  response,
  group_by,
  model = NULL,
  nsim = 100,
  seed = NULL,
  conf_level = 0.95,
  response_type = c("auto", "binary", "continuous", "count")
)
```

## Arguments

- data:

  Observed data.

- sim:

  Simulated data with matching `exposure`/`response`/`group_by` columns
  and `sim_id`.

- exposure:

  Exposure variable (unquoted).

- response:

  Response variable (unquoted).

- group_by:

  Variable (unquoted) to stratify predictions.

- model:

  A fitted model implementing
  [`er_simulate()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
  with `sim_resp`.

- nsim:

  Number of simulation replicates, only used with `model`.

- seed:

  Optional RNG seed, only used with `model`.

- conf_level:

  Confidence level.

- response_type:

  One of `"auto"`, `"binary"`, `"continuous"`, or `"count"`.

## Value

A ggplot2 object

## Details

`sim` and `model` are mutually exclusive; supply exactly one. `model` is
preferred when it implements
[`er_simulate()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
with `sim_resp` because `er_vpc_plot()` needs response-level simulated
observations rather than only mean predictions.

`response_type` controls how the observed-side summary is computed: rate
with a Clopper-Pearson interval for binary, mean with a t-interval for
continuous, and mean with an exact Poisson interval for count.

## Examples

``` r
if (requireNamespace("erglm", quietly = TRUE)) {
library(erglm)

mod <- erglm_model(
  ae2 ~ aucss + sex, 
  erglm_data, 
  family = binomial()
)

vpc1 <- er_vpc_plot(
  data = erglm_data, 
  exposure = aucss, 
  response = ae2, 
  group_by = aucss, 
  model = mod,
  seed = 9984
)
plot(vpc1)

vpc2 <- er_vpc_plot(
  data = erglm_data, 
  exposure = aucss, 
  response = ae2, 
  group_by = sex, 
  model = mod,
  seed = 5233
)
plot(vpc2)

mod_gaussian <- erglm_model(
  biomarker_change ~ aucss, 
  erglm_data, 
  family = gaussian()
)

vpc3 <- er_vpc_plot(
  data = erglm_data, 
  exposure = aucss, 
  response = biomarker_change,
  group_by = aucss, 
  model = mod_gaussian,
  seed = 5650
)
plot(vpc3)

mod_poisson <- erglm_model(
  ae_count ~ aucss, 
  erglm_data, 
  family = poisson()
)

vpc4 <- er_vpc_plot(
  data = erglm_data, 
  exposure = aucss, 
  response = ae_count, 
  group_by = aucss,
  model = mod_poisson, 
  response_type = "count",
  seed = 2758
)
plot(vpc4)

}




```
