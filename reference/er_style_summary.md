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

- inset:

  Distance from the panel edge for the annotation label, in normalized
  device coordinates (0 = panel edge, 0.5 = panel centre). Default
  `0.05`, reproducing the previous fixed value (labels placed at `0.05`
  from the near edge and `0.95` from the far edge).

- label_size:

  Label text size (in mm) — maps to `geom_label()`'s `size` parameter
  (geom_label uses `size.unit = "mm"`). If `NULL` the geom default is
  used.

- label_colour:

  Label text colour — mapped to `geom_label()`'s `text.colour`
  parameter. If `NULL` the geom default is used.

- label_fill:

  Label background fill — passed as `fill` to `geom_label()`. If `NULL`
  the geom default is used.

- ...:

  Additional named arguments forwarded from
  [`er_plot_add_model()`](https://erplots.djnavarro.net/reference/er_plot_add_model.md)'s
  own `...` (shared with `style`); see
  [`er_style()`](https://erplots.djnavarro.net/reference/er_style.md)'s
  "Passing extra arguments to a builder" section.

- fields:

  (for `er_style_summary_gof()` only) Which fields from `glance` to
  include, and in what order. A character vector, any subset of
  `c("n", "aic", "bic", "r_squared")` in the desired display order;
  unrecognised names are silently ignored. Default
  `c("n", "aic", "bic", "r_squared")`.

## Value

A geom, or a list of geoms; see
[`er_style()`](https://erplots.djnavarro.net/reference/er_style.md).

## Details

Builders for
[`er_plot_add_summary()`](https://erplots.djnavarro.net/reference/er_plot_add_summary.md),
which annotate the base panel with a summary statistic or descriptive
label rather than drawing a curve or raw data.
`er_style_summary_pvalue()` (the default) places a formatted p-value –
derived from the model's own
[`er_summary()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
method – in whichever corner of the panel is furthest from the observed
data, and draws nothing at all if no model was supplied to
[`er_plot_add_summary()`](https://erplots.djnavarro.net/reference/er_plot_add_summary.md),
or if the layer is stratified (one p-value doesn't unambiguously
describe multiple curves). `er_style_summary_n()` is a model-agnostic
alternative: it always draws, showing the total number of observations
(or, when stratified, one count per stratum level) – demonstrating that
a summary annotation doesn't have to originate from a fitted model at
all. `er_style_summary_coefficients()` draws one line per row of the
model's `coefficients` table (see
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
