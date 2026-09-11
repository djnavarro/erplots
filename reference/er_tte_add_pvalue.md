# Add a log-rank test annotation layer

Adds the pvalue layer: a corner-placed annotation of the log-rank test
comparing survival across `stratify_by`'s levels
([`survival::survdiff()`](https://rdrr.io/pkg/survival/man/survdiff.html)).
Singleton (a second call replaces the previous one). Requires a
stratified `er_tte` object – a log-rank test compares two or more
groups, so this errors if `stratify_by` wasn't set in
[`er_tte()`](https://erplots.djnavarro.net/reference/er_tte.md).

## Usage

``` r
er_tte_add_pvalue(object, style = NULL, ...)
```

## Arguments

- object:

  Partially constructed plot (has S3 class `er_tte`, with `stratify_by`
  set – see
  [`er_tte()`](https://erplots.djnavarro.net/reference/er_tte.md)).

- style:

  Function drawing the annotation. Defaults to
  [`er_style_tte_pvalue_logrank()`](https://erplots.djnavarro.net/reference/er_style_tte_pvalue.md).

- ...:

  Additional named arguments forwarded unchanged to `style` at build
  time (e.g.
  [`er_style_tte_pvalue_logrank()`](https://erplots.djnavarro.net/reference/er_style_tte_pvalue.md)'s
  `inset`/ `label_size`/`label_colour`/`label_fill`).

## Value

The input `object`, with the pvalue layer added.

## Details

The annotation is placed in whichever corner of the panel is currently
furthest from the plotted survival curve(s), computed the same way
[`er_plot_add_summary()`](https://erplots.djnavarro.net/reference/er_plot_add_summary.md)'s
corner-placed annotation avoids the raw data – see
[`er_style_tte_pvalue_logrank()`](https://erplots.djnavarro.net/reference/er_style_tte_pvalue.md).

## See also

[`er_tte()`](https://erplots.djnavarro.net/reference/er_tte.md),
[`er_style_tte_pvalue_logrank()`](https://erplots.djnavarro.net/reference/er_style_tte_pvalue.md)

## Examples

``` r
library(survival)
lung |>
  transform(sex = factor(sex, labels = c("Male", "Female"))) |>
  er_tte(time, status == 2, stratify_by = sex) |>
  er_tte_add_curve() |>
  er_tte_add_pvalue() |>
  plot()

```
