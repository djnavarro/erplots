# Add a summary annotation layer

Adds the summary layer to a TTE plot: a corner-placed text/label
annotation, summarising one or more aspects of the plot or the data.

## Usage

``` r
er_tte_add_summary(
  object,
  model = NULL,
  keep_strata = NULL,
  style = NULL,
  conf_level = 0.95,
  summary_args = list(),
  ...
)
```

## Arguments

- object:

  Partially constructed plot (has S3 class `er_tte`).

- model:

  A fitted time-to-event model implementing
  [`er_summary()`](https://erplots.djnavarro.net/reference/er_model_interface.md),
  or `NULL` (the default). Only needed for styles that produce
  model-based summaries, ignored by other style builder functions.

- keep_strata:

  Logical; whether this layer should use stratification. Defaults to
  `TRUE` when a stratification variable has been specified, and `FALSE`
  otherwise.

- style:

  Style used to produce the summary layer annotation. Can either be a
  string corresponding to one of the registered style labels (e.g.,
  `"logrank"`, the default), or a builder function used to compute the
  relevant plot object (see "Styles" below).

- conf_level:

  Confidence level forwarded to
  [`er_summary()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
  (see
  [`?er_model_interface`](https://erplots.djnavarro.net/reference/er_model_interface.md)).
  Defaults to `0.95`. Ignored when `model` is `NULL`.

- summary_args:

  A named list of additional arguments forwarded to
  [`er_summary()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
  when generating summaries.

- ...:

  Additional named arguments forwarded to the `style` builder function
  when the plot is built.

## Value

The input `object`, with the summary layer added.

## Details

The annotation is placed in whichever corner of the panel is currently
furthest from the plotted survival curve(s), computed the same way
[`er_plot_add_summary()`](https://erplots.djnavarro.net/reference/er_plot_add_summary.md)'s
corner-placed annotation avoids the raw data – see
[`er_style_tte_summary_logrank()`](https://erplots.djnavarro.net/reference/er_style_tte_summary.md).

The default log-rank builder draws nothing on an unstratified object, or
one with only 1 stratum level present in the data, rather than erroring
– a log-rank test needs at least 2 groups to compare. Other builders
(e.g.
[`er_style_tte_summary_n()`](https://erplots.djnavarro.net/reference/er_style_tte_summary.md))
work regardless of stratification.

## Styles

The following pre-defined styles are available for this layer. Please
see the documentation for the corresponding builder function to see what
customisation options are available:

|  |  |  |
|----|----|----|
| Label | Builder | Description |
| `"logrank"` | [`er_style_tte_summary_logrank()`](https://erplots.djnavarro.net/reference/er_style_tte_summary.md) | Log-rank test p-value comparing survival across `stratify_by`'s levels (the default). |
| `"n"` | [`er_style_tte_summary_n()`](https://erplots.djnavarro.net/reference/er_style_tte_summary.md) | Subject/event counts; model- and stratification-agnostic. |
| `"coefficients"` | [`er_style_tte_summary_coefficients()`](https://erplots.djnavarro.net/reference/er_style_tte_summary.md) | One line per model parameter, from `model`'s [`er_summary()`](https://erplots.djnavarro.net/reference/er_model_interface.md) `coefficients` table. |
| `"gof"` | [`er_style_tte_summary_gof()`](https://erplots.djnavarro.net/reference/er_style_tte_summary.md) | A goodness-of-fit annotation from `model`'s [`er_summary()`](https://erplots.djnavarro.net/reference/er_model_interface.md) `glance` table. |

See
[`er_style_tte()`](https://erplots.djnavarro.net/reference/er_style_tte.md)
for details on how style builder functions are defined for the TTE
mini-grammar, should a custom style be required.

## See also

[`er_tte()`](https://erplots.djnavarro.net/reference/er_tte.md),
[`er_style_tte_summary_logrank()`](https://erplots.djnavarro.net/reference/er_style_tte_summary.md)

## Examples

``` r
library(survival)
lung |>
  transform(sex = factor(sex, labels = c("Male", "Female"))) |>
  er_tte(time, status == 2, stratify_by = sex) |>
  er_tte_add_curve() |>
  er_tte_add_summary() |>
  plot()


# a purely descriptive annotation, with no model or log-rank test at all
lung |>
  er_tte(time, status == 2) |>
  er_tte_add_curve() |>
  er_tte_add_summary(style = er_style_tte_summary_n) |>
  plot()

```
