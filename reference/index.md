# Package index

## Exposure-response plots

Build exposure-response plots from any model that implements
[`er_predict()`](https://erplots.djnavarro.net/reference/er_model_interface.md)

- [`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md) :
  The exposure-response plotting mini-language

- [`er_plot_add_model()`](https://erplots.djnavarro.net/reference/er_plot_add_model.md)
  : Add a fitted-model curve/ribbon layer

- [`er_plot_add_summary()`](https://erplots.djnavarro.net/reference/er_plot_add_summary.md)
  : Add a summary annotation layer

- [`er_plot_add_quantiles()`](https://erplots.djnavarro.net/reference/er_plot_add_quantiles.md)
  : Add a quantile-binned response summary layer

- [`er_plot_add_data()`](https://erplots.djnavarro.net/reference/er_plot_add_data.md)
  : Add a raw-data layer

- [`er_plot_add_groups()`](https://erplots.djnavarro.net/reference/er_plot_add_groups.md)
  : Add a grouped exposure-distribution panel

- [`er_plot_theme()`](https://erplots.djnavarro.net/reference/er_plot_theme.md)
  :

  Adjust theme/labels for an `er_plot` object

- [`er_plot_build()`](https://erplots.djnavarro.net/reference/er_plot_build.md)
  :

  Build and render an `er_plot` object

## Plot builder functions

Low level functions to draw specific components of an exposure-response
plot

- [`er_style`](https://erplots.djnavarro.net/reference/er_style.md) :
  Builder functions for exposure-response plots
- [`er_style_tag()`](https://erplots.djnavarro.net/reference/er_style_tag.md)
  : Tag a builder with structural/aesthetic metadata
- [`er_style_model_ribbonline()`](https://erplots.djnavarro.net/reference/er_style_model.md)
  [`er_style_model_line()`](https://erplots.djnavarro.net/reference/er_style_model.md)
  [`er_style_model_spaghetti()`](https://erplots.djnavarro.net/reference/er_style_model.md)
  : Model curve builders for exposure-response plots
- [`er_style_summary_pvalue()`](https://erplots.djnavarro.net/reference/er_style_summary.md)
  [`er_style_summary_n()`](https://erplots.djnavarro.net/reference/er_style_summary.md)
  : Summary annotation builders for exposure-response plots
- [`er_style_quantile_errorbar()`](https://erplots.djnavarro.net/reference/er_style_quantile.md)
  [`er_style_quantile_errorbar_vlines()`](https://erplots.djnavarro.net/reference/er_style_quantile.md)
  [`er_style_quantile_pointrange()`](https://erplots.djnavarro.net/reference/er_style_quantile.md)
  [`er_style_quantile_pointrange_vlines()`](https://erplots.djnavarro.net/reference/er_style_quantile.md)
  : Quantile summary builders for exposure-response plots
- [`er_style_data_boxjitter()`](https://erplots.djnavarro.net/reference/er_style_data.md)
  [`er_style_data_overlay()`](https://erplots.djnavarro.net/reference/er_style_data.md)
  [`er_style_data_hex()`](https://erplots.djnavarro.net/reference/er_style_data.md)
  : Data layer builders for exposure-response plots
- [`er_style_group_boxplot()`](https://erplots.djnavarro.net/reference/er_style_group.md)
  [`er_style_group_histogram()`](https://erplots.djnavarro.net/reference/er_style_group.md)
  [`er_style_group_violin()`](https://erplots.djnavarro.net/reference/er_style_group.md)
  : Group panel builders for exposure-response plots

## Model interface

The generics a model must (or may) implement to work with erplots

- [`er_predict()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
  [`er_simulate()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
  [`er_summary()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
  : Model interface for exposure-response plots

## Other

Other functions and objects

- [`er_vpc_plot()`](https://erplots.djnavarro.net/reference/er_vpc_plot.md)
  : Visual predictive check plot for an exposure-response model
- [`ci_clopper_pearson()`](https://erplots.djnavarro.net/reference/ci_clopper_pearson.md)
  : Clopper-Pearson confidence interval for binary data
- [`ci_poisson()`](https://erplots.djnavarro.net/reference/ci_poisson.md)
  : Exact Poisson confidence interval for a count rate
- [`ci_t()`](https://erplots.djnavarro.net/reference/ci_t.md) :
  t-interval confidence interval for the mean of continuous data
- [`cut_exposure_quantile()`](https://erplots.djnavarro.net/reference/cut_quantile.md)
  [`cut_quantile()`](https://erplots.djnavarro.net/reference/cut_quantile.md)
  : Cut a continuous variable into quantiles
