#' Number-at-risk builders for the TTE grammar
#'
#' Builder functions for the `risktable` layer ([er_tte_add_risktable()]),
#' drawing a row of risk counts per stratum at a grid of time points.
#' Unlike every other TTE-grammar builder, this one's geoms are drawn
#' into their own patchwork panel below the curve, not onto the curve's
#' panel directly -- see [er_tte_build()].
#'
#' @include er-plot-style.R
#' @param data The original data frame (`object$data`).
#' @param config Configuration for the risktable layer (see
#'   `.layer_tte_risktable()`): `config$table` (`time`/`n_risk`/`strata`,
#'   one row per requested time break per stratum) and `config$breaks`
#'   (the time breaks themselves, also used as the curve panel's x-axis
#'   ticks -- see [er_tte_add_risktable()]).
#' @param stratify Logical: whether the fit is stratified
#'   (`!is.null(object$strata)`).
#' @param time `object$time` (`name`/`label`/`limits`).
#' @param strata `object$strata` (`var`/`label`/`type`/`n_strata`), or
#'   `NULL` when unstratified.
#' @param theme `object$theme`.
#' @param ... Additional named arguments forwarded from
#'   [er_tte_add_risktable()]'s own `...`.
#' @param text_size Size of the risk-count text. Default `3.5`.
#'
#' @details
#' Rows are ordered top-to-bottom in the same order strata first appear
#' in `config$table` (reversed, since a ggplot2 discrete y-axis plots
#' its first level at the bottom); an unstratified fit gets a single
#' `"All"` row.
#'
#' `er_style_tte_risktable_text()` is tagged `er_style_tag(fn, layer =
#' "risktable")`, so [er_tte_add_risktable()] errors informatively if
#' handed a builder tagged for a different layer.
#'
#' @returns A geom, or a list of geoms.
#'
#' @examples
#' library(survival)
#' lung |>
#'   er_tte(time, status == 2) |>
#'   er_tte_add_curve() |>
#'   er_tte_add_risktable(style = er_style_tte_risktable_text, text_size = 4) |>
#'   plot()
#'
#' @name er_style_tte_risktable
#' @seealso [er_tte_add_risktable()]
NULL

#' @rdname er_style_tte_risktable
#' @export
er_style_tte_risktable_text <- function(data, config, stratify, time, strata, theme, ...,
                                         text_size = 3.5) {

  strata_levels <- if (stratify) rev(unique(config$table$strata)) else "All"
  table <- config$table
  table$strata <- factor(table$strata, levels = strata_levels)

  list(
    ggplot2::geom_text(
      data = table,
      mapping = ggplot2::aes(x = time, y = strata, label = n_risk),
      size = text_size
    )
  )
}
er_style_tte_risktable_text <- er_style_tag(er_style_tte_risktable_text, layer = "risktable")
