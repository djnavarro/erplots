# Time-to-event plots

``` r

library(erplots)
library(survival)
library(ertte)
```

Alongside the
[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md)/[`er_vpc()`](https://erplots.djnavarro.net/reference/er_vpc.md)
mini-grammars covered in the other articles, erplots supplies a third,
separate mini-grammar built around
[`er_tte()`](https://erplots.djnavarro.net/reference/er_tte.md) for
Kaplan-Meier/survival-over-time figures. It has a different coordinate
system to the other two: time on the x-axis, survival probability on the
y-axis, rather than exposure-vs-response.
[`er_tte()`](https://erplots.djnavarro.net/reference/er_tte.md) itself
computes the Kaplan-Meier estimate once
([`survival::survfit()`](https://rdrr.io/pkg/survival/man/survfit.html)),
and every layer added afterwards reads from that shared fit rather than
recomputing it. As with
[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md)/[`er_vpc()`](https://erplots.djnavarro.net/reference/er_vpc.md),
nothing is drawn until at least one `er_tte_add_*()` layer has been
added and the pipeline is plotted.

This article uses the `lung` dataset from the survival package
throughout, treating `status == 2` as the event indicator (the dataset
codes `1` = censored, `2` = dead).

## A single curve

The minimal pipeline is
[`er_tte()`](https://erplots.djnavarro.net/reference/er_tte.md) followed
by
[`er_tte_add_curve()`](https://erplots.djnavarro.net/reference/er_tte_add_curve.md),
which draws the Kaplan-Meier step curve with a confidence band:

``` r

lung |>
  er_tte(time, status == 2) |>
  er_tte_add_curve() |>
  plot()
```

![](plot-tte_files/figure-html/single-curve-1.png)

[`er_tte_add_censor()`](https://erplots.djnavarro.net/reference/er_tte_add_censor.md)
adds a tick mark at every censoring time, layered on top of the curve:

``` r

lung |>
  er_tte(time, status == 2) |>
  er_tte_add_curve() |>
  er_tte_add_censor() |>
  plot()
```

![](plot-tte_files/figure-html/curve-censor-1.png)

[`er_tte_add_risktable()`](https://erplots.djnavarro.net/reference/er_tte_add_risktable.md)
adds a number-at-risk panel, stacked below the curve via patchwork, with
a shared x-axis:

``` r

lung |>
  er_tte(time, status == 2) |>
  er_tte_add_curve() |>
  er_tte_add_censor() |>
  er_tte_add_risktable() |>
  plot()
```

![](plot-tte_files/figure-html/curve-censor-risktable-1.png)

## Stratified curves

Passing `stratify_by` to
[`er_tte()`](https://erplots.djnavarro.net/reference/er_tte.md) splits
the Kaplan-Meier estimate into one curve per level
(`survival::survfit(... ~ strata)`), and every layer added afterwards
follows suit. `stratify_by` must name a discrete/categorical variable –
`lung$sex` is coded numerically (1/2), so we convert it to a factor
first:

``` r

lung_sex <- lung |> transform(sex = factor(sex, labels = c("Male", "Female")))

lung_sex |>
  er_tte(time, status == 2, stratify_by = sex) |>
  er_tte_add_curve() |>
  er_tte_add_censor() |>
  er_tte_add_risktable() |>
  plot()
```

![](plot-tte_files/figure-html/stratified-curve-1.png)

A genuinely continuous covariate, like `age`, needs binning into groups
first –
[`cut_quantile()`](https://erplots.djnavarro.net/reference/cut_quantile.md)
gives full control over bin count, tie-breaking, and labels:

``` r

lung |>
  transform(age_grp = cut_quantile(age, n = 3)) |>
  er_tte(time, status == 2, stratify_by = age_grp) |>
  er_tte_add_curve() |>
  plot()
```

![](plot-tte_files/figure-html/stratified-continuous-covariate-1.png)

### Log-rank test annotation

[`er_tte_add_pvalue()`](https://erplots.djnavarro.net/reference/er_tte_add_pvalue.md)
adds a corner-placed annotation of the log-rank test comparing survival
across `stratify_by`’s levels
([`survival::survdiff()`](https://rdrr.io/pkg/survival/man/survdiff.html)).
It requires a stratified object – calling it on an unstratified one
errors, since a log-rank test needs at least two groups to compare:

``` r

lung_sex |>
  er_tte(time, status == 2, stratify_by = sex) |>
  er_tte_add_curve() |>
  er_tte_add_pvalue() |>
  plot()
```

![](plot-tte_files/figure-html/logrank-pvalue-1.png)

## Overlaying a parametric model

[`er_tte_add_model()`](https://erplots.djnavarro.net/reference/er_tte_add_model.md)
overlays a fitted parametric $`S(t)`$ curve (with an uncertainty band)
on top of the Kaplan-Meier estimate, for any model implementing
[`er_predict_survival()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
(see [Implementing the model
interface](https://erplots.djnavarro.net/articles/model-interface.md)).
This article uses `ertte`, the package that implements the full model
interface for time-to-event models, fitting an accelerated failure time
model:

``` r

mod <- ertte_aft(Surv(time, status == 2) ~ sex, lung_sex)

lung_sex |>
  er_tte(time, status == 2, stratify_by = sex) |>
  er_tte_add_curve() |>
  er_tte_add_model(mod) |>
  plot()
```

![](plot-tte_files/figure-html/model-aft-1.png)

`model` may reference covariates beyond the strata variable; erplots
fills any other covariate from the plot data with a reference value
(first factor level or numeric mean), the same approach
[`er_plot_add_model()`](https://erplots.djnavarro.net/reference/er_plot_add_model.md)
uses. A Cox model works the same way, and doesn’t require `stratify_by`
to be set at all:

``` r

mod_cox <- ertte_coxph(Surv(time, status == 2) ~ age, lung)

lung |>
  er_tte(time, status == 2) |>
  er_tte_add_curve() |>
  er_tte_add_model(mod_cox) |>
  plot()
```

![](plot-tte_files/figure-html/model-cox-1.png)

Since `age` isn’t a stratification variable here,
[`er_tte_add_model()`](https://erplots.djnavarro.net/reference/er_tte_add_model.md)
predicts `S(t)` at `age`’s mean value from the plot data – a single
overlay curve, rather than one per stratum.

## Theming

[`er_tte_theme()`](https://erplots.djnavarro.net/reference/er_tte_theme.md)
adjusts labels, titles, axis limits, and the overall ggplot2 theme,
without changing which variable drives which aesthetic. As with
[`er_plot_theme()`](https://erplots.djnavarro.net/reference/er_plot_theme.md)/[`er_vpc_theme()`](https://erplots.djnavarro.net/reference/er_vpc_theme.md),
every argument defaults to `NULL` (“leave unchanged”), so repeated calls
only touch the fields they supply:

``` r

lung_sex |>
  er_tte(time, status == 2, stratify_by = sex) |>
  er_tte_add_curve() |>
  er_tte_add_pvalue() |>
  er_tte_theme(
    xlab = "Days",
    ylab = "Overall survival",
    strata_lab = "Sex",
    title = "Kaplan-Meier estimate of overall survival",
    theme_base = ggplot2::theme_minimal()
  ) |>
  plot()
```

![](plot-tte_files/figure-html/theming-1.png)

`subtitle`/`caption` add further plot-level text, and `ylim` overrides
the survival-probability axis’s displayed range – purely cosmetic, since
a survival probability is always modelled on `[0, 1]` regardless of
what’s shown:

``` r

lung_sex |>
  er_tte(time, status == 2, stratify_by = sex) |>
  er_tte_add_curve() |>
  er_tte_theme(
    subtitle = "Lung cancer cohort",
    caption = "Source: survival::lung",
    ylim = c(0, 1.05)
  ) |>
  plot()
```

![](plot-tte_files/figure-html/theming-labels-1.png)

One theming argument is structural rather than purely cosmetic, unlike
`ylim` above: `xlim` overwrites the time axis’s limits directly, and
those limits are what
[`er_tte_add_model()`](https://erplots.djnavarro.net/reference/er_tte_add_model.md)’s
default `time_grid` and
[`er_tte_add_risktable()`](https://erplots.djnavarro.net/reference/er_tte_add_risktable.md)’s
default `times` are computed from *at add-layer time*. So
`er_tte_theme(xlim = ...)` needs to be called before those layers to
affect their defaults – calling it afterwards only changes the curve
panel’s own displayed range:

``` r

lung |>
  er_tte(time, status == 2) |>
  er_tte_theme(xlim = c(0, 600)) |>
  er_tte_add_curve() |>
  er_tte_add_risktable() |>
  plot()
#> Warning: Removed 24 rows containing missing values or values outside the scale range
#> (`geom_step()`).
```

![](plot-tte_files/figure-html/theming-xlim-1.png)

`format_p` controls how the log-rank annotation’s p-value is displayed:

``` r

lung_sex |>
  er_tte(time, status == 2, stratify_by = sex) |>
  er_tte_add_curve() |>
  er_tte_add_pvalue() |>
  er_tte_theme(format_p = scales::label_pvalue(accuracy = 0.0001, add_p = TRUE)) |>
  plot()
```

![](plot-tte_files/figure-html/theming-format-p-1.png)

`draw_key` swaps the legend glyph the curve/model layers use, e.g. a
point instead of the default filled rectangle:

``` r

lung_sex |>
  er_tte(time, status == 2, stratify_by = sex) |>
  er_tte_add_curve() |>
  er_tte_theme(draw_key = ggplot2::draw_key_point) |>
  plot()
```

![](plot-tte_files/figure-html/theming-draw-key-1.png)

`height_curve`/`height_risktable` set the relative heights patchwork
gives to the two stacked panels once
[`er_tte_add_risktable()`](https://erplots.djnavarro.net/reference/er_tte_add_risktable.md)
is in play – supplying only one leaves the other unchanged:

``` r

lung |>
  er_tte(time, status == 2) |>
  er_tte_add_curve() |>
  er_tte_add_risktable() |>
  er_tte_theme(height_curve = 3, height_risktable = 2) |>
  plot()
```

![](plot-tte_files/figure-html/theming-heights-1.png)

`format_percent` is also accepted and stored, reserved for a future
risk-table/survival-probability builder that formats a value as a
percentage – no built-in TTE style currently reads it, so setting it has
no visible effect today.

For anything
[`er_tte_theme()`](https://erplots.djnavarro.net/reference/er_tte_theme.md)
doesn’t cover, `+ ggplot2::theme(...)`/`+ ggplot2::labs(...)` remains
the general-purpose escape hatch on the ggplot2 object
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) returns –
though note that once
[`er_tte_add_risktable()`](https://erplots.djnavarro.net/reference/er_tte_add_risktable.md)
is in play, the result is a patchwork composition of two panels rather
than a single ggplot2 object, so such additions only apply to the
top-level object, not automatically to both panels.
