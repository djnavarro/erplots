# Add a summary annotation layer

Adds the summary layer: a corner-placed text/label annotation, drawn
from a log-rank test comparing survival across `stratify_by`'s levels
(the default style,
[`survival::survdiff()`](https://rdrr.io/pkg/survival/man/survdiff.html)),
a supplied model's
[`er_summary()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
result, or purely descriptive observation/event counts – depending on
`style`. Singleton (a second call replaces the previous one).

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
  or `NULL` (the default). Independent of whatever model, if any, was
  passed to
  [`er_tte_add_model()`](https://erplots.djnavarro.net/reference/er_tte_add_model.md)
  – only needed for builder styles (e.g.
  [`er_style_tte_summary_coefficients()`](https://erplots.djnavarro.net/reference/er_style_tte_summary.md)/
  [`er_style_tte_summary_gof()`](https://erplots.djnavarro.net/reference/er_style_tte_summary.md))
  that produce model-based summaries; the default log-rank builder and
  [`er_style_tte_summary_n()`](https://erplots.djnavarro.net/reference/er_style_tte_summary.md)
  both ignore it.

- keep_strata:

  Logical, indicating whether this layer should be split by the plot's
  stratification variable; defaults to `TRUE` if `stratify_by` was set
  in [`er_tte()`](https://erplots.djnavarro.net/reference/er_tte.md),
  `FALSE` otherwise.

- style:

  Function drawing the annotation, or one of the registered short-string
  labels for this layer (see "Styles" below). Defaults to
  [`er_style_tte_summary_logrank()`](https://erplots.djnavarro.net/reference/er_style_tte_summary.md).

- conf_level:

  Confidence level forwarded to
  [`er_summary()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
  (see
  [`?er_model_interface`](https://erplots.djnavarro.net/reference/er_model_interface.md)).
  Defaults to `0.95`. Ignored when `model` is `NULL`.

- summary_args:

  A named list of additional arguments forwarded to
  [`er_summary()`](https://erplots.djnavarro.net/reference/er_model_interface.md),
  distinct from `...` the same way
  [`er_tte_add_model()`](https://erplots.djnavarro.net/reference/er_tte_add_model.md)'s
  `predict_args` is distinct from its own `...` – see its "Details".

- ...:

  Additional named arguments forwarded unchanged to `style` at build
  time (e.g.
  [`er_style_tte_summary_logrank()`](https://erplots.djnavarro.net/reference/er_style_tte_summary.md)'s
  `inset`/ `label_size`/`label_colour`/`label_fill`).

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

|  |  |  |
|----|----|----|
| Label | Builder | Description |
| `"logrank"` | [`er_style_tte_summary_logrank()`](https://erplots.djnavarro.net/reference/er_style_tte_summary.md) | Log-rank test p-value comparing survival across `stratify_by`'s levels (the default). |
| `"n"` | [`er_style_tte_summary_n()`](https://erplots.djnavarro.net/reference/er_style_tte_summary.md) | Subject/event counts; model- and stratification-agnostic. |
| `"coefficients"` | [`er_style_tte_summary_coefficients()`](https://erplots.djnavarro.net/reference/er_style_tte_summary.md) | One line per model parameter, from `model`'s [`er_summary()`](https://erplots.djnavarro.net/reference/er_model_interface.md) `coefficients` table. |
| `"gof"` | [`er_style_tte_summary_gof()`](https://erplots.djnavarro.net/reference/er_style_tte_summary.md) | A goodness-of-fit annotation from `model`'s [`er_summary()`](https://erplots.djnavarro.net/reference/er_model_interface.md) `glance` table. |

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
