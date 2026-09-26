# curve -----------------------------------------------------------------------

#' Add a Kaplan-Meier curve layer
#'
#' Adds the curve layer: a Kaplan-Meier step curve with a confidence
#' band, computed from the fit already stored on `object$km` (see
#' [er_tte()]) -- no recomputation happens here. Singleton (a second
#' call replaces the previous one).
#'
#' @param object Partially constructed plot (has S3 class `er_tte`).
#' @param style Function drawing the KM curve/ribbon. Defaults to
#'   [er_style_tte_curve_km()].
#' @param ... Additional named arguments forwarded unchanged to `style`
#'   at build time (e.g. [er_style_tte_curve_km()]'s `show_ci`/
#'   `ribbon_alpha`/`linewidth`).
#'
#' @returns The input `object`, with the curve layer added.
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
  if (!is.null(style) && !is.function(style)) rlang::abort("`style` must be a function or NULL")

  style <- style %||% er_style_tte_curve_km
  .check_style_layer(style, "curve", arg = "style")

  object$layer$curve <- .layer_tte_curve(object = object, style = style, dots = dots)

  return(object)
}


# censor -----------------------------------------------------------------------

#' Add a censoring-marks layer
#'
#' Adds the censor layer: a tick mark at every time a subject was
#' censored, read from the fit already stored on `object$km` (see
#' [er_tte()]) -- no recomputation happens here. Singleton (a second
#' call replaces the previous one).
#'
#' @param object Partially constructed plot (has S3 class `er_tte`).
#' @param style Function drawing the censoring marks. Defaults to
#'   [er_style_tte_censor_ticks()].
#' @param ... Additional named arguments forwarded unchanged to `style`
#'   at build time (e.g. [er_style_tte_censor_ticks()]'s `shape`/
#'   `size`/`stroke`).
#'
#' @returns The input `object`, with the censor layer added.
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
  if (!is.null(style) && !is.function(style)) rlang::abort("`style` must be a function or NULL")

  style <- style %||% er_style_tte_censor_ticks
  .check_style_layer(style, "censor", arg = "style")

  object$layer$censor <- .layer_tte_censor(object = object, style = style, dots = dots)

  return(object)
}


# risktable -----------------------------------------------------------------

#' Add a number-at-risk panel
#'
#' Adds the risktable layer: a patchwork panel stacked below the curve,
#' showing the number of subjects still at risk at a grid of time
#' points (one row per stratum, when stratified) -- read from the fit
#' already stored on `object$km` (see [er_tte()]) via
#' `summary.survfit(..., extend = TRUE)`. Singleton (a second call
#' replaces the previous one).
#'
#' @param object Partially constructed plot (has S3 class `er_tte`).
#' @param style Function drawing the risk-count labels. Defaults to
#'   [er_style_tte_risktable_text()].
#' @param times Numeric vector of time points at which to report the
#'   number at risk, or `NULL` (the default) to use `n_times` evenly
#'   spaced breaks spanning `object$time$limits`.
#' @param n_times Number of evenly spaced breaks to use when `times` is
#'   `NULL`. Must be a single whole number of at least 2. Ignored when
#'   `times` is supplied. Defaults to `6`.
#' @param ... Additional named arguments forwarded unchanged to `style`
#'   at build time (e.g. [er_style_tte_risktable_text()]'s `text_size`).
#'
#' @returns The input `object`, with the risktable layer added.
#'
#' @details
#' The same time breaks used for the number-at-risk grid also become
#' the curve panel's x-axis tick marks, so the two panels'
#' [patchwork::wrap_plots()]-collected x-axis lines up exactly --
#' see [er_tte_build()].
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
  if (!is.null(style) && !is.function(style)) rlang::abort("`style` must be a function or NULL")

  if (!is.null(times) && (!is.numeric(times) || length(times) < 1L || any(!is.finite(times)) || any(times < 0))) {
    rlang::abort("`times` must be a numeric vector of non-negative values, or NULL.")
  }
  if (!is.numeric(n_times) || length(n_times) != 1L || !is.finite(n_times) || n_times < 2 || n_times != round(n_times)) {
    rlang::abort("`n_times` must be a single whole number of at least 2.")
  }

  style <- style %||% er_style_tte_risktable_text
  .check_style_layer(style, "risktable", arg = "style")

  object$layer$risktable <- .layer_tte_risktable(object = object, style = style, dots = dots, times = times, n_times = n_times)

  return(object)
}


# model ---------------------------------------------------------------------

#' Add a parametric survival-curve overlay layer
#'
#' Adds the model layer: a fitted parametric `S(t)` curve (with an
#' uncertainty band) from a time-to-event model, overlaid on the
#' Kaplan-Meier curve already stored on `object$km` (see [er_tte()]).
#' Singleton (a second call replaces the previous one).
#'
#' @param object Partially constructed plot (has S3 class `er_tte`).
#' @param model A fitted time-to-event model. Must implement
#'   [er_predict_survival()] (see [er_model_interface]).
#' @param keep_strata Logical; whether this layer should draw one curve
#'   per stratum level. Defaults to `!is.null(object$strata)`.
#' @param style Function drawing the model curve/ribbon. Defaults to
#'   [er_style_tte_model_line()].
#' @param conf_level Confidence level for the prediction band. Defaults
#'   to `0.95`.
#' @param time_grid Numeric vector of times at which to predict `S(t)`,
#'   or `NULL` (the default) to use 100 points evenly spaced across
#'   `object$time$limits`.
#' @param predict_args A named list of additional arguments forwarded to
#'   [er_predict_survival()] (e.g. a model-specific argument its method
#'   requires beyond `model`/`newdata`/`time_grid`/`conf_level`).
#'   Distinct from `...`: `predict_args` reaches [er_predict_survival()],
#'   `...` reaches `style` -- mirroring [er_plot_add_model()]'s
#'   `predict_args`.
#' @param ... Additional named arguments forwarded unchanged to `style`
#'   at build time.
#'
#' @details
#' `model` may reference covariates beyond the strata variable; erplots
#' fills any additional covariate from the plot data with a reference
#' value (first factor level or numeric mean), exactly as
#' [er_plot_add_model()] does -- see its "Details". Strata membership is
#' carried on the `newdata` passed to [er_predict_survival()], never
#' implicit in `model` itself -- see [er_model_interface]'s "Details".
#'
#' erplots does not check that `model` was fit on the same time/event
#' variables as the plot; the caller must ensure compatibility.
#'
#' @returns The input `object`, with the model layer added.
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
  if (!is.null(style) && !is.function(style)) rlang::abort("`style` must be a function or NULL")
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
#' Adds the summary layer: a corner-placed text/label annotation, drawn
#' from a log-rank test comparing survival across `stratify_by`'s levels
#' (the default style, `survival::survdiff()`), a supplied model's
#' [er_summary()] result, or purely descriptive observation/event counts
#' -- depending on `style`. Singleton (a second call replaces the
#' previous one).
#'
#' @param object Partially constructed plot (has S3 class `er_tte`).
#' @param model A fitted time-to-event model implementing [er_summary()],
#'   or `NULL` (the default). Independent of whatever model, if any, was
#'   passed to [er_tte_add_model()] -- only needed for builder styles
#'   (e.g. [er_style_tte_summary_coefficients()]/
#'   [er_style_tte_summary_gof()]) that produce model-based summaries;
#'   the default log-rank builder and [er_style_tte_summary_n()] both
#'   ignore it.
#' @param keep_strata Logical, indicating whether this layer should be
#'   split by the plot's stratification variable; defaults to `TRUE` if
#'   `stratify_by` was set in [er_tte()], `FALSE` otherwise.
#' @param style Function drawing the annotation. Defaults to
#'   [er_style_tte_summary_logrank()].
#' @param conf_level Confidence level forwarded to [er_summary()] (see
#'   `?er_model_interface`). Defaults to `0.95`. Ignored when `model` is
#'   `NULL`.
#' @param summary_args A named list of additional arguments forwarded to
#'   [er_summary()], distinct from `...` the same way
#'   [er_tte_add_model()]'s `predict_args` is distinct from its own
#'   `...` -- see its "Details".
#' @param ... Additional named arguments forwarded unchanged to `style`
#'   at build time (e.g. [er_style_tte_summary_logrank()]'s `inset`/
#'   `label_size`/`label_colour`/`label_fill`).
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
  if (!is.null(style) && !is.function(style)) rlang::abort("`style` must be a function or NULL")
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
