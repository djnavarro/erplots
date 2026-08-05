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
