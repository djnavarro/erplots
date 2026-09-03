#' Model-curve builders for the TTE grammar
#'
#' Builder functions for the `model` layer ([er_tte_add_model()]),
#' drawing a fitted parametric `S(t)` curve with an optional uncertainty
#' band. Shares the same `function(data, config, stratify, time, strata,
#' theme, ...)` signature every TTE-grammar builder implements -- see
#' [er_style_tte_curve] for the shared interface.
#'
#' @include er-plot-style.R
#' @param data The original data frame (`object$data`).
#' @param config Configuration for the model layer (see
#'   `.layer_tte_model()`): `config$predictions` (the prediction tibble
#'   from [er_predict_survival()], with `time`/`fit_survival`/
#'   `ci_lower`/`ci_upper` columns), `config$time_grid`, `config$conf_level`.
#' @param stratify Logical: whether the fit is stratified
#'   (`!is.null(object$strata)`).
#' @param time `object$time` (`name`/`label`/`limits`).
#' @param strata `object$strata` (`var`/`label`/`type`/`n_strata`), or
#'   `NULL` when unstratified.
#' @param theme `object$theme`.
#' @param ... Additional named arguments forwarded from
#'   [er_tte_add_model()]'s own `...`.
#' @param show_ci Whether to draw the confidence band. Default `TRUE`.
#' @param ribbon_alpha Transparency of the confidence band (`0`-`1`).
#'   Default `0.15`.
#' @param linewidth Width of the curve's line. Default `1`.
#'
#' @details
#' Unlike [er_style_tte_curve_km()]'s Kaplan-Meier step curve,
#' `config$predictions` is a smooth prediction grid (one row per
#' `newdata` row x `config$time_grid` value), so `er_style_tte_model_line()`
#' draws an ordinary [ggplot2::geom_line()]/[ggplot2::geom_ribbon()] pair
#' rather than a step function.
#'
#' Stratified colour/fill both map to `config$predictions`'s own strata
#' column (named after `strata$var`) rather than a fixed name -- unlike
#' [er_style_tte_curve_km()], which always reads a column literally
#' named `strata` (`.tidy_survfit()`'s own naming). `er_tte_build()`'s
#' `.polish_tte_labels()` still retitles the resulting legend with
#' `strata$label` afterwards.
#'
#' `er_style_tte_model_line()` is tagged `er_style_tag(fn, layer =
#' "model")`, so [er_tte_add_model()] errors informatively if handed a
#' builder tagged for a different layer.
#'
#' @returns A geom, or a list of geoms.
#'
#' @seealso [er_tte_add_model()], [er_style_tte_curve_km()]
#'
#' @name er_style_tte_model
NULL

#' @rdname er_style_tte_model
#' @export
er_style_tte_model_line <- function(data, config, stratify, time, strata, theme, ...,
                                     show_ci = TRUE, ribbon_alpha = 0.15, linewidth = 1) {

  predictions <- config$predictions
  geoms <- list()

  if (show_ci) {
    ribbon_mapping <- if (stratify) {
      ggplot2::aes(x = time, ymin = ci_lower, ymax = ci_upper, fill = .data[[strata$var]])
    } else {
      ggplot2::aes(x = time, ymin = ci_lower, ymax = ci_upper)
    }
    geoms <- c(geoms, list(
      ggplot2::geom_ribbon(
        data = predictions,
        mapping = ribbon_mapping,
        alpha = ribbon_alpha,
        color = NA,
        key_glyph = theme$draw_key
      )
    ))
  }

  line_mapping <- if (stratify) {
    ggplot2::aes(x = time, y = fit_survival, color = .data[[strata$var]])
  } else {
    ggplot2::aes(x = time, y = fit_survival)
  }
  geoms <- c(geoms, list(
    ggplot2::geom_line(
      data = predictions,
      mapping = line_mapping,
      linewidth = linewidth,
      key_glyph = theme$draw_key
    )
  ))

  return(geoms)
}
er_style_tte_model_line <- er_style_tag(er_style_tte_model_line, layer = "model")
