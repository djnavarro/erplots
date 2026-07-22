
#' Summary annotation builders for exposure-response plots
#'
#' @param data The original data frame
#' @param config Configuration for the specific plot
#' @param stratify Logical indicating whether to stratify
#' @param exposure Exposure variable
#' @param response Response variable
#' @param strata Stratification variable
#' @param theme Theme components
#' @param ... Additional named arguments forwarded from
#'   [er_plot_add_model()]'s own `...` (shared with `style`); see
#'   [er_style()]'s "Passing extra arguments to a builder" section.
#'
#' @details Builders for the `summary_style` argument of
#' [er_plot_add_model()], which annotate the model panel with a summary
#' statistic rather than drawing the curve itself: `er_style_summary_pvalue()`
#' (the default) places a formatted p-value in whichever corner of the
#' panel is furthest from the data. It's tagged `er_style_tag(fn, layer
#' = "summary")`, so [er_plot_add_model()] errors informatively if it's
#' passed as `style` (the curve/ribbon argument) rather than
#' `summary_style`.
#'
#' See [er_style()] for the shared builder interface these functions
#' implement, including how to write a custom builder of your own.
#'
#' @returns A geom, or a list of geoms; see [er_style()].
#'
#' @name er_style_summary
#' @seealso [er_style()]
NULL

#' @rdname er_style_summary
#' @export
er_style_summary_pvalue <- function(data, config, stratify, exposure, response, strata, theme, ...) {

  if (is.null(config$p_value)) return(list())

  corner <- names(sort(config$corner_distance)[4])
  summary_data <- tibble::tibble(lbl = theme$format_p(config$p_value))

  if (corner == "top_left") {
    geoms <- ggplot2::geom_label(
      data = summary_data,
      mapping = ggplot2::aes(x = I(.05), y = I(.95), label = lbl),
      hjust = 0, vjust = 1, show.legend = FALSE
    )
  }

  if (corner == "top_right") {
    geoms <- ggplot2::geom_label(
      data = summary_data,
      mapping = ggplot2::aes(x = I(.95), y = I(.95), label = lbl),
      hjust = 1, vjust = 1, show.legend = FALSE
    )
  }

  if (corner == "bottom_left") {
    geoms <- ggplot2::geom_label(
      data = summary_data,
      mapping = ggplot2::aes(x = I(.05), y = I(.05), label = lbl),
      hjust = 0, vjust = 0, show.legend = FALSE
    )
  }

  if (corner == "bottom_right") {
    geoms <- ggplot2::geom_label(
      data = summary_data,
      mapping = ggplot2::aes(x = I(.95), y = I(.05), label = lbl),
      hjust = 1, vjust = 0, show.legend = FALSE
    )
  }
  
  return(geoms)
}
er_style_summary_pvalue <- er_style_tag(er_style_summary_pvalue, layer = "summary")
