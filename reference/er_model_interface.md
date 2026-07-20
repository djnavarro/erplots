# Model interface for exposure-response plots

`erplots` draws exposure-response plots from *any* fitted model that
implements this small interface, rather than assuming a particular model
class (e.g. a logistic regression `glm`). To make a model usable with
[`er_plot_show_model()`](https://erplots.djnavarro.net/reference/er_plot_show_model.md)
and friends, implement at least a method for `er_predict()`.
Implementing `er_simulate()` additionally enables simulation-based
visualisations (e.g. spaghetti plots, VPCs); implementing `er_summary()`
enables annotations such as p-value labels.

## Usage

``` r
er_predict(model, newdata, conf_level = 0.95, ...)

er_simulate(model, newdata, nsim = 100, seed = NULL, ...)

er_summary(model, ...)
```

## Arguments

- model:

  A fitted exposure-response model object

- newdata:

  A data frame of covariate values at which to predict

- conf_level:

  Confidence level for the prediction interval

- ...:

  Passed to methods

- nsim:

  Number of simulation replicates

- seed:

  Optional RNG seed

## Value

- `er_predict()` returns `newdata` with three additional columns:
  `fit_resp` (point prediction), `ci_lower`, and `ci_upper`.

- `er_simulate()` returns a data frame containing `nsim` replicates of
  `newdata`, with a `sim_id` column identifying each replicate, and a
  `fit_resp` column giving the simulated prediction for that replicate
  (reflecting parameter uncertainty). Models that cannot support
  simulation-based visualisation should not implement a method; the
  default method returns `NULL`; callers should treat a `NULL` result as
  "not available" rather than an error.

- `er_summary()` returns a named list of scalar summary statistics (for
  example `list(p_value = 0.013)`), or `NULL` if nothing is available.
  The default method returns `NULL`.
