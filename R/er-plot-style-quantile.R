#' Quantile summary builders for exposure-response plots
#'
#' Builder functions for the `quantile` layer ([er_plot_add_quantiles()]),
#' drawing a point/interval summary per exposure quantile bin as an error bar
#' or a pointrange, optionally with bin-boundary vlines.
#'
#' @include er-plot-style.R
#' @param data The original data frame.
#' @param config Configuration for the specific plot.
#' @param stratify Logical: whether to stratify.
#' @param exposure Exposure variable.
#' @param response Response variable.
#' @param strata Stratification variable.
#' @param theme Theme components.
#' @param point_size Point size for `er_style_quantile_errorbar()`.
#' @param errorbar_width Width of `er_style_quantile_errorbar()`'s error bars.
#' @param label_size Text size for the per-bin value label.
#' @param pointrange_size,pointrange_linewidth Size and linewidth for `ggplot2::geom_pointrange()`.
#' @param vline_colour,vline_linetype Colour and linetype of interior quantile boundary lines.
#' @param vline_labels Logical: whether the `_vlines` builders also label each interior boundary with its exposure value.
#' @param vline_label_position One of `"auto"`, `"top"`, `"bottom"` -- vertical placement of `vline_labels`.
#' @param vline_label_size,vline_label_colour,vline_label_fill Size, text colour, and background fill for `vline_labels`.
#' @param vline_label_inset Fraction of the response range `vline_labels` are inset from the panel edge.
#' @param ... Additional named arguments forwarded from [er_plot_add_quantiles()]'s own `...`.
#'
#' @details Builders for the `quantile` layer ([er_plot_add_quantiles()])
#' bin exposure into quantile groups and plot a response summary with an
#' uncertainty interval. `er_style_quantile_errorbar()` and
#' `er_style_quantile_pointrange()` are the base builders; their
#' `_vlines` variants add interior quantile-bin boundary lines. All
#' built-in quantile builders are tagged `er_style_tag(fn, layer =
#' "quantile")`, so [er_plot_add_quantiles()] errors informatively if
#' handed a builder tagged for a different layer.
#'
#' The `_vlines` variants can also label each interior boundary with its
#' exposure value (`vline_labels = TRUE`, off by default). Labels are
#' drawn with [ggplot2::geom_label()] (an opaque background, since a
#' label sits directly on a vline spanning the full panel height) along
#' either the top or bottom edge of the panel. `vline_label_position =
#' "auto"` (the default) picks whichever vertical half doesn't contain
#' the corner a summary annotation ([er_plot_add_summary()]) would place
#' itself in -- based on the same raw-data corner-crowdedness
#' calculation the summary layer itself uses -- so the two don't
#' collide; this works whether or not a summary layer is actually
#' present, since both layers compute the same deterministic quantity
#' independently. Override with `"top"`/`"bottom"` to place labels
#' manually instead.
#'
#' When stratified, all four builders horizontally dodge each quantile
#' bin's points/bars/labels apart by [er_plot_theme()]'s `dodge_width`
#' (a fraction of the exposure range, default `0.05`) -- a cross-layer,
#' stratification-wide setting controlled via `er_plot_theme()` rather
#' than a per-builder argument here, since it's about how stratification
#' lays out a dodged layer, not one builder's own visual style.
#'
#' See [er_style()] for the shared builder interface these functions
#' implement, including how to write a custom builder of your own.
#'
#' @returns A geom, or a list of geoms; see [er_style()].
#'
#' @examples
#' if (requireNamespace("erglm", quietly = TRUE)) {
#'   library(erglm)
#'   mod <- erglm_model(ae1 ~ aucss, erglm_data, family = binomial())
#'
#'   # er_style_quantile_errorbar(): point + error bar, the default
#'   erglm_data |>
#'     er_plot(aucss, ae1) |>
#'     er_plot_add_model(mod) |>
#'     er_plot_add_quantiles(style = er_style_quantile_errorbar) |>
#'     plot()
#'
#'   # er_style_quantile_pointrange(): a pointrange instead
#'   erglm_data |>
#'     er_plot(aucss, ae1) |>
#'     er_plot_add_model(mod) |>
#'     er_plot_add_quantiles(style = er_style_quantile_pointrange) |>
#'     plot()
#'
#'   # er_style_quantile_errorbar_vlines(): the default, plus dotted
#'   # lines marking the interior quantile-bin boundaries
#'   erglm_data |>
#'     er_plot(aucss, ae1) |>
#'     er_plot_add_model(mod) |>
#'     er_plot_add_quantiles(style = er_style_quantile_errorbar_vlines) |>
#'     plot()
#'
#'   # Customize the quantile builder's appearance.
#'   erglm_data |>
#'     er_plot(aucss, ae1) |>
#'     er_plot_add_model(mod) |>
#'     er_plot_add_quantiles(
#'       style = er_style_quantile_errorbar,
#'       point_size = 4,
#'       errorbar_width = 0.08,
#'       label_size = 4
#'     ) |>
#'     plot()
#'
#'   erglm_data |>
#'     er_plot(aucss, ae1) |>
#'     er_plot_add_model(mod) |>
#'     er_plot_add_quantiles(
#'       style = er_style_quantile_pointrange,
#'       label_size = 4,
#'       pointrange_size = 2,
#'       pointrange_linewidth = 1.2
#'     ) |>
#'     plot()
#'
#'   # widening the stratum-dodge spacing via er_plot_theme()
#'   mod2 <- erglm_model(ae1 ~ aucss + sex, erglm_data, family = binomial())
#'   erglm_data |>
#'     er_plot(aucss, ae1, stratify_by = sex) |>
#'     er_plot_add_model(mod2) |>
#'     er_plot_add_quantiles(style = er_style_quantile_errorbar) |>
#'     er_plot_theme(dodge_width = 0.15) |>
#'     plot()
#'
#'   # labeling each interior quantile-bin boundary with its exposure
#'   # value, placed automatically to avoid the summary annotation
#'   erglm_data |>
#'     er_plot(aucss, ae1) |>
#'     er_plot_add_model(mod) |>
#'     er_plot_add_summary(mod) |>
#'     er_plot_add_quantiles(style = er_style_quantile_errorbar_vlines, vline_labels = TRUE) |>
#'     plot()
#' }
#'
#' @name er_style_quantile
#' @seealso [er_style()]
NULL

#' Dotted vertical lines at interior quantile-bin boundaries
#'
#' @param config Configuration for the quantile layer (as passed to a
#'   quantile builder); `config$breaks` holds the `n + 1` quantile
#'   cutpoints from [cut_exposure_quantile()] (excluding placebo).
#' @param exposure Exposure variable (as passed to a quantile builder).
#' @param vline_colour,vline_linetype Colour/linetype of the drawn line;
#'   see `er_style_quantile_errorbar_vlines()`'s own arguments of the
#'   same name.
#'
#' @returns A single [ggplot2::geom_vline()], or `NULL` if there are no
#'   interior boundaries to draw (e.g. a single bin).
#' @noRd
.quantile_boundary_vlines <- function(config, exposure, vline_colour = "grey50", vline_linetype = "dotted") {

  breaks <- config$breaks
  if (is.null(breaks) || length(breaks) <= 2) return(NULL)

  # drop the overall min/max -- those sit at (or beyond) the plot's own
  # edges and aren't bin *boundaries* in the sense a reader would care
  # about
  interior_breaks <- breaks[-c(1, length(breaks))]

  ggplot2::geom_vline(
    xintercept = interior_breaks,
    linetype = vline_linetype,
    colour = vline_colour
  )
}

#' Which vertical half of the panel a quantile vline label should sit in
#'
#' @param corner_distance The named length-4 vector from
#'   `.compute_corner_distance()` (`config$corner_distance`, as stored by
#'   `.layer_quantile()`).
#'
#' @details Finds the single least-crowded corner (the same selection
#' `er_style_summary_pvalue()` uses to place its own annotation:
#' `names(sort(x)[4])`) and returns the *opposite* vertical half, so a
#' vline label placed there won't collide with a summary annotation --
#' whether or not one is actually present, since both are derived from
#' the same raw-data calculation.
#'
#' @returns `"top"` or `"bottom"`.
#' @noRd
.quantile_label_side <- function(corner_distance) {
  least_crowded <- names(sort(corner_distance))[4]
  if (least_crowded %in% c("top_left", "top_right")) "bottom" else "top"
}

#' Value labels for interior quantile-bin boundary vlines
#'
#' @param config Configuration for the quantile layer; `config$breaks`
#'   and `config$corner_distance` are used.
#' @param exposure,response Exposure/response variables (as passed to a
#'   quantile builder).
#' @param theme Theme components (as passed to a quantile builder);
#'   `theme$format_number` formats the label text.
#' @param position One of `"auto"`, `"top"`, `"bottom"`.
#' @param size,colour,fill Passed to [ggplot2::geom_label()].
#' @param inset Fraction of the response range the label is inset from
#'   the panel edge.
#'
#' @returns A single [ggplot2::geom_label()], or `NULL` if there are no
#'   interior boundaries to label.
#' @noRd
.quantile_boundary_vline_labels <- function(config, exposure, response, theme, position = "auto",
                                             size = 3, colour = NULL, fill = NULL, inset = 0.05) {

  breaks <- config$breaks
  if (is.null(breaks) || length(breaks) <= 2) return(NULL)
  interior_breaks <- breaks[-c(1, length(breaks))]

  side <- if (identical(position, "auto")) {
    .quantile_label_side(config$corner_distance)
  } else {
    position
  }

  response_lo <- response$limits[1]
  response_hi <- response$limits[2]
  margin <- inset * (response_hi - response_lo)

  label_data <- data.frame(
    x = interior_breaks,
    y = if (side == "top") response_hi - margin else response_lo + margin,
    lbl = theme$format_number(interior_breaks)
  )

  args <- list(
    data = label_data,
    mapping = ggplot2::aes(x = x, y = y, label = lbl),
    angle = 90,
    vjust = if (side == "top") 1 else 0,
    inherit.aes = FALSE,
    show.legend = FALSE
  )
  if (!is.null(size)) args$size <- size
  if (!is.null(colour)) args$colour <- colour
  if (!is.null(fill)) args$fill <- fill

  do.call(ggplot2::geom_label, args)
}

#' @rdname er_style_quantile
#' @export
er_style_quantile_errorbar <- function(data, config, stratify, exposure, response, strata, theme,
                                        point_size = 2, errorbar_width = 0.025, label_size = 3, ...) {

  if (stratify == FALSE) {

    point <- ggplot2::geom_point(
      data = config$summary,
      mapping = ggplot2::aes(x = x_mid, y = y_mid),
      inherit.aes = FALSE,
      size = point_size,
      key_glyph = theme$draw_key
    )

    bar <- ggplot2::geom_errorbar(
      data = config$summary,
      mapping = ggplot2::aes(x = x_mid, ymin = ci_lower, ymax = ci_upper),
      width = errorbar_width * (exposure$limits[2] - exposure$limits[1]),
      inherit.aes = FALSE,
      key_glyph = theme$draw_key
    )

    label <- ggplot2::geom_text(
      data = config$summary,
      mapping = ggplot2::aes(x = x_mid, y = y_lbl, label = y_mid_lbl),
      inherit.aes = FALSE,
      size = label_size,
      show.legend = FALSE
    )
  }

  if (stratify == TRUE) {

    # different strata share (near-)identical `x_mid` values per exposure
    # bin (bins are quantile cutpoints of the same exposure variable), so
    # plotting points/bars/labels at `x_mid` unmodified makes labels for
    # different strata collide. Dodge all three horizontally by a small,
    # symmetric-around-`x_mid` offset per stratum, sized relative to the
    # exposure range so it scales sensibly across data sets. The spacing
    # itself (`theme$dodge_width`) is a cross-layer, stratification-wide
    # setting controlled via `er_plot_theme()`, not a per-builder argument
    # -- see `?er_plot_theme`'s `dodge_width` argument.
    summary_dodged <- .dodge_quantile_strata(config$summary, exposure$limits, theme$dodge_width)

    point <- ggplot2::geom_point(
      data = summary_dodged,
      mapping = ggplot2::aes(
        x = x_dodge, 
        y = y_mid,
        color = .data[["strata"]]
      ),
      inherit.aes = FALSE,
      size = point_size,
      key_glyph = theme$draw_key
    )
    
    bar <- ggplot2::geom_errorbar(
      data = summary_dodged,
      mapping = ggplot2::aes(
        x = x_dodge, 
        ymin = ci_lower, 
        ymax = ci_upper,
        color = .data[["strata"]]  
      ),
      inherit.aes = FALSE,
      width = errorbar_width * (exposure$limits[2] - exposure$limits[1]),
      key_glyph = theme$draw_key
    )
    
    label <- ggplot2::geom_text(
      data = summary_dodged,
      mapping = ggplot2::aes(
        x = x_dodge, 
        y = y_lbl, 
        label = y_mid_lbl,
        color = .data[["strata"]]
      ),
      inherit.aes = FALSE,
      size = label_size,
      show.legend = FALSE
    ) 
  }

  geoms <- list(point, bar, label)
  return(geoms)
}
er_style_quantile_errorbar <- er_style_tag(er_style_quantile_errorbar, layer = "quantile")


#' @rdname er_style_quantile
#' @export
er_style_quantile_errorbar_vlines <- function(data, config, stratify, exposure, response, strata, theme,
                                               point_size = 2, errorbar_width = 0.025, label_size = 3,
                                               vline_colour = "grey50", vline_linetype = "dotted",
                                               vline_labels = FALSE,
                                               vline_label_position = c("auto", "top", "bottom"),
                                               vline_label_size = 3,
                                               vline_label_colour = NULL,
                                               vline_label_fill = NULL,
                                               vline_label_inset = 0.05, ...) {
  vline_label_position <- match.arg(vline_label_position)
  vlines <- .quantile_boundary_vlines(config, exposure, vline_colour, vline_linetype)
  geoms <- er_style_quantile_errorbar(
    data, config, stratify, exposure, response, strata, theme,
    point_size = point_size, errorbar_width = errorbar_width, label_size = label_size, ...
  )
  out <- c(list(vlines), geoms)
  if (vline_labels) {
    labels <- .quantile_boundary_vline_labels(
      config, exposure, response, theme,
      position = vline_label_position, size = vline_label_size,
      colour = vline_label_colour, fill = vline_label_fill, inset = vline_label_inset
    )
    out <- c(out, list(labels))
  }
  out
}
er_style_quantile_errorbar_vlines <- er_style_tag(er_style_quantile_errorbar_vlines, layer = "quantile")


#' @rdname er_style_quantile
#' @export
er_style_quantile_pointrange <- function(data, config, stratify, exposure, response, strata, theme,
                                          label_size = 3, pointrange_size = NULL, pointrange_linewidth = NULL, ...) {

  if (stratify == FALSE) {

    geom_args <- list(
      data = config$summary,
      mapping = ggplot2::aes(x = x_mid, y = y_mid, ymin = ci_lower, ymax = ci_upper),
      inherit.aes = FALSE,
      key_glyph = theme$draw_key
    )
    if (!is.null(pointrange_size)) geom_args$size <- pointrange_size
    if (!is.null(pointrange_linewidth)) geom_args$linewidth <- pointrange_linewidth

    range <- do.call(ggplot2::geom_pointrange, geom_args)

    label <- ggplot2::geom_text(
      data = config$summary,
      mapping = ggplot2::aes(x = x_mid, y = y_lbl, label = y_mid_lbl),
      inherit.aes = FALSE,
      size = label_size,
      show.legend = FALSE
    )
  }

  if (stratify == TRUE) {

    # see `er_style_quantile_errorbar()` for why strata are dodged
    # horizontally before plotting, and where `theme$dodge_width` comes from
    summary_dodged <- .dodge_quantile_strata(config$summary, exposure$limits, theme$dodge_width)

    geom_args <- list(
      data = summary_dodged,
      mapping = ggplot2::aes(
        x = x_dodge,
        y = y_mid,
        ymin = ci_lower,
        ymax = ci_upper,
        color = .data[["strata"]]
      ),
      inherit.aes = FALSE,
      key_glyph = theme$draw_key
    )
    if (!is.null(pointrange_size)) geom_args$size <- pointrange_size
    if (!is.null(pointrange_linewidth)) geom_args$linewidth <- pointrange_linewidth

    range <- do.call(ggplot2::geom_pointrange, geom_args)

    label <- ggplot2::geom_text(
      data = summary_dodged,
      mapping = ggplot2::aes(
        x = x_dodge,
        y = y_lbl,
        label = y_mid_lbl,
        color = .data[["strata"]]
      ),
      inherit.aes = FALSE,
      size = label_size,
      show.legend = FALSE
    )
  }

  geoms <- list(range, label)
  return(geoms)
}
er_style_quantile_pointrange <- er_style_tag(er_style_quantile_pointrange, layer = "quantile")


#' @rdname er_style_quantile
#' @export
er_style_quantile_pointrange_vlines <- function(data, config, stratify, exposure, response, strata, theme,
                                                  label_size = 3, pointrange_size = NULL, pointrange_linewidth = NULL,
                                                  vline_colour = "grey50", vline_linetype = "dotted",
                                                  vline_labels = FALSE,
                                                  vline_label_position = c("auto", "top", "bottom"),
                                                  vline_label_size = 3,
                                                  vline_label_colour = NULL,
                                                  vline_label_fill = NULL,
                                                  vline_label_inset = 0.05, ...) {
  vline_label_position <- match.arg(vline_label_position)
  vlines <- .quantile_boundary_vlines(config, exposure, vline_colour, vline_linetype)
  geoms <- er_style_quantile_pointrange(
    data, config, stratify, exposure, response, strata, theme,
    label_size = label_size, pointrange_size = pointrange_size,
    pointrange_linewidth = pointrange_linewidth, ...
  )
  out <- c(list(vlines), geoms)
  if (vline_labels) {
    labels <- .quantile_boundary_vline_labels(
      config, exposure, response, theme,
      position = vline_label_position, size = vline_label_size,
      colour = vline_label_colour, fill = vline_label_fill, inset = vline_label_inset
    )
    out <- c(out, list(labels))
  }
  out
}
er_style_quantile_pointrange_vlines <- er_style_tag(er_style_quantile_pointrange_vlines, layer = "quantile")
