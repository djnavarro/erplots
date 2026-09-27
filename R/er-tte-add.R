# curve -----------------------------------------------------------------------

#' Add a Kaplan-Meier curve layer
#'
#' Adds the curve layer to a TTE plot: a Kaplan-Meier step curve with a 
#' confidence band, computed from the fit already contained within the plot 
#' object.
#'
#' @param object Partially constructed plot (has S3 class `er_tte`).
#' @param style Style used to draw the Kaplan-Meier curve and ribbon. Can 
#'   either be a string corresponding to one of the registered style labels
#'   (e.g., `"km"`, the default), or a builder function used to compute the
#'   relevant plot object (see "Styles" below). 
#' @param ... Additional named arguments forwarded to the `style` builder
#'   function when the plot is built.
#'
#' @returns The input `object`, with the curve layer added.
#'
#' @section Styles:
#' The following pre-defined styles are available for this layer. Please
#' see the documentation for the corresponding builder function to see what 
#' customisation options are available:
#' 
#' | Label | Builder | Description |
#' | --- | --- | --- |
#' | `"km"` | [er_style_tte_curve_km()] | Kaplan-Meier step curve with a confidence band (the only built-in, and the default). |
#'
#' See [er_style_tte()] for details on how style builder functions are 
#' defined for the TTE mini-grammar, should a custom style be required.
#' 
#' @examples
#' library(survival)
#' lung |>
#'   er_tte(time, status == 2) |>
#'   er_tte_add_curve() |>
#'   plot()
#'
#' lung |>
#'   transform(sex = factor(sex, labels = c("Male", "Female"))) |>
#'   er_tte(time, status == 2, stratify_by = sex) |>
#'   er_tte_add_curve() |>
#'   plot()
#'
#' @seealso [er_tte()], [er_style_tte_curve_km()]
#'
#' @export
er_tte_add_curve <- function(object, style = NULL, ...) {

  dots <- rlang::list2(...)
  .check_dots_named(dots)
  if (!inherits(object, "er_tte")) rlang::abort("`object` must be an er_tte object")
  if (!is.null(style) && !is.function(style) && !is.character(style)) {
    rlang::abort("`style` must be a function, a registered label string, or NULL")
  }
  if (is.character(style)) style <- .lookup_style_label("tte_curve", style, arg = "style")

  style <- style %||% er_style_tte_curve_km
  .check_style_layer(style, "tte_curve", arg = "style")

  object$layer$curve <- .layer_tte_curve(object = object, style = style, dots = dots)

  return(object)
}


# censor -----------------------------------------------------------------------

#' Add a censoring-marks layer
#'
#' Adds the censoring layer to a TTE plot, showing the times at which a 
#' a subject was censored, read from the fit already stored internally within 
#' the plot object.
#'
#' @param object Partially constructed plot (has S3 class `er_tte`).
#' @param style Style used to draw the censoring marks layer. Can 
#'   either be a string corresponding to one of the registered style labels
#'   (e.g., `"ticks"`, the default), or a builder function used to compute the
#'   relevant plot object (see "Styles" below). 
#' @param ... Additional named arguments forwarded to the `style` builder
#'   function when the plot is built.
#'
#' @returns The input `object`, with the censor layer added.
#'
#' @section Styles:
#' The following pre-defined styles are available for this layer. Please
#' see the documentation for the corresponding builder function to see what 
#' customisation options are available:
#' 
#' | Label | Builder | Description |
#' | --- | --- | --- |
#' | `"ticks"` | [er_style_tte_censor_ticks()] | Tick marks at each censoring time, on the curve's current step height (the only built-in, and the default). |
#'
#' See [er_style_tte()] for details on how style builder functions are 
#' defined for the TTE mini-grammar, should a custom style be required.
#' 
#' @examples
#' library(survival)
#' lung |>
#'   er_tte(time, status == 2) |>
#'   er_tte_add_curve() |>
#'   er_tte_add_censor() |>
#'   plot()
#'
#' @seealso [er_tte()], [er_style_tte_censor_ticks()]
#'
#' @export
er_tte_add_censor <- function(object, style = NULL, ...) {

  dots <- rlang::list2(...)
  .check_dots_named(dots)
  if (!inherits(object, "er_tte")) rlang::abort("`object` must be an er_tte object")
  if (!is.null(style) && !is.function(style) && !is.character(style)) {
    rlang::abort("`style` must be a function, a registered label string, or NULL")
  }
  if (is.character(style)) style <- .lookup_style_label("tte_censor", style, arg = "style")

  style <- style %||% er_style_tte_censor_ticks
  .check_style_layer(style, "tte_censor", arg = "style")

  object$layer$censor <- .layer_tte_censor(object = object, style = style, dots = dots)

  return(object)
}


# risktable -----------------------------------------------------------------

#' Add a number-at-risk panel
#'
#' Adds the at-risk table layer to a TTE plot: a separate panel stacked 
#' below the curve, showing the number of subjects still at risk at a 
#' grid of time points and computed from the fit already stored internally
#' within the plot object.
#'
#' @param object Partially constructed plot (has S3 class `er_tte`).
#' @param style Style used to generate the at-risk table in the plot. Can 
#'   either be a string corresponding to one of the registered style labels
#'   (e.g., `"text"`, the default), or a builder function used to compute the
#'   relevant plot object (see "Styles" below). 
#' @param times Numeric vector of time points at which to report the
#'   number at risk, or `NULL` (the default) to use `n_times` evenly
#'   spaced breaks across the time range.
#' @param n_times Number of evenly spaced breaks to use when `times` is
#'   `NULL`. Must be a single whole number of at least 2. Ignored when
#'   `times` is supplied. Defaults to `6`.
#' @param ... Additional named arguments forwarded to the `style` builder
#'   function when the plot is built.
#'
#' @returns The input `object`, with the risktable layer added.
#'
#' @details
#' The same time breaks used for the number-at-risk grid also become
#' the curve panel's x-axis tick marks, so the two panels'
#' [patchwork::wrap_plots()]-collected x-axis lines up exactly --
#' see [er_tte_build()].
#'
#' @section Styles:
#' The following pre-defined styles are available for this layer. Please
#' see the documentation for the corresponding builder function to see what 
#' customisation options are available:
#' 
#' | Label | Builder | Description |
#' | --- | --- | --- |
#' | `"text"` | [er_style_tte_risktable_text()] | Number-at-risk counts as a text grid, one row per stratum (the only built-in, and the default). |
#'
#' See [er_style_tte()] for details on how style builder functions are 
#' defined for the TTE mini-grammar, should a custom style be required.
#' 
#' @examples
#' library(survival)
#' lung |>
#'   er_tte(time, status == 2) |>
#'   er_tte_add_curve() |>
#'   er_tte_add_risktable() |>
#'   plot()
#'
#' @seealso [er_tte()], [er_style_tte_risktable_text()]
#'
#' @export
er_tte_add_risktable <- function(object, style = NULL, times = NULL, n_times = 6, ...) {

  dots <- rlang::list2(...)
  .check_dots_named(dots)
  if (!inherits(object, "er_tte")) rlang::abort("`object` must be an er_tte object")
  if (!is.null(style) && !is.function(style) && !is.character(style)) {
    rlang::abort("`style` must be a function, a registered label string, or NULL")
  }
  if (is.character(style)) style <- .lookup_style_label("tte_risktable", style, arg = "style")

  if (!is.null(times) && (!is.numeric(times) || length(times) < 1L || any(!is.finite(times)) || any(times < 0))) {
    rlang::abort("`times` must be a numeric vector of non-negative values, or NULL.")
  }
  if (!is.numeric(n_times) || length(n_times) != 1L || !is.finite(n_times) || n_times < 2 || n_times != round(n_times)) {
    rlang::abort("`n_times` must be a single whole number of at least 2.")
  }

  style <- style %||% er_style_tte_risktable_text
  .check_style_layer(style, "tte_risktable", arg = "style")

  object$layer$risktable <- .layer_tte_risktable(object = object, style = style, dots = dots, times = times, n_times = n_times)

  return(object)
}


# model ---------------------------------------------------------------------

#' Add a model-based survival curve overlay
#'
#' Adds the model layer to a TTE plot: a fitted survival curve with an
#' uncertainty band derived from the corresponding time-to-event model.
#'
#' @param object Partially constructed plot (has S3 class `er_tte`).
#' @param model A fitted time-to-event model. Must implement
#'   [er_predict_survival()].
#' @param keep_strata Logical; whether this layer should use stratification.
#'   Defaults to `TRUE` when a stratification variable has been specified, 
#'   and `FALSE` otherwise.
#' @param style Style used to draw the model-based survival curve. Can 
#'   either be a string corresponding to one of the registered style labels
#'   (e.g., `"line"`, the default), or a builder function used to compute the
#'   relevant plot object (see "Styles" below). 
#' @param conf_level Confidence level for the prediction band. Defaults
#'   to `0.95`.
#' @param time_grid Numeric vector of times at which to predict `S(t)`,
#'   or `NULL` (the default) to use 100 points evenly spaced across
#'   the time range.
#' @param predict_args A named list of additional arguments forwarded to
#'   [er_predict_survival()] when generating model-based predictions.
#' @param ... Additional named arguments forwarded to the `style` builder
#'   function when the plot is built.
#'
#' @details
#' The model layer of a TTE plot is used to display predictions generated
#' from an underlying survival model (e.g., parametric accelerated failure
#' time model, Cox proportional hazard model, etc). It uses the `model` 
#' object to create the predictions, using the [er_predict_survival()]
#' method for the relevant model class to do the work. The `model` object
#' is permitted to reference covariates other than the plot stratification
#' variable: see the details section to [er_plot_add_model()] for the 
#' specifics.
#' 
#' Note that erplots does not check that `model` was fit on the same 
#' time/event variables passed to the plot itself; it is left to the user
#' to ensure that the data set provided to the model is consistent with 
#' the data provided to the TTE plot.
#'
#' @returns The input `object`, with the model layer added.
#'
#' @section Styles:
#' The following pre-defined styles are available for this layer. Please
#' see the documentation for the corresponding builder function to see what 
#' customisation options are available:
#' 
#' | Label | Builder | Description |
#' | --- | --- | --- |
#' | `"line"` | [er_style_tte_model_line()] | Fitted `S(t)` curve with an uncertainty band (the only built-in, and the default). |
#'
#' See [er_style_tte()] for details on how style builder functions are 
#' defined for the TTE mini-grammar, should a custom style be required.
#'
#' @seealso [er_tte()], [er_style_tte_model_line()], [er_model_interface]
#'
#' @export
er_tte_add_model <- function(object, model, keep_strata = NULL, style = NULL,
                              conf_level = 0.95, time_grid = NULL,
                              predict_args = list(), ...) {

  dots <- rlang::list2(...)
  .check_dots_named(dots)
  .check_dots_named(predict_args, arg = "predict_args")
  if (!inherits(object, "er_tte")) rlang::abort("`object` must be an er_tte object")
  if (!is.null(style) && !is.function(style) && !is.character(style)) {
    rlang::abort("`style` must be a function, a registered label string, or NULL")
  }
  if (is.character(style)) style <- .lookup_style_label("tte_model", style, arg = "style")
  if (!is.null(time_grid) && (!is.numeric(time_grid) || length(time_grid) < 1L || any(!is.finite(time_grid)) || any(time_grid < 0))) {
    rlang::abort("`time_grid` must be a numeric vector of non-negative values, or NULL.")
  }
  if (is.null(keep_strata)) keep_strata <- !is.null(object$strata)

  style <- style %||% er_style_tte_model_line
  .check_style_layer(style, "tte_model", arg = "style")

  object$layer$model <- .layer_tte_model(
    object = object,
    model = model,
    stratify = keep_strata,
    conf_level = conf_level,
    time_grid = time_grid,
    predict_args = predict_args,
    style = style,
    dots = dots
  )

  return(object)
}


# summary ------------------------------------------------------------------

#' Add a summary annotation layer
#'
#' Adds the summary layer to a TTE plot: a corner-placed text/label annotation, 
#' summarising one or more aspects to the plot or the data.
#'
#' @param object Partially constructed plot (has S3 class `er_tte`).
#' @param model A fitted time-to-event model implementing [er_summary()],
#'   or `NULL` (the default). Independent of whatever model, if any, was
#'   passed to [er_tte_add_model()] -- only needed for builder styles
#'   (e.g. [er_style_tte_summary_coefficients()]/
#'   [er_style_tte_summary_gof()]) that produce model-based summaries;
#'   the default log-rank builder and [er_style_tte_summary_n()] both
#'   ignore it.
#' @param keep_strata Logical; whether this layer should use stratification.
#'   Defaults to `TRUE` when a stratification variable has been specified, 
#'   and `FALSE` otherwise.
#' @param style Style used to produce the summary layer annotation. Can 
#'   either be a string corresponding to one of the registered style labels
#'   (e.g., `"logrank"`, the default), or a builder function used to compute the
#'   relevant plot object (see "Styles" below). 
#' @param conf_level Confidence level forwarded to [er_summary()] (see
#'   `?er_model_interface`). Defaults to `0.95`. Ignored when `model` is
#'   `NULL`.
#' @param summary_args A named list of additional arguments forwarded to
#'   [er_summary()] when generating summaries.
#' @param ... Additional named arguments forwarded to the `style` builder
#'   function when the plot is built.
#'
#' @returns The input `object`, with the summary layer added.
#'
#' @details
#' The annotation is placed in whichever corner of the panel is
#' currently furthest from the plotted survival curve(s), computed the
#' same way [er_plot_add_summary()]'s corner-placed annotation avoids
#' the raw data -- see [er_style_tte_summary_logrank()].
#'
#' The default log-rank builder draws nothing on an unstratified object,
#' or one with only 1 stratum level present in the data, rather than
#' erroring -- a log-rank test needs at least 2 groups to compare. Other
#' builders (e.g. [er_style_tte_summary_n()]) work regardless of
#' stratification.
#'
#' @section Styles:
#' The following pre-defined styles are available for this layer. Please
#' see the documentation for the corresponding builder function to see what 
#' customisation options are available:
#' 
#' | Label | Builder | Description |
#' | --- | --- | --- |
#' | `"logrank"` | [er_style_tte_summary_logrank()] | Log-rank test p-value comparing survival across `stratify_by`'s levels (the default). |
#' | `"n"` | [er_style_tte_summary_n()] | Subject/event counts; model- and stratification-agnostic. |
#' | `"coefficients"` | [er_style_tte_summary_coefficients()] | One line per model parameter, from `model`'s [er_summary()] `coefficients` table. |
#' | `"gof"` | [er_style_tte_summary_gof()] | A goodness-of-fit annotation from `model`'s [er_summary()] `glance` table. |
#'
#' See [er_style_tte()] for details on how style builder functions are 
#' defined for the TTE mini-grammar, should a custom style be required.
#'
#' @examples
#' library(survival)
#' lung |>
#'   transform(sex = factor(sex, labels = c("Male", "Female"))) |>
#'   er_tte(time, status == 2, stratify_by = sex) |>
#'   er_tte_add_curve() |>
#'   er_tte_add_summary() |>
#'   plot()
#'
#' # a purely descriptive annotation, with no model or log-rank test at all
#' lung |>
#'   er_tte(time, status == 2) |>
#'   er_tte_add_curve() |>
#'   er_tte_add_summary(style = er_style_tte_summary_n) |>
#'   plot()
#'
#' @seealso [er_tte()], [er_style_tte_summary_logrank()]
#'
#' @export
er_tte_add_summary <- function(object, model = NULL, keep_strata = NULL, style = NULL,
                                conf_level = 0.95, summary_args = list(), ...) {

  dots <- rlang::list2(...)
  .check_dots_named(dots)
  .check_dots_named(summary_args, arg = "summary_args")
  if (!inherits(object, "er_tte")) rlang::abort("`object` must be an er_tte object")
  if (!is.null(style) && !is.function(style) && !is.character(style)) {
    rlang::abort("`style` must be a function, a registered label string, or NULL")
  }
  if (is.character(style)) style <- .lookup_style_label("tte_summary", style, arg = "style")
  if (is.null(keep_strata)) keep_strata <- !is.null(object$strata)

  style <- style %||% er_style_tte_summary_logrank
  .check_style_layer(style, "tte_summary", arg = "style")

  object$layer$summary <- .layer_tte_summary(
    object = object,
    model = model,
    stratify = keep_strata,
    conf_level = conf_level,
    summary_args = summary_args,
    style = style,
    dots = dots
  )

  return(object)
}
