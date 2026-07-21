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
er_vpc_plot(
  data,
  sim,
  exposure,
  response,
  group_by,
  conf_level = 0.95,
  response_type = c("auto", "binary", "continuous", "count")
)
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

  Response variable (one variable, unquoted). May be binary (0/1, or
  logical) or continuous; see `response_type`

- group_by:

  Variable (unquoted) to stratify predictions

- conf_level:

  Confidence level

- response_type:

  One of `"auto"` (default), `"binary"`, `"continuous"`, or `"count"`.
  Governs how the observed-side summary is computed: response *rate*
  with a Clopper-Pearson CI for `"binary"`, bin *mean* with a t-interval
  for `"continuous"` (see
  [`ci_t()`](https://erplots.djnavarro.net/reference/ci_t.md)), or bin
  *mean* with an exact Poisson interval for `"count"` (see
  [`ci_poisson()`](https://erplots.djnavarro.net/reference/ci_poisson.md)).
  `"auto"` detects from the observed `response` column (entirely in
  `{0, 1}`, or logical, is treated as binary; see
  [`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md)'s
  `response_type` for the same heuristic) and never resolves to
  `"count"`: a count (Poisson-style) response auto-detects as
  `"continuous"` (counts aren't confined to `{0, 1}`) and is summarised
  with the bin-mean-plus-t-interval approximation unless
  `response_type = "count"` is declared explicitly, in which case the
  exact Poisson interval is used instead – see `PLAN.md`'s design
  decision (4) for the rationale.

## Value

A ggplot2 object

## Examples

``` r
if (requireNamespace("erglm", quietly = TRUE)) {
library(erglm)
mod <- erglm_model(ae2 ~ aucss + sex, erglm_data, family = binomial())
sim <- erglm_vpc_sim(mod)
er_vpc_plot(erglm_data, sim, aucss, ae2, group_by = aucss)
er_vpc_plot(erglm_data, sim, aucss, ae2, group_by = sex)

mod_gaussian <- erglm_model(biomarker_change ~ aucss, erglm_data, family = gaussian())
sim_gaussian <- erglm_vpc_sim(mod_gaussian)
er_vpc_plot(erglm_data, sim_gaussian, aucss, biomarker_change, group_by = aucss)

mod_poisson <- erglm_model(ae_count ~ aucss, erglm_data, family = poisson())
sim_poisson <- erglm_vpc_sim(mod_poisson)
er_vpc_plot(
  erglm_data, sim_poisson, aucss, ae_count, group_by = aucss,
  response_type = "count"
)
}
#> Using seed = 4289
#> Using seed = 5993
#> Using seed = 9248

```
