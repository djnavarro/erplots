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
  style = er_style_vpc_simulated_mean_errorbar,
  simulate_args = list(),
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

  Simulated data with matching exposure/response/`plot_by` columns and
  `sim_id`. Mutually exclusive with `model`.

- nsim:

  Number of simulation replicates, only used with `model`. Defaults to
  `100`.

- seed:

  Optional RNG seed. Used for `model`'s own simulation draws, and also
  (regardless of whether `sim`/`model` was supplied) to seed this
  layer's random tie-break when
  [`er_vpc()`](https://erplots.djnavarro.net/reference/er_vpc.md)'s
  `ties` is `"split-even"` – see
  [`er_vpc()`](https://erplots.djnavarro.net/reference/er_vpc.md)'s own
  `seed` argument for the observed layer's independent tie-break seed.

- style:

  A function determining how the simulated layer is drawn. Defaults to
  [`er_style_vpc_simulated_mean_errorbar()`](https://erplots.djnavarro.net/reference/er_style_vpc_simulated.md);
  see
  [`er_style_vpc_simulated()`](https://erplots.djnavarro.net/reference/er_style_vpc_simulated.md)
  for the other built-in options.

- simulate_args:

  A named list of additional arguments forwarded to
  [`er_simulate()`](https://erplots.djnavarro.net/reference/er_model_interface.md),
  only used with `model`. Distinct from `...` the same way
  [`er_plot_add_model()`](https://erplots.djnavarro.net/reference/er_plot_add_model.md)'s
  `predict_args` is distinct from its own `...` – see that function's
  "Details" for the rationale.

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

`conf_level`/`probs` are set once on
[`er_vpc()`](https://erplots.djnavarro.net/reference/er_vpc.md) itself
(rather than here), so the observed and simulated layers always agree on
them.

## See also

[`er_vpc()`](https://erplots.djnavarro.net/reference/er_vpc.md),
[`er_vpc_add_observed()`](https://erplots.djnavarro.net/reference/er_vpc_add_observed.md),
[`er_style_vpc_simulated()`](https://erplots.djnavarro.net/reference/er_style_vpc_simulated.md)
