# Builds an exposure-response plot for a fitted model

Builds an exposure-response plot for a fitted model

## Usage

``` r
er_plot(data, exposure, response, stratify_by = NULL, response_type = "auto")

er_plot_style(object, labels)

er_plot_show_model(
  object,
  model,
  keep_strata = NULL,
  style = "ribbonline",
  conf_level = 0.95
)

er_plot_show_quantiles(
  object,
  keep_strata = NULL,
  style = "errorbar",
  bins = 4,
  conf_level = 0.95
)

er_plot_show_datastrip(
  object,
  keep_strata = NULL,
  style = "jitter",
  panel = "both"
)

er_plot_show_groups(
  object,
  group_by,
  style = "boxplot",
  bins = NULL,
  keep_strata = NULL
)

er_plot_build(object)
```

## Arguments

- data:

  Observed data

- exposure:

  Exposure variable (one variable, unquoted)

- response:

  Response variable (one variable, unquoted)

- stratify_by:

  Stratification variable used for color and fill (one variable,
  unquoted)

- response_type:

  One of `"auto"` (the default), `"binary"`, `"continuous"`, or
  `"count"`. Governs response-scale defaults (e.g. axis limits) and
  which summary/CI method the quantile and VPC layers use. When
  `"auto"`, the response column is classified as `"binary"` if it is
  logical or takes only values in `{0, 1}`, and `"continuous"` otherwise
  – this means a count (Poisson-style) response, e.g. an adverse-event
  count, auto-detects as `"continuous"` (counts aren't confined to
  `{0, 1}`) and is summarised as an approximately-continuous quantity
  (bin mean plus a t-interval). `"auto"` never resolves to `"count"`:
  pass `response_type = "count"` explicitly for a genuine count response
  to instead get bin mean plus an *exact* Poisson interval (see
  [`poisson_interval()`](https://erplots.djnavarro.net/reference/poisson_interval.md)),
  which – unlike the t-interval approximation – never produces a
  negative lower bound. See `PLAN.md`'s design decision (4) for the
  rationale.

- object:

  Partially constructed plot (has S3 class `er_plot`)

- labels:

  Named list of labels

- model:

  A fitted exposure-response model. Must implement
  [`er_predict()`](https://erplots.djnavarro.net/reference/er_model_interface.md);
  implementing
  [`er_simulate()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
  and
  [`er_summary()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
  enables additional visualisations (see
  [er_model_interface](https://erplots.djnavarro.net/reference/er_model_interface.md))

- keep_strata:

  Logical, indicating whether this component should keep the color
  stratification

- style:

  Character string used to specify the partial builder for this
  component

- conf_level:

  Confidence level

- bins:

  Number of exposure bins (not counting placebo)

- panel:

  Character string: "upper", "lower", or "both" (the default)

- group_by:

  Grouping variables to define groups for distribution plots (a
  tidyselection of variables)

## Value

Plot object of class `er_plot`

## Details

`er_plot_show_quantiles()` supports binary (response *rate* with a
Clopper-Pearson CI), continuous (bin *mean* with a t-interval), and
count (bin *mean* with an exact Poisson interval) responses; see
`PLAN.md` for the generalisation history. Count responses are routed
through the continuous path unless `response_type = "count"` is declared
explicitly (see `response_type` above). `er_plot_show_datastrip()`, by
contrast, has a design that is inherently about a binary response
(responders jittered above the exposure line, non-responders below) with
no obvious continuous or count analogue. Calling it on an `er_plot`
whose response was classified (or declared) as `"continuous"` or
`"count"` raises an error rather than silently producing an
empty/misleading strip; see `PLAN.md` for the design decision behind
omitting a continuous/count-response variant.

## Examples

``` r
if (FALSE) { # \dontrun{
library(erglm)
mod <- erglm_model(ae1 ~ aucss, erglm_data, family = binomial())

erglm_data |>
  er_plot(aucss, ae1) |>
  er_plot_show_model(mod) |>
  er_plot_show_quantiles() |>
  er_plot_show_groups(aucss) |>
  plot()

mod2 <- erglm_model(ae2 ~ aucss + sex, erglm_data, family = binomial())
plt <- erglm_data |>
  er_plot(aucss, ae2, stratify_by = sex) |>
  er_plot_show_model(mod2, keep_strata = FALSE) |>
  er_plot_show_quantiles() |>
  er_plot_show_datastrip() |>
  er_plot_show_groups(group_by = c(aucss, treatment), keep_strata = FALSE)

print(plt)
plot(plt)

# continuous response: bin means/t-intervals instead of rates/
# Clopper-Pearson intervals, auto-detected from the response column
mod3 <- erglm_model(biomarker_change ~ aucss, erglm_data, family = gaussian())
erglm_data |>
  er_plot(aucss, biomarker_change) |>
  er_plot_show_model(mod3) |>
  er_plot_show_quantiles() |>
  plot()

# count response: declare response_type = "count" explicitly for an
# exact Poisson interval instead of the t-interval approximation used
# by the auto-detected ("continuous") default
mod4 <- erglm_model(ae_count ~ aucss, erglm_data, family = poisson())
erglm_data |>
  er_plot(aucss, ae_count, response_type = "count") |>
  er_plot_show_model(mod4) |>
  er_plot_show_quantiles() |>
  plot()
} # }
```
