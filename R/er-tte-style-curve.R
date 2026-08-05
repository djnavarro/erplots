#' Kaplan-Meier curve builders for the TTE grammar
#'
#' Builder functions for the `curve` layer ([er_tte_add_curve()]),
#' drawing the Kaplan-Meier estimate as a step function with an optional
#' step-shaped confidence band. Shares the same `function(data, config,
#' stratify, time, strata, theme, ...)` signature every TTE-grammar
#' builder implements -- the TTE analogue of [er_style()]'s shared
#' interface for the `er_plot()` grammar, adapted for a time x-axis/
#' survival-probability y-axis instead of exposure/response.
#'
#' @include er-plot-style.R
#' @param data The original data frame (`object$data`).
#' @param config Configuration for the curve layer (see
#'   `.layer_tte_curve()`): `config$table` (the tidy KM table, with a
#'   `(0, 1)` origin row prepended per stratum), `config$time_upper`
#'   (the time-axis upper limit, needed so the last confidence-band
#'   interval has somewhere to end), `config$conf_level`.
#' @param stratify Logical: whether the fit is stratified
#'   (`!is.null(object$strata)`).
#' @param time `object$time` (`name`/`label`/`limits`).
#' @param strata `object$strata` (`var`/`label`/`type`/`n_strata`), or
#'   `NULL` when unstratified.
#' @param theme `object$theme`.
#' @param ... Additional named arguments forwarded from
#'   [er_tte_add_curve()]'s own `...`.
#' @param show_ci Whether to draw the confidence band. Default `TRUE`.
#' @param ribbon_alpha Transparency of the confidence band (`0`-`1`).
#'   Default `0.15`.
#' @param linewidth Width of the step curve's line. Default `1`.
#'
#' @details
#' A Kaplan-Meier confidence band is a step function, just like the
#' curve itself, but ggplot2 has no built-in "step ribbon" geom (unlike
#' [ggplot2::geom_step()] for the line). `er_style_tte_curve_km()` works
#' around this with [ggplot2::geom_rect()]: one rectangle per interval
#' between consecutive event/censoring times, with `xmin`/`xmax` the
#' interval's start/end time and `ymin`/`ymax` the interval's constant
#' `lower`/`upper` bound -- visually identical to a step ribbon, without
#' needing a bespoke stat.
#'
#' Stratified colour/fill both map to `config$table`'s own `strata`
#' column (the already-cleaned stratum label, e.g. `"Q1"` or a
#' categorical level) rather than the original `stratify_by` column on
#' `data`, since that's what `config$table` actually carries -- there is
#' no polishing step yet (analogous to `er_plot()`'s `.polish_labels()`)
#' to retitle the resulting legend with `strata$label` instead of the
#' literal `"strata"`.
#'
#' `er_style_tte_curve_km()` is tagged `er_style_tag(fn, layer =
#' "curve")`, so [er_tte_add_curve()] errors informatively if handed a
#' builder tagged for a different layer.
#'
#' @returns A geom, or a list of geoms.
#'
#' @examples
#' library(survival)
#' lung |>
#'   er_tte(time, status == 2) |>
#'   er_tte_add_curve(style = er_style_tte_curve_km, ribbon_alpha = 0.3) |>
#'   plot()
#'
#' @name er_style_tte_curve
#' @seealso [er_tte_add_curve()]
NULL

#' @rdname er_style_tte_curve
#' @export
er_style_tte_curve_km <- function(data, config, stratify, time, strata, theme, ...,
                                   show_ci = TRUE, ribbon_alpha = 0.15, linewidth = 1) {

  step_table <- if (stratify) {
    config$table |> dplyr::mutate(xmax = dplyr::lead(time, default = config$time_upper), .by = strata)
  } else {
    config$table |> dplyr::mutate(xmax = dplyr::lead(time, default = config$time_upper))
  }

  geoms <- list()

  if (show_ci) {
    ribbon_mapping <- if (stratify) {
      ggplot2::aes(xmin = time, xmax = xmax, ymin = lower, ymax = upper, fill = .data[["strata"]])
    } else {
      ggplot2::aes(xmin = time, xmax = xmax, ymin = lower, ymax = upper)
    }
    geoms <- c(geoms, list(
      ggplot2::geom_rect(
        data = step_table,
        mapping = ribbon_mapping,
        alpha = ribbon_alpha,
        color = NA,
        key_glyph = theme$draw_key
      )
    ))
  }

  line_mapping <- if (stratify) {
    ggplot2::aes(x = time, y = surv, color = .data[["strata"]])
  } else {
    ggplot2::aes(x = time, y = surv)
  }
  geoms <- c(geoms, list(
    ggplot2::geom_step(
      data = config$table,
      mapping = line_mapping,
      linewidth = linewidth,
      key_glyph = theme$draw_key
    )
  ))

  return(geoms)
}
er_style_tte_curve_km <- er_style_tag(er_style_tte_curve_km, layer = "curve")
