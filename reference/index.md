# Package index

## Plot

Build exposure-response plots from any model that implements
[`er_predict()`](https://erplots.djnavarro.net/reference/er_model_interface.md)

- [`er_plot()`](https://erplots.djnavarro.net/reference/er_plot.md) :
  The exposure-response plotting mini-language

- [`er_plot_style()`](https://erplots.djnavarro.net/reference/er_plot_style.md)
  :

  Adjust style/labels for an `er_plot` object

- [`er_plot_show_model()`](https://erplots.djnavarro.net/reference/er_plot_show_model.md)
  : Add a fitted-model curve/ribbon layer

- [`er_plot_show_quantiles()`](https://erplots.djnavarro.net/reference/er_plot_show_quantiles.md)
  : Add a quantile-binned response summary layer

- [`er_plot_show_data()`](https://erplots.djnavarro.net/reference/er_plot_show_data.md)
  : Add a raw-data layer

- [`er_plot_show_groups()`](https://erplots.djnavarro.net/reference/er_plot_show_groups.md)
  : Add a grouped exposure-distribution panel

- [`er_plot_build()`](https://erplots.djnavarro.net/reference/er_plot_build.md)
  :

  Build and render an `er_plot` object

- [`build_data_jitter()`](https://erplots.djnavarro.net/reference/er_partial.md)
  [`build_data_overlay()`](https://erplots.djnavarro.net/reference/er_partial.md)
  [`build_data_color()`](https://erplots.djnavarro.net/reference/er_partial.md)
  [`build_group_boxplot()`](https://erplots.djnavarro.net/reference/er_partial.md)
  [`build_group_violin()`](https://erplots.djnavarro.net/reference/er_partial.md)
  [`build_model_ribbonline()`](https://erplots.djnavarro.net/reference/er_partial.md)
  [`build_model_spaghetti()`](https://erplots.djnavarro.net/reference/er_partial.md)
  [`build_quantile_errorbar()`](https://erplots.djnavarro.net/reference/er_partial.md)
  [`build_quantile_pointrange()`](https://erplots.djnavarro.net/reference/er_partial.md)
  [`build_summary_pvalue()`](https://erplots.djnavarro.net/reference/er_partial.md)
  : Partial builders for exposure-response plots

- [`er_layout()`](https://erplots.djnavarro.net/reference/er_layout.md)
  : Declare a data-layer builder's structural layout

- [`er_vpc_plot()`](https://erplots.djnavarro.net/reference/er_vpc_plot.md)
  : Visual predictive check plot for an exposure-response model

## Model interface

The generics a model must (or may) implement to work with erplots

- [`er_predict()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
  [`er_simulate()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
  [`er_summary()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
  : Model interface for exposure-response plots

## Other

Other functions and objects

- [`clopper_pearson()`](https://erplots.djnavarro.net/reference/clopper_pearson.md)
  : Clopper-Pearson confidence interval for binary data
- [`cut_exposure_quantile()`](https://erplots.djnavarro.net/reference/cut_quantile.md)
  [`cut_quantile()`](https://erplots.djnavarro.net/reference/cut_quantile.md)
  : Cut a continuous variable into quantiles
- [`poisson_interval()`](https://erplots.djnavarro.net/reference/poisson_interval.md)
  : Exact Poisson confidence interval for a count rate
- [`t_interval()`](https://erplots.djnavarro.net/reference/t_interval.md)
  : t-interval confidence interval for the mean of continuous data
