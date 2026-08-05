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
