# Add the simulated-data layer to an `er_vpc` VPC

Bins simulated data using the same cutpoints
[`er_vpc_add_observed()`](https://erplots.djnavarro.net/reference/er_vpc_add_observed.md)
already computed, and summarizes it (mean + a percentile interval across
replicates, plus simulated percentile bands for a continuous/count
response).

## Usage

``` r
er_vpc_add_simulated(
  object,
  model = NULL,
  sim = NULL,
  nsim = 100,
  seed = NULL,
  conf_level = 0.95,
  probs = c(0.1, 0.5, 0.9),
  style = er_style_vpc_simulated_errorbar,
  ...
)
```

## Arguments

- object:

  Partially constructed VPC (has S3 class `er_vpc`), which must already
  have an observed layer (see
  [`er_vpc_add_observed()`](https://erplots.djnavarro.net/reference/er_vpc_add_observed.md)).

- model:

  A fitted model implementing
  [`er_simulate()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
  with `sim_resp`. Mutually exclusive with `sim`.

- sim:

  Simulated data with matching exposure/response/`group_by` columns and
  `sim_id`. Mutually exclusive with `model`.

- nsim:

  Number of simulation replicates, only used with `model`.

- seed:

  Optional RNG seed, only used with `model`.

- conf_level:

  Confidence level for the simulated-side interval.

- probs:

  Percentiles to compute for the continuous-x ribbon builder; should
  match whatever `probs` was passed to
  [`er_vpc_add_observed()`](https://erplots.djnavarro.net/reference/er_vpc_add_observed.md)
  (ignored by the default errorbar builder).

- style:

  A function determining how the simulated layer is drawn; see
  [`er_style_vpc_simulated()`](https://erplots.djnavarro.net/reference/er_style_vpc_simulated.md).

- ...:

  Additional named arguments forwarded to `style`.

## Value

`object`, with `object$layer$simulated` populated.

## Details

`sim` and `model` are mutually exclusive; supply exactly one. `model` is
preferred when it implements
[`er_simulate()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
with `sim_resp`, since a VPC needs response-level simulated observations
rather than only mean predictions – this function errors informatively
if `sim_resp` isn't available.

## See also

[`er_vpc()`](https://erplots.djnavarro.net/reference/er_vpc.md),
[`er_vpc_add_observed()`](https://erplots.djnavarro.net/reference/er_vpc_add_observed.md),
[`er_style_vpc_simulated()`](https://erplots.djnavarro.net/reference/er_style_vpc_simulated.md)
