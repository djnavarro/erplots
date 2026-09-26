#' Model-curve builders for the TTE grammar
#'
#' Builder functions for the `model` layer ([er_tte_add_model()]),
#' drawing a fitted parametric `S(t)` curve with an optional uncertainty
#' band. See [er_style_tte()] for the shared interface every TTE-grammar
#' builder implements.
#'
#' @include er-plot-style.R
#' @param data The original data frame (`object$data`).
#' @param config Configuration for the model layer (populated by
#'   [er_tte_add_model()]): `config$predictions` (the prediction tibble
#'   from [er_predict_survival()], with `time`/`fit_survival`/
#'   `ci_lower`/`ci_upper` columns), `config$time_grid`, `config$conf_level`.
#' @param stratify Logical: whether the fit is stratified
#'   (`!is.null(object$strata)`).
#' @param time `object$time` (`name`/`label`/`limits`).
#' @param strata `object$strata` (`var`/`label`), or
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
#' named `strata` (the tidied Kaplan-Meier table's own naming).
#' [er_tte_build()] still retitles the resulting legend with
#' `strata$label` afterwards.
#'
#' `er_style_tte_model_line()` is tagged `er_style_tag(fn, layer =
#' "tte_model")` -- distinct from [er_plot_add_model()]'s own `"model"`
#' tag, since the two grammars' model builders share no signature or
#' `config` contents -- so [er_tte_add_model()] errors informatively if
#' handed a builder tagged for a different layer (including
#' [er_plot_add_model()]'s own builders).
#'
#' @returns A geom, or a list of geoms.
#'
#' @examples
#' if (requireNamespace("ertte", quietly = TRUE)) {
#'   library(survival)
#'   library(ertte)
#'   mod <- ertte_aft(Surv(time, status == 2) ~ age, lung)
#'
#'   lung |>
#'     er_tte(time, status == 2) |>
#'     er_tte_add_curve() |>
#'     er_tte_add_model(mod, style = er_style_tte_model_line, ribbon_alpha = 0.3) |>
#'     plot()
#' }
#'
#' @seealso [er_tte_add_model()], [er_style_tte_curve_km()], [er_style_tte()]
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
er_style_tte_model_line <- er_style_tag(er_style_tte_model_line, layer = "tte_model")
