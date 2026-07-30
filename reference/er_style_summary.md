# Summary annotation builders for exposure-response plots

Summary annotation builders for exposure-response plots

## Usage

``` r
er_style_summary_pvalue(
  data,
  config,
  stratify,
  exposure,
  response,
  strata,
  theme,
  inset = 0.05,
  label_size = NULL,
  label_colour = NULL,
  label_fill = NULL,
  ...
)

er_style_summary_n(
  data,
  config,
  stratify,
  exposure,
  response,
  strata,
  theme,
  inset = 0.05,
  label_size = NULL,
  label_colour = NULL,
  label_fill = NULL,
  ...
)

er_style_summary_coefficients(
  data,
  config,
  stratify,
  exposure,
  response,
  strata,
  theme,
  inset = 0.05,
  label_size = NULL,
  label_colour = NULL,
  label_fill = NULL,
  ...
)

er_style_summary_gof(
  data,
  config,
  stratify,
  exposure,
  response,
  strata,
  theme,
  inset = 0.05,
  fields = c("n", "aic", "bic", "r_squared"),
  label_size = NULL,
  label_colour = NULL,
  label_fill = NULL,
  ...
)
```

## Arguments

- data:

  The original data frame.

- config:

  Configuration for the specific plot.

- stratify:

  Logical: whether to stratify.

- exposure:

  Exposure variable.

- response:

  Response variable.

- strata:

  Stratification variable.

- theme:

  Theme components.

- inset:

  Distance from the panel edge for the annotation label.

- label_size:

  Label text size.

- label_colour:

  Label text colour.

- label_fill:

  Label background fill.

- ...:

  Additional named arguments forwarded from
  [`er_plot_add_model()`](https://erplots.djnavarro.net/reference/er_plot_add_model.md)'s
  own `...`.

- fields:

  Fields from `glance` to include for `er_style_summary_gof()`.

## Value

A geom, or a list of geoms; see
[`er_style()`](https://erplots.djnavarro.net/reference/er_style.md).

## Details

Builders for
[`er_plot_add_summary()`](https://erplots.djnavarro.net/reference/er_plot_add_summary.md)
annotate the base panel with a summary statistic or descriptive label.
`er_style_summary_pvalue()` draws a formatted p-value from the model's
[`er_summary()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
result; `er_style_summary_n()` draws observation counts and doesn't have
to originate from a fitted model at all.
`er_style_summary_coefficients()` draws one line per row of the model's
`coefficients` table (see
[`er_summary()`](https://erplots.djnavarro.net/reference/er_model_interface.md)'s
`coefficients` field), useful for models with several parameters and no
single privileged p-value (e.g. a multi-parameter nonlinear model); it
draws nothing if `coefficients` wasn't supplied, or if the layer is
stratified. `er_style_summary_gof()` draws a single-line,
comma-separated goodness-of-fit annotation from the model's `glance`
field (see
[`er_summary()`](https://erplots.djnavarro.net/reference/er_model_interface.md))
– a curated subset (`N`, `AIC`, `BIC`, `R\u00b2`) rather than every
reserved `glance` column, showing only whichever of those four are
actually present and non-`NA`; it draws nothing if none of them are
available, or if the layer is stratified. All four builders are tagged
`er_style_tag(fn, layer = "summary")`, so
[`er_plot_add_summary()`](https://erplots.djnavarro.net/reference/er_plot_add_summary.md)
errors informatively if a builder tagged for a different layer is passed
to it instead.

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

  # er_style_summary_pvalue(): the default, drawn from the model's own
  # er_summary()
  erglm_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(mod) |>
    er_plot_add_summary(model = mod, style = er_style_summary_pvalue) |>
    plot()

  # er_style_summary_n(): model-agnostic observation count
  erglm_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(mod) |>
    er_plot_add_summary(style = er_style_summary_n) |>
    plot()
}


```
