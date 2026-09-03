
#' Adjust theme/labels for an `er_tte` object
#'
#' Set axis/legend labels, plot titles/captions, axis limits, theme
#' objects, formatters, the legend key glyph, and relative panel heights
#' for a time-to-event plot. This does not change which variable is
#' mapped to which aesthetic -- that's the builder's job via `style`
#' (see [er_style_tte_curve]).
#'
#' @details
#' Every argument defaults to `NULL`, meaning "leave whatever was set
#' before unchanged". This allows repeated calls to `er_tte_theme()` to
#' update only the supplied fields, like [ggplot2::theme()]. There is no
#' implicit way to reset a field to the [er_tte()] default.
#'
#' `xlim` overwrites `object$time$limits` directly (the same structural
#' field [er_tte()] itself sets from the data), rather than a purely
#' cosmetic `ggplot2::coord_cartesian()` zoom -- mirroring
#' [er_plot_theme()]'s own `xlim` (not [er_vpc_theme()]'s, which is
#' display-only). This matters because `object$time$limits` also drives
#' non-cosmetic defaults computed at *add-layer* time: [er_tte_add_model()]'s
#' default `time_grid` and [er_tte_add_risktable()]'s default `times`
#' both span it. Call `er_tte_theme(xlim = ...)` *before* those layers
#' when you want the narrower/wider range reflected in their defaults;
#' calling it after only changes the curve panel's own x-axis display.
#' `ylim`, by contrast, is purely cosmetic (survival probability is
#' always modelled on `[0, 1]`; this only changes what's displayed),
#' stored on `object$theme$ylim` and defaulting to `c(0, 1)`.
#'
#' `theme_extra` defaults to a panel border plus `legend.position =
#' "bottom"`. Supplying a new value fully replaces this default rather
#' than merging with it, so re-include the border/legend-position
#' settings too if you want to keep them alongside your own additions.
#'
#' `title`/`subtitle`/`caption` are applied via a single
#' `ggplot2::labs()` call on the curve panel -- unlike [er_plot_theme()]'s
#' `patchwork::plot_annotation()` indirection, this is enough even when
#' [er_tte_add_risktable()]'s panel is stacked below it via
#' `patchwork::wrap_plots()`, since the curve panel is always the
#' top-most one.
#'
#' @param object Partially constructed plot (has S3 class `er_tte`).
#' @param xlab Time axis label (single string). See "Details" for why
#'   `xlim` (not this) drives layout decisions; `xlab` is purely
#'   cosmetic.
#' @param ylab Survival-probability axis label (single string).
#' @param strata_lab Stratification legend label (single string).
#'   Errors if `stratify_by` wasn't set in [er_tte()] -- there's no
#'   stratification legend to label.
#' @param title,subtitle,caption Plot-level annotation text (single
#'   strings).
#' @param xlim Time-axis limits (length-2, increasing numeric vector, no
#'   `NA`) -- overwrites `object$time$limits`. See "Details" for the
#'   call-order caveat.
#' @param ylim Survival-probability axis limits (length-2, increasing
#'   numeric vector, no `NA`). Purely cosmetic; defaults to `c(0, 1)`.
#' @param theme_base A ggplot2 theme object (e.g. [ggplot2::theme_minimal()])
#'   -- the swappable overall visual theme, defaulting to
#'   [ggplot2::theme_bw()].
#' @param theme_extra A ggplot2 theme object (e.g. from [ggplot2::theme()])
#'   with additional theme tweaks layered on top of `theme_base`. See
#'   "Details" for its default and replacement semantics.
#' @param format_p Formatter function (typically from `scales::label_pvalue()`),
#'   used by [er_tte_add_pvalue()]'s annotation.
#' @param format_percent Formatter function (typically from
#'   `scales::label_percent()`), reserved for a future TTE builder that
#'   formats a survival probability/risk-table count as a percentage.
#' @param draw_key A key-glyph function (e.g. [ggplot2::draw_key_point()]),
#'   passed as the curve/model layers' `key_glyph` argument.
#' @param height_curve,height_risktable Relative panel heights (single
#'   positive numbers), used when [er_tte_add_risktable()]'s panel is
#'   stacked below the curve panel. Supplying only one leaves the other
#'   unchanged.
#'
#' @returns The input `object`, with the requested theme fields updated.
#'
#' @examples
#' library(survival)
#' lung |>
#'   er_tte(time, status == 2) |>
#'   er_tte_add_curve() |>
#'   er_tte_theme(
#'     xlab = "Days", ylab = "Survival probability",
#'     title = "Overall survival"
#'   ) |>
#'   plot()
#'
#' @seealso [er_tte()], [er_style_tte_curve]
#'
#' @export
er_tte_theme <- function(object,
                          xlab = NULL, ylab = NULL, strata_lab = NULL,
                          title = NULL, subtitle = NULL, caption = NULL,
                          xlim = NULL, ylim = NULL,
                          theme_base = NULL, theme_extra = NULL,
                          format_p = NULL, format_percent = NULL,
                          draw_key = NULL,
                          height_curve = NULL, height_risktable = NULL) {

  if (!inherits(object, "er_tte")) rlang::abort("`object` must be an er_tte object")

  .check_theme_string(xlab, "xlab")
  .check_theme_string(ylab, "ylab")
  .check_theme_string(strata_lab, "strata_lab")
  .check_theme_string(title, "title")
  .check_theme_string(subtitle, "subtitle")
  .check_theme_string(caption, "caption")
  .check_theme_limits(xlim, "xlim")
  .check_theme_limits(ylim, "ylim")
  .check_theme_class(theme_base, "theme_base", "theme")
  .check_theme_class(theme_extra, "theme_extra", "theme")
  .check_theme_function(format_p, "format_p")
  .check_theme_function(format_percent, "format_percent")
  .check_theme_function(draw_key, "draw_key")
  .check_theme_number(height_curve, "height_curve")
  .check_theme_number(height_risktable, "height_risktable")

  if (!is.null(strata_lab) && is.null(object$strata)) {
    rlang::abort(c(
      "`strata_lab` was supplied, but no `stratify_by` was set in `er_tte()`.",
      "i" = "There is no stratification legend to label."
    ))
  }

  if (!is.null(xlab)) object$theme$xlab <- xlab
  if (!is.null(ylab)) object$theme$ylab <- ylab
  if (!is.null(strata_lab)) object$strata$label <- strata_lab

  if (!is.null(title)) object$theme$title <- title
  if (!is.null(subtitle)) object$theme$subtitle <- subtitle
  if (!is.null(caption)) object$theme$caption <- caption

  # `xlim` is structural (see "Details"): it overwrites `object$time$limits`
  # directly, the same field `er_tte_add_model()`/`er_tte_add_risktable()`
  # read their own defaults from -- unlike `ylim`, which is purely
  # cosmetic and lives on `object$theme$ylim` instead.
  if (!is.null(xlim)) object$time$limits <- xlim
  if (!is.null(ylim)) object$theme$ylim <- ylim

  if (!is.null(theme_base)) object$theme$theme_base <- theme_base
  if (!is.null(theme_extra)) object$theme$theme_extra <- theme_extra

  if (!is.null(format_p)) object$theme$format_p <- format_p
  if (!is.null(format_percent)) object$theme$format_percent <- format_percent

  if (!is.null(draw_key)) object$theme$draw_key <- draw_key

  new_height <- list(curve = height_curve, risktable = height_risktable)
  new_height <- new_height[!purrr::map_lgl(new_height, is.null)]
  if (length(new_height) > 0) {
    object$theme$height <- utils::modifyList(object$theme$height, new_height)
  }

  return(object)
}
