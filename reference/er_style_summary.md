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
  own `...` (shared with `style`); see
  [`er_style()`](https://erplots.djnavarro.net/reference/er_style.md)'s
  "Passing extra arguments to a builder" section.

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
all. Both are tagged `er_style_tag(fn, layer = "summary")`, so
[`er_plot_add_summary()`](https://erplots.djnavarro.net/reference/er_plot_add_summary.md)
errors informatively if a builder tagged for a different layer is passed
to it instead.

See [`er_style()`](https://erplots.djnavarro.net/reference/er_style.md)
for the shared builder interface these functions implement, including
how to write a custom builder of your own.

## See also

[`er_style()`](https://erplots.djnavarro.net/reference/er_style.md)
