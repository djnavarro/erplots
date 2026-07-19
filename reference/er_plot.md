# Builds an exposure-response plot for a fitted model

Builds an exposure-response plot for a fitted model

## Usage

``` r
er_plot(data, exposure, response, stratify_by = NULL)

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
} # }
```
