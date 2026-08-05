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
#'   `times` is supplied.
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


# pvalue ------------------------------------------------------------------

#' Add a log-rank test annotation layer
#'
#' Adds the pvalue layer: a corner-placed annotation of the log-rank
#' test comparing survival across `stratify_by`'s levels
#' (`survival::survdiff()`). Singleton (a second call replaces the
#' previous one). Requires a stratified `er_tte` object -- a log-rank
#' test compares two or more groups, so this errors if `stratify_by`
#' wasn't set in [er_tte()].
#'
#' @param object Partially constructed plot (has S3 class `er_tte`,
#'   with `stratify_by` set -- see [er_tte()]).
#' @param style Function drawing the annotation. Defaults to
#'   [er_style_tte_pvalue_logrank()].
#' @param ... Additional named arguments forwarded unchanged to `style`
#'   at build time (e.g. [er_style_tte_pvalue_logrank()]'s `inset`/
#'   `label_size`/`label_colour`/`label_fill`).
#'
#' @returns The input `object`, with the pvalue layer added.
#'
#' @details
#' The annotation is placed in whichever corner of the panel is
#' currently furthest from the plotted survival curve(s), computed the
#' same way [er_plot_add_summary()]'s corner-placed annotation avoids
#' the raw data -- see [er_style_tte_pvalue_logrank()].
#'
#' @examples
#' library(survival)
#' lung |>
#'   transform(sex = factor(sex, labels = c("Male", "Female"))) |>
#'   er_tte(time, status == 2, stratify_by = sex) |>
#'   er_tte_add_curve() |>
#'   er_tte_add_pvalue() |>
#'   plot()
#'
#' @seealso [er_tte()], [er_style_tte_pvalue_logrank()]
#'
#' @export
er_tte_add_pvalue <- function(object, style = NULL, ...) {

  dots <- rlang::list2(...)
  .check_dots_named(dots)
  if (!inherits(object, "er_tte")) rlang::abort("`object` must be an er_tte object")
  if (!is.null(style) && !is.function(style)) rlang::abort("`style` must be a function or NULL")

  if (is.null(object$strata)) {
    rlang::abort(c(
      "`er_tte_add_pvalue()` requires a stratified `er_tte` object.",
      "i" = "Set `stratify_by` in `er_tte()` first -- a log-rank test compares two or more groups."
    ))
  }
  n_strata_present <- length(unique(stats::na.omit(object$data[[".er_tte_strata"]])))
  if (n_strata_present < 2) {
    rlang::abort(c(
      sprintf("`stratify_by` (`%s`) has only %d level present in the data.", object$strata$var, n_strata_present),
      "i" = "A log-rank test needs at least 2 groups to compare."
    ))
  }

  style <- style %||% er_style_tte_pvalue_logrank
  .check_style_layer(style, "pvalue", arg = "style")

  object$layer$pvalue <- .layer_tte_pvalue(object = object, style = style, dots = dots)

  return(object)
}
