# The exposure-response VPC mini-language

Create an `er_vpc` specification for a visual predictive check. Build
the plot by adding an observed layer and a simulated layer, and render
with
[`plot()`](https://rdrr.io/r/graphics/plot.default.html)/[`print()`](https://rdrr.io/r/base/print.html)
or
[`er_vpc_build()`](https://erplots.djnavarro.net/reference/er_vpc_build.md).

## Usage

``` r
er_vpc(
  data,
  exposure,
  response,
  response_type = "auto",
  plot_by = NULL,
  n_bins = 4,
  ties = "upward",
  quantile_type = 7,
  labeller = NULL,
  stratify_by = NULL,
  conf_level = 0.95,
  probs = c(0.1, 0.5, 0.9),
  seed = NULL
)
```

## Arguments

- data:

  Data frame or tibble containing the observed data.

- exposure:

  Exposure variable (one variable, unquoted).

- response:

  Response variable (one variable, unquoted).

- response_type:

  One of `"auto"` (the default), `"binary"`, `"continuous"`, or
  `"count"`.

- plot_by:

  Variable (unquoted) plotted on the x-axis and used to bin/group the
  observed vs. simulated comparison. Defaults to `exposure`. A numeric
  variable is split into `n_bins` quantile bins (placebo, i.e. `0`, kept
  in its own bin when `plot_by` is the exposure variable itself); a
  categorical variable is used as-is, with no binning.

- n_bins:

  Number of quantile bins, when `plot_by` is numeric. Defaults to `4`.

- ties, quantile_type, labeller:

  Control how a numeric `plot_by` is split into quantile bins – passed
  straight through to
  [`cut_exposure_quantile()`](https://erplots.djnavarro.net/reference/cut_quantile.md),
  see its documentation for what each controls. Set here, on `er_vpc()`
  itself, rather than on
  [`er_vpc_add_observed()`](https://erplots.djnavarro.net/reference/er_vpc_add_observed.md)/[`er_vpc_add_simulated()`](https://erplots.djnavarro.net/reference/er_vpc_add_simulated.md),
  because the two layers must always agree on how `plot_by` is binned –
  [`er_vpc_add_simulated()`](https://erplots.djnavarro.net/reference/er_vpc_add_simulated.md)
  reuses these exact settings (via
  [`cut_exposure_quantile()`](https://erplots.djnavarro.net/reference/cut_quantile.md)'s
  attributes on the observed layer's own binned column) rather than
  re-resolving them, so both sides always stay in sync.

- stratify_by:

  Optional variable (unquoted) splitting the VPC into one facet panel
  per level, via
  [`ggplot2::facet_wrap()`](https://ggplot2.tidyverse.org/reference/facet_wrap.html),
  used as-is. Must be discrete – a numeric column errors; bin it
  yourself first with
  [`cut_quantile()`](https://erplots.djnavarro.net/reference/cut_quantile.md)/[`cut_exposure_quantile()`](https://erplots.djnavarro.net/reference/cut_quantile.md)
  and pass the resulting factor, for full control over bin
  count/tie-breaking/labels. Must resolve to a different variable than
  `plot_by`. Defaults to `NULL` (no faceting, a single panel, matching
  prior behaviour).

- conf_level:

  Confidence level for both the observed- and simulated-side intervals.
  Must be strictly between 0 and 1. Defaults to `0.95`.

- probs:

  Percentiles to compute for a percentile-based builder (e.g.
  [`er_style_vpc_observed_quantile_line()`](https://erplots.djnavarro.net/reference/er_style_vpc_observed.md)/[`er_style_vpc_simulated_quantile_ribbon()`](https://erplots.djnavarro.net/reference/er_style_vpc_simulated.md)/
  [`er_style_vpc_observed_quantile_errorbar()`](https://erplots.djnavarro.net/reference/er_style_vpc_observed.md)/[`er_style_vpc_simulated_quantile_errorbar()`](https://erplots.djnavarro.net/reference/er_style_vpc_simulated.md);
  ignored by the default adaptive mean/errorbar pair). Only computed for
  a continuous/count response. Defaults to `c(0.1, 0.5, 0.9)`.

- seed:

  Optional single number seeding the observed layer's random tie-break
  when `ties` is `"split-even"` (ignored otherwise). `NULL` (the
  default) draws from the ambient RNG stream. The simulated layer's own
  `"split-even"` tie-break is instead seeded by
  [`er_vpc_add_simulated()`](https://erplots.djnavarro.net/reference/er_vpc_add_simulated.md)'s
  own `seed` argument – the two are independent random draws over
  different data (the observed rows vs. the, typically larger, simulated
  replicate pool), so each is seeded by the call that actually performs
  it.

## Value

An (empty) plot object of class `er_vpc`.

## Details

[`er_vpc_add_observed()`](https://erplots.djnavarro.net/reference/er_vpc_add_observed.md)
bins the observed data and computes its response summary;
[`er_vpc_add_simulated()`](https://erplots.djnavarro.net/reference/er_vpc_add_simulated.md)
must be added afterwards, since it reuses the observed layer's own
binning decision so both sides share identical bin boundaries. Both
layers are singletons (a second call replaces the previous one).

`er_vpc()`'s own stratification (`stratify_by`) is real, but simpler
than
[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md)'s: a
facet-only split via
[`ggplot2::facet_wrap()`](https://ggplot2.tidyverse.org/reference/facet_wrap.html),
with no colour/facet precedence rule to reconcile (see `stratify_by`
below). It's orthogonal to `plot_by` – see
[`er_vpc_add_observed()`](https://erplots.djnavarro.net/reference/er_vpc_add_observed.md)
for `plot_by`, the variable plotted on the x-axis and used to bin/group
the comparison. Whether `plot_by` is `"continuous"` (numeric,
quantile-binned) or `"discrete"` (used as-is) is auto-detected from the
column's type and stored on `object$group$type`, mirroring how
`object$response$type` records the response's type.

## See also

[`er_vpc_add_observed()`](https://erplots.djnavarro.net/reference/er_vpc_add_observed.md),
[`er_vpc_add_simulated()`](https://erplots.djnavarro.net/reference/er_vpc_add_simulated.md),
[`er_vpc_build()`](https://erplots.djnavarro.net/reference/er_vpc_build.md),
[er_model_interface](https://erplots.djnavarro.net/reference/er_model_interface.md)

## Examples

``` r
if (requireNamespace("erglm", quietly = TRUE)) {
library(erglm)
mod <- erglm_model(ae2 ~ aucss + sex, erglm_data, family = binomial())

erglm_data |>
  er_vpc(aucss, ae2, plot_by = aucss) |>
  er_vpc_add_observed() |>
  er_vpc_add_simulated(model = mod, seed = 9984) |>
  plot()
}

```
