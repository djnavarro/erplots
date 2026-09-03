#' Censoring-mark builders for the TTE grammar
#'
#' Builder functions for the `censor` layer ([er_tte_add_censor()]),
#' marking each censoring time directly on the Kaplan-Meier curve.
#' Shares the same `function(data, config, stratify, time, strata,
#' theme, ...)` signature every TTE-grammar builder implements.
#'
#' @include er-plot-style.R
#' @param data The original data frame (`object$data`).
#' @param config Configuration for the censor layer (see
#'   `.layer_tte_censor()`): `config$table` (the subset of the tidy KM
#'   table where `n_censor > 0`, with a `strata` column when
#'   stratified).
#' @param stratify Logical: whether the fit is stratified
#'   (`!is.null(object$strata)`).
#' @param time `object$time` (`name`/`label`/`limits`).
#' @param strata `object$strata` (`var`/`label`/`type`/`n_strata`), or
#'   `NULL` when unstratified.
#' @param theme `object$theme`.
#' @param ... Additional named arguments forwarded from
#'   [er_tte_add_censor()]'s own `...`.
#' @param shape Point shape for a censoring mark. Default `3` (a plus
#'   sign), the conventional Kaplan-Meier censoring glyph.
#' @param size Point size. Default `2`.
#' @param stroke Point stroke width. Default `0.75`.
#'
#' @details
#' A censoring-only row of the KM table (`n_censor > 0`, `n_event == 0`)
#' carries the survival value the curve already had going into that
#' time -- Kaplan-Meier survival only drops at an *event* time -- so a
#' mark drawn at `(time, surv)` lands exactly on the step curve without
#' any extra lookup.
#'
#' Stratified colour maps to `config$table`'s own `strata` column, the
#' same already-cleaned stratum label [er_style_tte_curve_km()] uses,
#' so a censoring mark takes on the colour of the curve it sits on. The
#' marks never contribute their own legend entry (`show.legend =
#' FALSE`) -- the curve layer's legend already identifies each stratum.
#'
#' `er_style_tte_censor_ticks()` is tagged `er_style_tag(fn, layer =
#' "censor")`, so [er_tte_add_censor()] errors informatively if handed
#' a builder tagged for a different layer.
#'
#' @returns A geom, or a list of geoms.
#'
#' @examples
#' library(survival)
#' lung |>
#'   er_tte(time, status == 2) |>
#'   er_tte_add_curve() |>
#'   er_tte_add_censor(style = er_style_tte_censor_ticks, shape = 124, size = 3) |>
#'   plot()
#'
#' @name er_style_tte_censor
#' @seealso [er_tte_add_censor()]
NULL

#' @rdname er_style_tte_censor
#' @export
er_style_tte_censor_ticks <- function(data, config, stratify, time, strata, theme, ...,
                                       shape = 3, size = 2, stroke = 0.75) {

  if (nrow(config$table) == 0) return(list())

  censor_mapping <- if (stratify) {
    ggplot2::aes(x = time, y = surv, color = .data[["strata"]])
  } else {
    ggplot2::aes(x = time, y = surv)
  }

  list(
    ggplot2::geom_point(
      data = config$table,
      mapping = censor_mapping,
      shape = shape,
      size = size,
      stroke = stroke,
      show.legend = FALSE
    )
  )
}
er_style_tte_censor_ticks <- er_style_tag(er_style_tte_censor_ticks, layer = "censor")
