# Add the simulated-data layer to a VPC plot

Bins the simulation data for a VPC plot and computes binned response
summaries for comparison against the observed data layer.

## Usage

``` r
er_vpc_add_simulated(
  object,
  model = NULL,
  sim = NULL,
  style = er_style_vpc_simulated_mean_errorbar,
  nsim = 100,
  seed = NULL,
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

- style:

  Style used to draw the VPC simulation layer. Can either be a string
  corresponding to one of the registered style labels (e.g.,
  `"mean_errorbar"`, the default), or a builder function used to compute
  the relevant plot object (see "Styles" below).

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

- simulate_args:

  A named list of additional arguments forwarded to
  [`er_simulate()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
  when simulating from the model.

- ...:

  Additional named arguments forwarded to the `style` builder function
  when the plot is built.

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

## Styles

The following pre-defined styles are available for this layer. Please
see the documentation for the corresponding builder function to see what
customisation options are available:

|  |  |  |
|----|----|----|
| Label | Builder | Description |
| `"mean_errorbar"` | [`er_style_vpc_simulated_mean_errorbar()`](https://erplots.djnavarro.net/reference/er_style_vpc_simulated.md) | Mean/rate + CI per bin, x-position adaptive to `plot_by`'s type (the default). |
| `"quantile_ribbon"` | [`er_style_vpc_simulated_quantile_ribbon()`](https://erplots.djnavarro.net/reference/er_style_vpc_simulated.md) | One ribbon per requested percentile against a continuous `plot_by` axis. |
| `"quantile_errorbar"` | [`er_style_vpc_simulated_quantile_errorbar()`](https://erplots.djnavarro.net/reference/er_style_vpc_simulated.md) | Point + error bar per bin and per requested percentile. |

See
[`er_style_vpc()`](https://erplots.djnavarro.net/reference/er_style_vpc.md)
for details on how style builder functions are defined for the VPC
mini-grammar, should a custom style be required.

## See also

[`er_vpc()`](https://erplots.djnavarro.net/reference/er_vpc.md),
[`er_vpc_add_observed()`](https://erplots.djnavarro.net/reference/er_vpc_add_observed.md),
[`er_style_vpc_simulated()`](https://erplots.djnavarro.net/reference/er_style_vpc_simulated.md)
