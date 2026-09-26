# Add a grouped exposure-distribution panel

Adds a group layer: a boxplot/violin panel showing the *exposure*
distribution, split by one or more grouping variables (continuous
grouping variables are binned into quantiles first).

## Usage

``` r
er_plot_add_groups(
  object,
  group_by,
  style = NULL,
  bins = NULL,
  keep_strata = NULL,
  ties = "upward",
  quantile_type = 7,
  labeller = NULL,
  ...
)
```

## Arguments

- object:

  Partially constructed plot (has S3 class `er_plot`).

- group_by:

  Grouping variables to define groups for distribution plots (a
  tidyselection of variables).

- style:

  Function drawing each group panel – defaults to
  [`er_style_group_boxplot()`](https://erplots.djnavarro.net/reference/er_style_group.md).
  Applied to every grouping variable added by this call; see
  [`er_style()`](https://erplots.djnavarro.net/reference/er_style.md)
  and "Details". Or one of the registered short-string labels for this
  layer (see "Styles" below).

- bins:

  Number of quantile bins used for continuous grouping variables
  (`NULL`, the default, uses
  [`cut_quantile()`](https://erplots.djnavarro.net/reference/cut_quantile.md)'s
  own default). Applied identically to every grouping variable added by
  this call.

- keep_strata:

  Logical, indicating whether this layer should be split by the plot's
  stratification variable; defaults to `TRUE` if `stratify_by` was set
  in [`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md),
  `FALSE` otherwise. See "Details" for an error case.

- ties, quantile_type, labeller:

  Passed straight through to
  [`cut_quantile()`](https://erplots.djnavarro.net/reference/cut_quantile.md)/[`cut_exposure_quantile()`](https://erplots.djnavarro.net/reference/cut_quantile.md)
  to control how a continuous grouping variable is split into bins – see
  their documentation for what each controls. Applied identically to
  every grouping variable added by this call.

- ...:

  Additional named arguments forwarded, unchanged, to `style` when it's
  called at build time (identically for every grouping variable added by
  this call) – see
  [`er_style()`](https://erplots.djnavarro.net/reference/er_style.md)'s
  "Passing extra arguments to a builder" section. Must be named.

## Value

The input `object`, with a group panel added.

## Details

Unlike the other four layers, the groups layer is **additive**: each
call adds another panel alongside any already added by a previous call,
rather than replacing it.

[`er_style_group_violin()`](https://erplots.djnavarro.net/reference/er_style_group.md)
and
[`er_style_group_histogram()`](https://erplots.djnavarro.net/reference/er_style_group.md)
are the other built-in `style` options; any function matching the
standard
`(data, config, stratify, exposure, response, strata, theme, ...)`
signature can be supplied instead. If `style` is tagged with a `layer`
(via
[`er_style_tag()`](https://erplots.djnavarro.net/reference/er_style_tag.md))
other than `"plot_group"`, this errors informatively; an untagged
builder is never checked.

`keep_strata = TRUE` errors if `group_by` is itself the plot's
stratification variable, since that would mean grouping and stratifying
by the same column at once; pass `keep_strata = FALSE` for that grouping
variable instead.

`bins`/`ties`/`quantile_type`/`labeller` are local to this call –
different grouping variables (including across separate
`er_plot_add_groups()` calls) aren't required to agree, and generally
shouldn't: they're usually different variables with no reason to share a
binning scheme. The one exception is grouping by the plot's own exposure
variable, which risks silently disagreeing with
[`er_plot_add_quantiles()`](https://erplots.djnavarro.net/reference/er_plot_add_quantiles.md)'s
own exposure-binning;
[`er_plot_build()`](https://erplots.djnavarro.net/reference/er_plot_build.md)
warns (doesn't error) if the two disagree in that specific case.

## Styles

|  |  |  |
|----|----|----|
| Label | Builder | Description |
| `"boxplot"` | [`er_style_group_boxplot()`](https://erplots.djnavarro.net/reference/er_style_group.md) | Boxplot per group level, group levels on the y-axis (the default). |
| `"violin"` | [`er_style_group_violin()`](https://erplots.djnavarro.net/reference/er_style_group.md) | Violin per group level, group levels on the y-axis. |
| `"histogram"` | [`er_style_group_histogram()`](https://erplots.djnavarro.net/reference/er_style_group.md) | Histogram per group level, group levels on facet strips, y-axis freed for counts. |
| `"linerange"` | [`er_style_group_linerange()`](https://erplots.djnavarro.net/reference/er_style_group.md) | Median dot with inner/outer-range lines per group level, group levels on the y-axis. |
| `"boxjitter"` | [`er_style_group_boxjitter()`](https://erplots.djnavarro.net/reference/er_style_group.md) | `"boxplot"` with jittered raw exposure values overlaid. |
| `"violinjitter"` | [`er_style_group_violinjitter()`](https://erplots.djnavarro.net/reference/er_style_group.md) | `"violin"` with jittered raw exposure values overlaid. |

## See also

[`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md),
[`er_plot_add_model()`](https://erplots.djnavarro.net/reference/er_plot_add_model.md),
[`er_plot_add_summary()`](https://erplots.djnavarro.net/reference/er_plot_add_summary.md),
[`er_plot_add_quantiles()`](https://erplots.djnavarro.net/reference/er_plot_add_quantiles.md),
[`er_plot_add_data()`](https://erplots.djnavarro.net/reference/er_plot_add_data.md),
[`er_style()`](https://erplots.djnavarro.net/reference/er_style.md)

## Examples

``` r
if (requireNamespace("erglm", quietly = TRUE)) {
library(erglm)
mod <- erglm_model(ae1 ~ aucss, erglm_data, family = binomial())
erglm_data |>
  er_plot(aucss, ae1) |>
  er_plot_add_model(mod) |>
  er_plot_add_groups(aucss) |>
  plot()

# additive: a second call adds a second panel rather than replacing the first
erglm_data |>
  er_plot(aucss, ae1) |>
  er_plot_add_model(mod) |>
  er_plot_add_groups(aucss) |>
  er_plot_add_groups(treatment) |>
  plot()
}


```
