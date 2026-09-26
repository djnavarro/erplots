# Package index

## Exposure-response plots

The compositional mini-grammar for designing exposure-response plots,
dividing plot structure into distinct layers for the data, the model,
the quantile summaries, textual summaries, and the exposure group plots.

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

## Time-to-event plots

The compositional mini-grammar for designing
Kaplan-Meier/survival-over-time plots, dividing plot structure distinct
layers for survival curves, censoring markers, risk tables, textual
summaries, and the survival model.

- [`er_tte()`](https://erplots.djnavarro.net/reference/er_tte.md) : The
  time-to-event plotting mini-language

- [`er_tte_add_curve()`](https://erplots.djnavarro.net/reference/er_tte_add_curve.md)
  : Add a Kaplan-Meier curve layer

- [`er_tte_add_censor()`](https://erplots.djnavarro.net/reference/er_tte_add_censor.md)
  : Add a censoring-marks layer

- [`er_tte_add_risktable()`](https://erplots.djnavarro.net/reference/er_tte_add_risktable.md)
  : Add a number-at-risk panel

- [`er_tte_add_summary()`](https://erplots.djnavarro.net/reference/er_tte_add_summary.md)
  : Add a summary annotation layer

- [`er_tte_add_model()`](https://erplots.djnavarro.net/reference/er_tte_add_model.md)
  : Add a parametric survival-curve overlay layer

- [`er_tte_theme()`](https://erplots.djnavarro.net/reference/er_tte_theme.md)
  :

  Adjust theme/labels for an `er_tte` object

- [`er_tte_build()`](https://erplots.djnavarro.net/reference/er_tte_build.md)
  :

  Build and render an `er_tte` object

## Visual predictive check plots

The compositional mini-grammar for desigining visual predictive check
plots, dividing plot structure into distinct layers for the observed
data and the simulated data.

- [`er_vpc()`](https://erplots.djnavarro.net/reference/er_vpc.md) : The
  exposure-response VPC mini-language

- [`er_vpc_add_observed()`](https://erplots.djnavarro.net/reference/er_vpc_add_observed.md)
  :

  Add the observed-data layer to an `er_vpc` VPC

- [`er_vpc_add_simulated()`](https://erplots.djnavarro.net/reference/er_vpc_add_simulated.md)
  :

  Add the simulated-data layer to an `er_vpc` VPC

- [`er_vpc_theme()`](https://erplots.djnavarro.net/reference/er_vpc_theme.md)
  :

  Adjust theme/labels for an `er_vpc` object

- [`er_vpc_build()`](https://erplots.djnavarro.net/reference/er_vpc_build.md)
  :

  Build and render an `er_vpc` object

## Builder function metadata

Tag a new builder function with the required metadata

- [`er_style_tag()`](https://erplots.djnavarro.net/reference/er_style_tag.md)
  : Tag a builder with structural/aesthetic metadata

## Builder functions for exposure-response plots

Low level functions to draw specific components of an exposure-response
plot. Each function supports one option for the `style` argument to the
corresponding layer in the exposure-response plot.

- [`er_style`](https://erplots.djnavarro.net/reference/er_style.md) :
  Builder functions for exposure-response plots
- [`er_style_model_ribbonline()`](https://erplots.djnavarro.net/reference/er_style_model.md)
  [`er_style_model_line()`](https://erplots.djnavarro.net/reference/er_style_model.md)
  [`er_style_model_spaghetti()`](https://erplots.djnavarro.net/reference/er_style_model.md)
  : Model curve builders for exposure-response plots
- [`er_style_summary_pvalue()`](https://erplots.djnavarro.net/reference/er_style_summary.md)
  [`er_style_summary_n()`](https://erplots.djnavarro.net/reference/er_style_summary.md)
  [`er_style_summary_coefficients()`](https://erplots.djnavarro.net/reference/er_style_summary.md)
  [`er_style_summary_gof()`](https://erplots.djnavarro.net/reference/er_style_summary.md)
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
  [`er_style_group_linerange()`](https://erplots.djnavarro.net/reference/er_style_group.md)
  [`er_style_group_boxjitter()`](https://erplots.djnavarro.net/reference/er_style_group.md)
  [`er_style_group_violinjitter()`](https://erplots.djnavarro.net/reference/er_style_group.md)
  : Group panel builders for exposure-response plots

## Builder functions for time-to-event plots

Low level functions to draw specific components of a time-to-event plot.
Each function supports one option for the `style` argument to the
corresponding layer in the time-to-event plot.

- [`er_style_tte_curve_km()`](https://erplots.djnavarro.net/reference/er_style_tte_curve.md)
  : Kaplan-Meier curve builders for the TTE grammar
- [`er_style_tte_censor_ticks()`](https://erplots.djnavarro.net/reference/er_style_tte_censor.md)
  : Censoring-mark builders for the TTE grammar
- [`er_style_tte_risktable_text()`](https://erplots.djnavarro.net/reference/er_style_tte_risktable.md)
  : Number-at-risk builders for the TTE grammar
- [`er_style_tte_summary_logrank()`](https://erplots.djnavarro.net/reference/er_style_tte_summary.md)
  [`er_style_tte_summary_n()`](https://erplots.djnavarro.net/reference/er_style_tte_summary.md)
  [`er_style_tte_summary_coefficients()`](https://erplots.djnavarro.net/reference/er_style_tte_summary.md)
  [`er_style_tte_summary_gof()`](https://erplots.djnavarro.net/reference/er_style_tte_summary.md)
  : Summary annotation builders for the TTE grammar
- [`er_style_tte_model_line()`](https://erplots.djnavarro.net/reference/er_style_tte_model.md)
  : Model-curve builders for the TTE grammar

## Builder functions for visual predictive check plots

Low level functions to draw specific components of a VPC plot. Each
function supports one option for the `style` argument to the
corresponding layer in the VPC plot.

- [`er_style_vpc_observed_quantile_line()`](https://erplots.djnavarro.net/reference/er_style_vpc_observed.md)
  [`er_style_vpc_observed_quantile_errorbar()`](https://erplots.djnavarro.net/reference/er_style_vpc_observed.md)
  [`er_style_vpc_observed_mean_errorbar()`](https://erplots.djnavarro.net/reference/er_style_vpc_observed.md)
  : Observed-layer builders for VPC plots
- [`er_style_vpc_simulated_quantile_ribbon()`](https://erplots.djnavarro.net/reference/er_style_vpc_simulated.md)
  [`er_style_vpc_simulated_quantile_errorbar()`](https://erplots.djnavarro.net/reference/er_style_vpc_simulated.md)
  [`er_style_vpc_simulated_mean_errorbar()`](https://erplots.djnavarro.net/reference/er_style_vpc_simulated.md)
  : Simulated-layer builders for VPC plots

## Confidence intervals

Helper functions to compute confidence intervals

- [`ci_clopper_pearson()`](https://erplots.djnavarro.net/reference/ci_clopper_pearson.md)
  : Clopper-Pearson confidence interval for binary data
- [`ci_poisson()`](https://erplots.djnavarro.net/reference/ci_poisson.md)
  : Exact Poisson confidence interval for a count rate
- [`ci_t()`](https://erplots.djnavarro.net/reference/ci_t.md) :
  t-interval confidence interval for the mean of continuous data
- [`ci_quantile()`](https://erplots.djnavarro.net/reference/ci_quantile.md)
  : Distribution-free confidence interval for a sample quantile

## Model interface

Generic functions that define the interface between models and plots

- [`er_predict()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
  [`er_simulate()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
  [`er_summary()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
  [`er_predict_survival()`](https://erplots.djnavarro.net/reference/er_model_interface.md)
  : Model interface for exposure-response plots

## Other

Other functions and objects

- [`cut_exposure_quantile()`](https://erplots.djnavarro.net/reference/cut_quantile.md)
  [`cut_quantile()`](https://erplots.djnavarro.net/reference/cut_quantile.md)
  : Cut a continuous variable into quantiles
- [`erplots_data`](https://erplots.djnavarro.net/reference/erplots_data.md)
  : Simulated exposure-response data
