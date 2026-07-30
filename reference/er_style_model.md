# Model curve builders for exposure-response plots

Builder functions for the `model` layer
([`er_plot_add_model()`](https://erplots.djnavarro.net/reference/er_plot_add_model.md)),
drawing the fitted exposure-response curve as a ribbon-and-line, a line
alone, or a spaghetti plot of simulated draws.

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
  ...,
  ribbon_fill = "grey40",
  ribbon_alpha = 0.25,
  ribbon_edges = FALSE,
  linewidth = 1
)

er_style_model_line(
  data,
  config,
  stratify,
  exposure,
  response,
  strata,
  theme,
  ...,
  linewidth = 1
)

er_style_model_spaghetti(
  data,
  config,
  stratify,
  exposure,
  response,
  strata,
  theme,
  ...,
  alpha = NULL,
  linewidth = 1,
  nsim = 100L
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

- ribbon_fill:

  Fill colour for `er_style_model_ribbonline()`'s ribbon. Only takes
  effect when the layer is unstratified – a stratified ribbon already
  maps `fill` to the strata variable, so this argument is ignored in
  that case. Default `"grey40"`.

- ribbon_alpha:

  Transparency of `er_style_model_ribbonline()`'s ribbon (`0`-`1`),
  stratified or not. Default `0.25`.

- ribbon_edges:

  Whether `er_style_model_ribbonline()` additionally draws a dashed
  [`ggplot2::geom_path()`](https://ggplot2.tidyverse.org/reference/geom_path.html)
  along the ribbon's own `ci_lower`/`ci_upper` bounds, on top of the
  shaded ribbon fill. Default `FALSE` (ribbon fill only).

- linewidth:

  Width of the fitted curve's line, for all three model builders
  (`er_style_model_ribbonline()`/`_line()`'s single curve,
  `er_style_model_spaghetti()`'s mean curve drawn on top of the
  spaghetti draws). Default `1`.

- alpha:

  Transparency of `er_style_model_spaghetti()`'s individual simulated
  draws (`0`-`1`). Defaults to `NULL`, which uses `0.1` unstratified and
  `0.25` stratified. An explicit value overrides this for both cases
  uniformly.

- nsim:

  Number of simulated draws for `er_style_model_spaghetti()`, passed to
  [`er_simulate()`](https://erplots.djnavarro.net/reference/er_model_interface.md).
  Default `100L`.

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

  # overriding a builder's own visual defaults: a thicker, less
  # saturated ribbon with its bounds outlined, and fewer/fainter
  # spaghetti draws
  erglm_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(
      mod,
      style = er_style_model_ribbonline,
      ribbon_fill = "steelblue",
      ribbon_alpha = 0.15,
      ribbon_edges = TRUE,
      linewidth = 1.5
    ) |>
    plot()

  erglm_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(
      mod,
      style = er_style_model_spaghetti,
      seed = 4821,
      nsim = 40L,
      alpha = 0.05
    ) |>
    plot()
}





```
