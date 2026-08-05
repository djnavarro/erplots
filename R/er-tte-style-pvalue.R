#' Log-rank test annotation builders for the TTE grammar
#'
#' Builder functions for the `pvalue` layer ([er_tte_add_pvalue()]),
#' drawing a corner-placed text/label annotation from a log-rank test
#' comparing survival across `stratify_by`'s levels.
#'
#' @include er-plot-style.R
#' @param data The original data frame (`object$data`).
#' @param config Configuration for the pvalue layer (see
#'   `.layer_tte_pvalue()`): `config$p_value` (the log-rank test's
#'   p-value) and `config$corner_distance` (how uncrowded each panel
#'   corner is, relative to the plotted survival curve(s) -- see
#'   [er_style()]'s `?er_plot_add_summary()`-analogous corner-placement
#'   idiom).
#' @param stratify Logical: always `TRUE` here, since
#'   [er_tte_add_pvalue()] requires a stratified `er_tte` object.
#' @param time `object$time` (`name`/`label`/`limits`).
#' @param strata `object$strata` (`var`/`label`/`type`/`n_strata`).
#' @param theme `object$theme` -- `theme$format_p` formats the p-value.
#' @param ... Additional named arguments forwarded from
#'   [er_tte_add_pvalue()]'s own `...`.
#' @param inset Distance from the panel edge for the annotation label,
#'   as a fraction of the panel's width/height. Default `0.05`.
#' @param label_size Label text size.
#' @param label_colour Label text colour.
#' @param label_fill Label background fill.
#'
#' @details
#' `er_style_tte_pvalue_logrank()` places its annotation in whichever of
#' the panel's 4 corners is currently furthest from the survival
#' curve(s), using the same `(0, 1)`-rescaled corner-distance
#' calculation [er_plot_add_summary()]'s own p-value annotation uses to
#' avoid a plot's raw data points -- here applied to the curve's own
#' `(time, surv)` coordinates instead, since there's no raw per-subject
#' scatter in this grammar for the annotation to avoid.
#'
#' `er_style_tte_pvalue_logrank()` is tagged `er_style_tag(fn, layer =
#' "pvalue")`, so [er_tte_add_pvalue()] errors informatively if handed a
#' builder tagged for a different layer.
#'
#' @returns A geom, or a list of geoms.
#'
#' @examples
#' library(survival)
#' lung |>
#'   transform(sex = factor(sex, labels = c("Male", "Female"))) |>
#'   er_tte(time, status == 2, stratify_by = sex) |>
#'   er_tte_add_curve() |>
#'   er_tte_add_pvalue(style = er_style_tte_pvalue_logrank, label_fill = "white") |>
#'   plot()
#'
#' @name er_style_tte_pvalue
#' @seealso [er_tte_add_pvalue()]
NULL

#' @rdname er_style_tte_pvalue
#' @export
er_style_tte_pvalue_logrank <- function(data, config, stratify, time, strata, theme, ...,
                                         inset = 0.05, label_size = NULL, label_colour = NULL, label_fill = NULL) {

  if (is.null(config$p_value)) return(list())

  corner <- names(sort(config$corner_distance)[4])
  summary_data <- tibble::tibble(lbl = paste0("Log-rank test: ", theme$format_p(config$p_value)))

  x_left  <- inset
  x_right <- 1 - inset
  y_top   <- 1 - inset
  y_bot   <- inset

  if (corner == "top_left") {
    geoms <- .summary_label_geom(summary_data, x_left, y_top, 0, 1,
                                 label_size = label_size, label_colour = label_colour, label_fill = label_fill)
  }

  if (corner == "top_right") {
    geoms <- .summary_label_geom(summary_data, x_right, y_top, 1, 1,
                                 label_size = label_size, label_colour = label_colour, label_fill = label_fill)
  }

  if (corner == "bottom_left") {
    geoms <- .summary_label_geom(summary_data, x_left, y_bot, 0, 0,
                                 label_size = label_size, label_colour = label_colour, label_fill = label_fill)
  }

  if (corner == "bottom_right") {
    geoms <- .summary_label_geom(summary_data, x_right, y_bot, 1, 0,
                                 label_size = label_size, label_colour = label_colour, label_fill = label_fill)
  }

  return(geoms)
}
er_style_tte_pvalue_logrank <- er_style_tag(er_style_tte_pvalue_logrank, layer = "pvalue")
