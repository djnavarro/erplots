
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
#' @details Builders for [er_plot_add_summary()], which annotate the base
#' panel with a summary statistic or descriptive label rather than
#' drawing a curve or raw data. `er_style_summary_pvalue()` (the default)
#' places a formatted p-value -- derived from the model's own
#' [er_summary()] method -- in whichever corner of the panel is furthest
#' from the observed data, and draws nothing at all if no model was
#' supplied to [er_plot_add_summary()], or if the layer is stratified (one
#' p-value doesn't unambiguously describe multiple curves).
#' `er_style_summary_n()` is a model-agnostic alternative: it always draws,
#' showing the total number of observations (or, when stratified, one
#' count per stratum level) -- demonstrating that a summary annotation
#' doesn't have to originate from a fitted model at all. Both are tagged
#' `er_style_tag(fn, layer = "summary")`, so [er_plot_add_summary()] errors
#' informatively if a builder tagged for a different layer is passed to
#' it instead.
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

  if (is.null(config$p_value) || stratify) return(list())

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

#' @rdname er_style_summary
#' @export
er_style_summary_n <- function(data, config, stratify, exposure, response, strata, theme, ...) {

  if (stratify && !is.null(strata$name)) {
    counts <- data |>
      dplyr::mutate(strata_value = .get_strata_values(data, strata$name)) |>
      dplyr::count(strata_value) |>
      dplyr::mutate(lbl = paste0(strata_value, ": N=", n))
    lbl <- paste(counts$lbl, collapse = "\n")
  } else {
    lbl <- paste0("N=", nrow(data))
  }

  corner <- names(sort(config$corner_distance)[4])
  summary_data <- tibble::tibble(lbl = lbl)

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
er_style_summary_n <- er_style_tag(er_style_summary_n, layer = "summary")
