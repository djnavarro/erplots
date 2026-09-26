#' Number-at-risk builders for the TTE grammar
#'
#' Builder functions for the `risktable` layer ([er_tte_add_risktable()]),
#' drawing a row of risk counts per stratum at a grid of time points.
#' Unlike every other TTE-grammar builder, this one's geoms are drawn
#' into their own patchwork panel below the curve, not onto the curve's
#' panel directly -- see [er_tte_build()].
#'
#' @include er-plot-style.R er-style-registry.R
#' @param data The original data frame (`object$data`).
#' @param config Configuration for the risktable layer (populated by
#'   [er_tte_add_risktable()]): `config$table` (`time`/`n_risk`/`strata`/
#'   `n_baseline` -- the stratum's time-zero number at risk, used by
#'   `show_percent` below -- one row per requested time break per
#'   stratum) and `config$breaks` (the time breaks themselves, also used
#'   as the curve panel's x-axis ticks).
#' @param stratify Logical: whether the fit is stratified
#'   (`!is.null(object$strata)`).
#' @param time `object$time` (`name`/`label`/`limits`).
#' @param strata `object$strata` (`var`/`label`), or
#'   `NULL` when unstratified.
#' @param theme `object$theme`.
#' @param ... Additional named arguments forwarded from
#'   [er_tte_add_risktable()]'s own `...`.
#' @param text_size Size of the risk-count text. Default `3.5`.
#' @param show_percent Whether to append each break's `n_risk` as a
#'   percentage of that stratum's own baseline (time-zero) size,
#'   formatted via [er_tte_theme()]'s `format_percent`. Default `FALSE`
#'   (a bare count, the previous behaviour).
#'
#' @details
#' See [er_style_tte()] for the shared interface every TTE-grammar
#' builder implements.
#'
#' Rows are ordered top-to-bottom in the same order strata first appear
#' in `config$table` (reversed, since a ggplot2 discrete y-axis plots
#' its first level at the bottom); an unstratified fit gets a single
#' `"All"` row.
#'
#' `show_percent = TRUE` displays `"<n_risk> (<percent>%)"` instead of a
#' bare `n_risk`, using [er_tte_theme()]'s `format_percent` (defaulting
#' to `scales::label_percent(accuracy = 1)`) to format
#' `n_risk / n_baseline` -- see `config` above for where `n_baseline`
#' comes from.
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
#' @seealso [er_tte_add_risktable()], [er_style_tte()]
NULL

#' @rdname er_style_tte_risktable
#' @export
er_style_tte_risktable_text <- function(data, config, stratify, time, strata, theme, ...,
                                         text_size = 3.5, show_percent = FALSE) {

  strata_levels <- if (stratify) rev(unique(config$table$strata)) else "All"
  table <- config$table
  table$strata <- factor(table$strata, levels = strata_levels)

  # `show_percent = TRUE` appends each break's `n_risk` as a percentage
  # of that stratum's own baseline (`n_baseline`, time-zero) size,
  # formatted via `theme$format_percent` -- see issue #22
  table$.label <- if (show_percent) {
    paste0(table$n_risk, " (", theme$format_percent(table$n_risk / table$n_baseline), ")")
  } else {
    as.character(table$n_risk)
  }

  list(
    ggplot2::geom_text(
      data = table,
      mapping = ggplot2::aes(x = time, y = strata, label = .label),
      size = text_size
    )
  )
}
er_style_tte_risktable_text <- er_style_tag(er_style_tte_risktable_text, layer = "tte_risktable", label = "text")
