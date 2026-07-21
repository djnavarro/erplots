
#' Quantile summary builders for exposure-response plots
#'
#' @param data The original data frame
#' @param config Configuration for the specific plot
#' @param stratify Logical indicating whether to stratify
#' @param exposure Exposure variable
#' @param response Response variable
#' @param strata Stratification variable
#' @param style Style components
#'
#' @details Builders for the `quantile` layer ([er_plot_add_quantiles()]),
#' which bins exposure into quantile groups and plots a response summary
#' (rate, mean, or count-mean, depending on response type) with an
#' uncertainty interval per bin: `er_builder_quantile_errorbar()` (point plus
#' error bar, the default) and `er_builder_quantile_pointrange()` (point
#' range). `er_builder_quantile_errorbar_vlines()` and
#' `er_builder_quantile_pointrange_vlines()` are minor variants of each,
#' additionally drawing a dotted [ggplot2::geom_vline()] at each interior
#' quantile cutpoint (i.e. every bin boundary except the exposure
#' variable's overall min/max) -- a common way exposure-response bin plots
#' are annotated in practice, so that the reader can see exactly where one
#' quantile bin ends and the next begins without inferring it from the
#' point/error bar spacing alone. All four are tagged
#' `er_builder_tag(fn, layer = "quantile")`, so [er_plot_add_quantiles()]
#' errors informatively if handed a builder tagged for a different layer.
#'
#' See [er_builder()] for the shared builder interface these functions
#' implement, including how to write a custom builder of your own.
#'
#' @returns A geom, or a list of geoms; see [er_builder()].
#'
#' @name er_builder_quantile
#' @seealso [er_builder()]
NULL

#' Dotted vertical lines at interior quantile-bin boundaries
#'
#' @param config Configuration for the quantile layer (as passed to a
#'   quantile builder); `config$breaks` holds the `n + 1` quantile
#'   cutpoints from [cut_exposure_quantile()] (excluding placebo).
#' @param exposure Exposure variable (as passed to a quantile builder).
#'
#' @returns A single [ggplot2::geom_vline()], or `NULL` if there are no
#'   interior boundaries to draw (e.g. a single bin).
#' @noRd
.quantile_boundary_vlines <- function(config, exposure) {

  breaks <- config$breaks
  if (is.null(breaks) || length(breaks) <= 2) return(NULL)

  # drop the overall min/max -- those sit at (or beyond) the plot's own
  # edges and aren't bin *boundaries* in the sense a reader would care
  # about
  interior_breaks <- breaks[-c(1, length(breaks))]

  ggplot2::geom_vline(
    xintercept = interior_breaks,
    linetype = "dotted",
    colour = "grey50"
  )
}

#' @rdname er_builder_quantile
#' @export
er_builder_quantile_errorbar <- function(data, config, stratify, exposure, response, strata, style) {

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
er_builder_quantile_errorbar <- er_builder_tag(er_builder_quantile_errorbar, layer = "quantile")


#' @rdname er_builder_quantile
#' @export
er_builder_quantile_errorbar_vlines <- function(data, config, stratify, exposure, response, strata, style) {
  vlines <- .quantile_boundary_vlines(config, exposure)
  geoms <- er_builder_quantile_errorbar(data, config, stratify, exposure, response, strata, style)
  c(list(vlines), geoms)
}
er_builder_quantile_errorbar_vlines <- er_builder_tag(er_builder_quantile_errorbar_vlines, layer = "quantile")


#' @rdname er_builder_quantile
#' @export
er_builder_quantile_pointrange <- function(data, config, stratify, exposure, response, strata, style) {

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

    # see `er_builder_quantile_errorbar()` for why strata are dodged
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
er_builder_quantile_pointrange <- er_builder_tag(er_builder_quantile_pointrange, layer = "quantile")


#' @rdname er_builder_quantile
#' @export
er_builder_quantile_pointrange_vlines <- function(data, config, stratify, exposure, response, strata, style) {
  vlines <- .quantile_boundary_vlines(config, exposure)
  geoms <- er_builder_quantile_pointrange(data, config, stratify, exposure, response, strata, style)
  c(list(vlines), geoms)
}
er_builder_quantile_pointrange_vlines <- er_builder_tag(er_builder_quantile_pointrange_vlines, layer = "quantile")

