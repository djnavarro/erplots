

#' @rdname er_partial
#' @export
build_quantile_errorbar <- function(data, config, stratify, exposure, response, strata, style) {

  if (stratify == FALSE) {

    point <- ggplot2::geom_point(
      data = config$summary,
      mapping = ggplot2::aes(x = x_mid, y = y_mid),
      inherit.aes = FALSE,
      size = 2,
      key_glyph = style$draw_key
    )

    bar <- ggplot2::geom_errorbar(
      data = config$summary,
      mapping = ggplot2::aes(x = x_mid, ymin = ci_lower, ymax = ci_upper),
      width = 0.025 * (exposure$limits[2] - exposure$limits[1]),
      inherit.aes = FALSE,
      key_glyph = style$draw_key
    )

    label <- ggplot2::geom_text(
      data = config$summary,
      mapping = ggplot2::aes(x = x_mid, y = y_lbl, label = y_mid_lbl),
      inherit.aes = FALSE,
      size = 3,
      show.legend = FALSE
    )
  }

  if (stratify == TRUE) {

    # different strata share (near-)identical `x_mid` values per exposure
    # bin (bins are quantile cutpoints of the same exposure variable), so
    # plotting points/bars/labels at `x_mid` unmodified makes labels for
    # different strata collide -- see PLAN.md "Stratified quantile labels
    # can visually overlap". Dodge all three horizontally by a small,
    # symmetric-around-`x_mid` offset per stratum, sized relative to the
    # exposure range so it scales sensibly across data sets.
    summary_dodged <- .dodge_quantile_strata(config$summary, exposure$limits)

    point <- ggplot2::geom_point(
      data = summary_dodged,
      mapping = ggplot2::aes(
        x = x_dodge, 
        y = y_mid,
        color = .data[["strata"]]
      ),
      inherit.aes = FALSE,
      size = 2,
      key_glyph = style$draw_key
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
      width = 0.025 * (exposure$limits[2] - exposure$limits[1]),
      key_glyph = style$draw_key
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
      size = 3,
      show.legend = FALSE
    ) 
  }

  geoms <- list(point, bar, label)
  return(geoms)
}


#' @rdname er_partial
#' @export
build_quantile_bar <- function(data, config, stratify, exposure, response, strata, style) {

  if (stratify == FALSE) {

    bar <- ggplot2::geom_col(
      data = config$summary,
      mapping = ggplot2::aes(x = x_mid, y = y_mid),
      width = 0.06 * (exposure$limits[2] - exposure$limits[1]),
      alpha = .7,
      key_glyph = style$draw_key
    )

    errbar <- ggplot2::geom_errorbar(
      data = config$summary,
      mapping = ggplot2::aes(x = x_mid, ymin = ci_lower, ymax = ci_upper),
      width = 0.025 * (exposure$limits[2] - exposure$limits[1]),
      inherit.aes = FALSE,
      key_glyph = style$draw_key
    )

    label <- ggplot2::geom_text(
      data = config$summary,
      mapping = ggplot2::aes(x = x_mid, y = y_lbl, label = y_mid_lbl),
      inherit.aes = FALSE,
      size = 3,
      show.legend = FALSE
    )
  }

  if (stratify == TRUE) {

    # see `build_quantile_errorbar()` for why strata are dodged
    # horizontally before plotting
    summary_dodged <- .dodge_quantile_strata(config$summary, exposure$limits)

    bar <- ggplot2::geom_col(
      data = summary_dodged,
      mapping = ggplot2::aes(
        x = x_dodge,
        y = y_mid,
        fill = .data[["strata"]]
      ),
      width = 0.045 * (exposure$limits[2] - exposure$limits[1]),
      alpha = .7,
      position = "identity",
      key_glyph = style$draw_key
    )

    errbar <- ggplot2::geom_errorbar(
      data = summary_dodged,
      mapping = ggplot2::aes(
        x = x_dodge,
        ymin = ci_lower,
        ymax = ci_upper,
        color = .data[["strata"]]
      ),
      inherit.aes = FALSE,
      width = 0.025 * (exposure$limits[2] - exposure$limits[1]),
      key_glyph = style$draw_key
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
      size = 3,
      show.legend = FALSE
    )
  }

  geoms <- list(bar, errbar, label)
  return(geoms)
}


#' @rdname er_partial
#' @export
build_quantile_pointrange <- function(data, config, stratify, exposure, response, strata, style) {

  if (stratify == FALSE) {

    range <- ggplot2::geom_pointrange(
      data = config$summary,
      mapping = ggplot2::aes(x = x_mid, y = y_mid, ymin = ci_lower, ymax = ci_upper),
      inherit.aes = FALSE,
      key_glyph = style$draw_key
    )

    label <- ggplot2::geom_text(
      data = config$summary,
      mapping = ggplot2::aes(x = x_mid, y = y_lbl, label = y_mid_lbl),
      inherit.aes = FALSE,
      size = 3,
      show.legend = FALSE
    )
  }

  if (stratify == TRUE) {

    # see `build_quantile_errorbar()` for why strata are dodged
    # horizontally before plotting
    summary_dodged <- .dodge_quantile_strata(config$summary, exposure$limits)

    range <- ggplot2::geom_pointrange(
      data = summary_dodged,
      mapping = ggplot2::aes(
        x = x_dodge,
        y = y_mid,
        ymin = ci_lower,
        ymax = ci_upper,
        color = .data[["strata"]]
      ),
      inherit.aes = FALSE,
      key_glyph = style$draw_key
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
      size = 3,
      show.legend = FALSE
    )
  }

  geoms <- list(range, label)
  return(geoms)
}

