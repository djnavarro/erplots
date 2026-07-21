# Model curve builders for exposure-response plots

Model curve builders for exposure-response plots

## Usage

``` r
er_builder_model_ribbonline(
  data,
  config,
  stratify,
  exposure,
  response,
  strata,
  style
)

er_builder_model_line(
  data,
  config,
  stratify,
  exposure,
  response,
  strata,
  style
)

er_builder_model_spaghetti(
  data,
  config,
  stratify,
  exposure,
  response,
  strata,
  style
)
```

## Arguments

- data:

  The original data frame

- config:

  Configuration for the specific plot

- stratify:

  Logical indicating whether to stratify

- exposure:

  Exposure variable

- response:

  Response variable

- strata:

  Stratification variable

- style:

  Style components

## Value

A geom, or a list of geoms; see
[`er_builder()`](https://erplots.djnavarro.net/reference/er_builder.md).

## Details

Builders for the `model` layer
([`er_plot_add_model()`](https://erplots.djnavarro.net/reference/er_plot_add_model.md)),
which draws the fitted curve (and, where applicable, its uncertainty)
over the exposure range: `er_builder_model_ribbonline()` (ribbon plus
line, the default), `er_builder_model_line()` (line only, no ribbon),
and `er_builder_model_spaghetti()` (a spaghetti plot of simulated draws,
for models that implement
[`er_simulate()`](https://erplots.djnavarro.net/reference/er_model_interface.md)).
All three are tagged `er_builder_tag(fn, layer = "model")`, so
[`er_plot_add_model()`](https://erplots.djnavarro.net/reference/er_plot_add_model.md)
errors informatively if handed one of these swapped into the
`summary_builder` argument, or a builder tagged for a different layer
entirely.

See
[`er_builder()`](https://erplots.djnavarro.net/reference/er_builder.md)
for the shared builder interface these functions implement, including
how to write a custom builder of your own.

## See also

[`er_builder()`](https://erplots.djnavarro.net/reference/er_builder.md)
