# Visual predictive check plot for an exposure-response model

Compares observed response rates against simulated response rates from a
model, stratified by a grouping variable. This function is
model-agnostic: it operates purely on data frames, and can obtain those
data frames in either of two ways – see the `sim`/`model` arguments
below.

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

  Observed data

- sim:

  Simulated data, with the same `exposure`/`response`/`group_by` columns
  as `data`, plus a `sim_id` column identifying each replicate. Mutually
  exclusive with `model`; supply exactly one of the two. Useful for a
  hand-built simulation, or a model-specific helper that doesn't go
  through the
  [`er_simulate()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
  interface. Passing `model` instead is preferred whenever the model
  implements
  [`er_simulate()`](https://erplots.djnavarro.net/reference/er_model_interface.md)'s
  `sim_resp` extension (see
  [er_model_interface](https://erplots.djnavarro.net/reference/er_model_interface.md)).

- exposure:

  Exposure variable (one variable, unquoted)

- response:

  Response variable (one variable, unquoted). May be binary (0/1, or
  logical) or continuous; see `response_type`

- group_by:

  Variable (unquoted) to stratify predictions

- model:

  A fitted exposure-response model implementing
  [`er_simulate()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
  with a `sim_resp` column (see
  [er_model_interface](https://erplots.djnavarro.net/reference/er_model_interface.md)).
  Mutually exclusive with `sim`; supply exactly one of the two. When
  supplied, `sim` is built internally via
  `er_simulate(model, newdata = data, nsim = nsim, seed = seed)`; an
  error is raised if the model's
  [`er_simulate()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
  method doesn't provide `sim_resp` (either because it returns `NULL`,
  i.e. no simulation support at all, or because it only supports the
  parameter-uncertainty-only `fit_resp` used by
  [`er_style_model_spaghetti()`](https://erplots.djnavarro.net/reference/er_style_model.md)
  – a VPC needs the fuller, response-level simulation `sim_resp`
  represents; see
  [er_model_interface](https://erplots.djnavarro.net/reference/er_model_interface.md)
  for the distinction).

- nsim:

  Number of simulation replicates, only used when `model` is supplied.
  Must be a single positive whole number.

- seed:

  Optional RNG seed, only used when `model` is supplied

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
  exact Poisson interval is used instead.

## Value

A ggplot2 object

## Examples

``` r
if (requireNamespace("erglm", quietly = TRUE)) {
library(erglm)
mod <- erglm_model(ae2 ~ aucss + sex, erglm_data, family = binomial())

er_vpc_plot(erglm_data, exposure = aucss, response = ae2, group_by = aucss, model = mod)
er_vpc_plot(erglm_data, exposure = aucss, response = ae2, group_by = sex, model = mod)

mod_gaussian <- erglm_model(biomarker_change ~ aucss, erglm_data, family = gaussian())
er_vpc_plot(
  erglm_data, exposure = aucss, response = biomarker_change,
  group_by = aucss, model = mod_gaussian
)

mod_poisson <- erglm_model(ae_count ~ aucss, erglm_data, family = poisson())
er_vpc_plot(
  erglm_data, exposure = aucss, response = ae_count, group_by = aucss,
  model = mod_poisson, response_type = "count"
)
}
#> Using seed = 9984. Pass `seed = 9984` to reproduce this result.
#> Using seed = 5233. Pass `seed = 5233` to reproduce this result.
#> Using seed = 5650. Pass `seed = 5650` to reproduce this result.
#> Using seed = 2758. Pass `seed = 2758` to reproduce this result.

```
