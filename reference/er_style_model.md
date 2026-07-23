# Model curve builders for exposure-response plots

Model curve builders for exposure-response plots

## Usage

``` r
er_style_model_ribbonline(
  data,
  config,
  stratify,
  exposure,
  response,
  strata,
  theme,
  ...
)

er_style_model_line(
  data,
  config,
  stratify,
  exposure,
  response,
  strata,
  theme,
  ...
)

er_style_model_spaghetti(
  data,
  config,
  stratify,
  exposure,
  response,
  strata,
  theme,
  ...
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

- theme:

  Theme components

- ...:

  Additional named arguments forwarded from
  [`er_plot_add_model()`](https://erplots.djnavarro.net/reference/er_plot_add_model.md)'s
  own `...`; see
  [`er_style()`](https://erplots.djnavarro.net/reference/er_style.md)'s
  "Passing extra arguments to a builder" section.
  `er_style_model_spaghetti()` reads a `seed` from here (falling back to
  `config$seed` – currently always `NULL` for the model layer – when
  none is supplied) to pass to
  [`er_simulate()`](https://erplots.djnavarro.net/reference/er_model_interface.md),
  letting a caller override erglm's auto-selected seed.

## Value

A geom, or a list of geoms; see
[`er_style()`](https://erplots.djnavarro.net/reference/er_style.md).

## Details

Builders for the `model` layer
([`er_plot_add_model()`](https://erplots.djnavarro.net/reference/er_plot_add_model.md)),
which draws the fitted curve (and, where applicable, its uncertainty)
over the exposure range: `er_style_model_ribbonline()` (ribbon plus
line, the default), `er_style_model_line()` (line only, no ribbon), and
`er_style_model_spaghetti()` (a spaghetti plot of simulated draws, for
models that implement
[`er_simulate()`](https://erplots.djnavarro.net/reference/er_model_interface.md)).
All three are tagged `er_style_tag(fn, layer = "model")`, so
[`er_plot_add_model()`](https://erplots.djnavarro.net/reference/er_plot_add_model.md)
errors informatively if handed one of these tagged for a different layer
entirely (e.g. `"summary"`, meant for
[`er_plot_add_summary()`](https://erplots.djnavarro.net/reference/er_plot_add_summary.md)).

See [`er_style()`](https://erplots.djnavarro.net/reference/er_style.md)
for the shared builder interface these functions implement, including
how to write a custom builder of your own.

## See also

[`er_style()`](https://erplots.djnavarro.net/reference/er_style.md)

## Examples

``` r
if (requireNamespace("erglm", quietly = TRUE)) {
  library(erglm)
  mod <- erglm_model(ae1 ~ aucss, erglm_data, family = binomial())

  # er_style_model_ribbonline(): ribbon + line, the default
  erglm_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(mod, style = er_style_model_ribbonline) |>
    plot()

  # er_style_model_line(): line only, no ribbon
  erglm_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(mod, style = er_style_model_line) |>
    plot()

  # er_style_model_spaghetti(): simulated draws instead of a ribbon;
  # `seed` is forwarded to `er_simulate()` via `...`
  erglm_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(mod, style = er_style_model_spaghetti, seed = 4821) |>
    plot()
}



```
