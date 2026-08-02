
#' Adjust theme/labels for an `er_plot` object
#'
#' Set axis/legend labels, plot titles/captions, axis limits, theme objects, discrete and continuous scale objects, formatters, legend key glyph, and relative panel heights. This does not change which variable is mapped to which aesthetic.
#'
#' @details
#' `dodge_width` is a stratification-layout setting used by
#' [er_style_quantile_errorbar()]/[er_style_quantile_pointrange()] (and
#' their `_vlines` variants) to separate strata horizontally within each
#' quantile bin. It belongs in `er_plot_theme()` because dodging is about
#' stratification layout, not an individual builder's visual style.
#' Defaults to `0.015` (set in [er_plot()]).
#'
#' Every argument defaults to `NULL`, meaning "leave whatever was set
#' before unchanged". This allows repeated calls to `er_plot_theme()` to
#' update only the supplied fields, like [ggplot2::theme()]. There is no
#' implicit way to reset a field to the `er_plot()` default.
#'
#' `color_discrete`/`fill_discrete` apply only when a layer's `colour`/
#' `fill` aesthetic is mapped to stratification. Their continuous
#' counterparts, `color_continuous`/`fill_continuous`, apply only when the
#' aesthetic is mapped to a continuous quantity such as density or a
#' continuous/count response value. If a custom builder adds its own scale,
#' supplying one of these four will add a second scale and let ggplot2
#' choose the later one.
#'
#' `theme_extra` defaults to a panel border plus `legend.position =
#' "bottom"`. Supplying a new value fully replaces this default rather
#' than merging with it, so re-include the border/legend-position
#' settings too if you want to keep them alongside your own additions.
#'
#' @param object Partially constructed plot (has S3 class `er_plot`)
#' @param xlab,ylab Exposure/response axis label (single string).
#' @param strata_lab Stratification legend label (single string). 
#'   Errors if `stratify_by` wasn't set in
#'   [er_plot()] -- there's no stratification legend to label.
#' @param title,subtitle,caption Plot-level annotation text (single
#'   strings), applied via `patchwork::plot_annotation()` in
#'   [er_plot_build()].
#' @param xlim,ylim Exposure/response axis limits (length-2, increasing
#'   numeric vectors, no `NA`). These are read lazily by every builder at
#'   build time, so it doesn't matter whether `er_plot_theme()` is called
#'   before or after the layers that use them. Unlike
#'   [ggplot2::coord_cartesian()]'s `xlim`/`ylim`, `NA` isn't accepted for
#'   either endpoint: `object$exposure$limits`/`object$response$limits`
#'   also drive non-cosmetic computations (e.g. the model curve's
#'   prediction grid, quantile-bin boundaries), where a `NA` bound has no
#'   well-defined meaning.
#' @param theme_base A ggplot2 theme object (e.g. [ggplot2::theme_minimal()])
#'   -- the swappable overall visual
#'   theme, defaulting to [ggplot2::theme_bw()].
#' @param theme_extra A ggplot2 theme object (e.g. from [ggplot2::theme()])
#'   with additional theme tweaks layered on top of `theme_base`. See
#'   "Details" for its default and replacement semantics.
#' @param color_discrete,fill_discrete A discrete ggplot2 scale object
#'   (e.g. [ggplot2::scale_color_brewer()], [ggplot2::scale_fill_viridis_d()]),
#'   applied to every plot whose `colour`/`fill` aesthetic is mapped to
#'   the stratification variable -- see "Details".
#' @param color_continuous,fill_continuous A continuous ggplot2 scale object
#'   (e.g. [ggplot2::scale_color_viridis_c()], [ggplot2::scale_fill_gradient()]),
#'   applied to every plot whose `colour`/`fill` aesthetic is mapped to
#'   something continuous other than the stratification variable -- see
#'   "Details".
#' @param format_p,format_percent,format_number Formatter functions
#'   (typically from `scales::label_*()`). Used by the summary/quantile layers to
#'   format p-values/rates/means for display.
#' @param draw_key A key-glyph function (e.g. [ggplot2::draw_key_point()]),
#'   passed as every geom's `key_glyph` argument.
#' @param dodge_width Spacing between adjacent strata's horizontal offset
#'   in the quantile layer, as a fraction of the exposure range. A single
#'   positive number; see "Details".
#' @param height_base,height_data,height_group Relative panel heights
#'   (single positive numbers).
#'   Supplying only one leaves the other two unchanged.
#'
#' @returns The input `object`, with the requested theme fields updated.
#'
#' @seealso [er_plot()], [er_style()]
#'
#' @export
er_plot_theme <- function(object,
                            xlab = NULL, ylab = NULL, strata_lab = NULL,
                            title = NULL, subtitle = NULL, caption = NULL,
                            xlim = NULL, ylim = NULL,
                            theme_base = NULL, theme_extra = NULL,
                            color_discrete = NULL, fill_discrete = NULL,
                            color_continuous = NULL, fill_continuous = NULL,
                            format_p = NULL, format_percent = NULL, format_number = NULL,
                            draw_key = NULL, dodge_width = NULL,
                            height_base = NULL, height_data = NULL, height_group = NULL) {

  if (!inherits(object, "er_plot")) rlang::abort("`object` must be an er_plot object")

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
  .check_theme_class(color_discrete, "color_discrete", "Scale")
  .check_theme_class(fill_discrete, "fill_discrete", "Scale")
  .check_theme_class(color_continuous, "color_continuous", "ScaleContinuous")
  .check_theme_class(fill_continuous, "fill_continuous", "ScaleContinuous")
  .check_theme_function(format_p, "format_p")
  .check_theme_function(format_percent, "format_percent")
  .check_theme_function(format_number, "format_number")
  .check_theme_function(draw_key, "draw_key")
  .check_theme_number(dodge_width, "dodge_width")
  .check_theme_number(height_base, "height_base")
  .check_theme_number(height_data, "height_data")
  .check_theme_number(height_group, "height_group")

  if (!is.null(strata_lab) && is.null(object$strata$name)) {
    rlang::abort(c(
      "`strata_lab` was supplied, but no `stratify_by` was set in `er_plot()`.",
      "i" = "There is no stratification legend to label."
    ))
  }

  if (!is.null(xlab)) object$exposure$label <- xlab
  if (!is.null(ylab)) object$response$label <- ylab
  if (!is.null(strata_lab)) object$strata$label <- strata_lab

  if (!is.null(title)) object$theme$title <- title
  if (!is.null(subtitle)) object$theme$subtitle <- subtitle
  if (!is.null(caption)) object$theme$caption <- caption

  if (!is.null(xlim)) object$exposure$limits <- xlim
  if (!is.null(ylim)) object$response$limits <- ylim

  if (!is.null(theme_base)) object$theme$theme_base <- theme_base
  if (!is.null(theme_extra)) object$theme$theme_extra <- theme_extra

  if (!is.null(color_discrete)) object$theme$color_discrete <- color_discrete
  if (!is.null(fill_discrete)) object$theme$fill_discrete <- fill_discrete
  if (!is.null(color_continuous)) object$theme$color_continuous <- color_continuous
  if (!is.null(fill_continuous)) object$theme$fill_continuous <- fill_continuous

  if (!is.null(format_p)) object$theme$format_p <- format_p
  if (!is.null(format_percent)) object$theme$format_percent <- format_percent
  if (!is.null(format_number)) object$theme$format_number <- format_number

  if (!is.null(draw_key)) object$theme$draw_key <- draw_key
  if (!is.null(dodge_width)) object$theme$dodge_width <- dodge_width

  new_height <- list(base = height_base, data = height_data, group = height_group)
  new_height <- new_height[!purrr::map_lgl(new_height, is.null)]
  if (length(new_height) > 0) {
    object$theme$height <- utils::modifyList(object$theme$height, new_height)
  }

  return(object)
}

#' @noRd
.check_theme_string <- function(x, arg) {
  if (is.null(x)) return(invisible(NULL))
  if (!is.character(x) || length(x) != 1L) {
    rlang::abort(paste0("`", arg, "` must be a single string."))
  }
  invisible(NULL)
}

#' @noRd
.check_theme_limits <- function(x, arg) {
  if (is.null(x)) return(invisible(NULL))
  # Checked before the `length(x) != 2L` short-circuit even runs the
  # `x[2] > x[1]` comparison: unlike `ggplot2::coord_cartesian()`'s
  # `xlim`/`ylim`, `NA` isn't a supported "leave this bound alone" value
  # here (`object$exposure$limits`/`response$limits` also drive
  # non-cosmetic computations such as the model curve's prediction grid),
  # and `x[2] > x[1]` silently evaluates to `NA` for an `NA` endpoint,
  # which would otherwise crash the `if()` below with an opaque "missing
  # value where TRUE/FALSE needed" instead of erroring informatively.
  # `c(NA, NA)` is a logical vector (not numeric), so this check can't
  # require `is.numeric(x)` first the way the length/ordering check below
  # does -- only `length(x) == 2L` is required to catch it here.
  if (length(x) == 2L && anyNA(x)) {
    rlang::abort(paste0("`", arg, "` cannot contain `NA`."))
  }
  if (!is.numeric(x) || length(x) != 2L || !(x[2] > x[1])) {
    rlang::abort(paste0("`", arg, "` must be a length-2, increasing numeric vector."))
  }
  invisible(NULL)
}

#' @noRd
.check_theme_class <- function(x, arg, class) {
  if (is.null(x)) return(invisible(NULL))
  if (!inherits(x, class)) {
    rlang::abort(paste0("`", arg, "` must be an object of class \"", class, "\"."))
  }
  invisible(NULL)
}

#' @noRd
.check_theme_function <- function(x, arg) {
  if (is.null(x)) return(invisible(NULL))
  if (!is.function(x)) {
    rlang::abort(paste0("`", arg, "` must be a function."))
  }
  invisible(NULL)
}

#' @noRd
.check_theme_number <- function(x, arg) {
  if (is.null(x)) return(invisible(NULL))
  if (!is.numeric(x) || length(x) != 1L || x <= 0) {
    rlang::abort(paste0("`", arg, "` must be a single positive number."))
  }
  invisible(NULL)
}
