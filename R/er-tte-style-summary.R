#' Summary annotation builders for the TTE grammar
#'
#' Builder functions for the `summary` layer ([er_tte_add_summary()]),
#' drawing a corner-placed text/label annotation from a log-rank test
#' comparing survival across `stratify_by`'s levels, a supplied model's
#' [er_summary()] result, or observation/event counts.
#'
#' @include er-plot-style.R
#' @param data The original data frame (`object$data`).
#' @param config Configuration for the summary layer (populated by
#'   [er_tte_add_summary()]): `config$logrank_p_value` (the log-rank
#'   test's p-value, or `NULL` when fewer than 2 strata levels are
#'   present in the data), `config$summary` (the supplied model's raw
#'   [er_summary()] result, or `NULL` when no `model` was supplied), and
#'   `config$corner_distance` (how uncrowded each panel corner is,
#'   relative to the plotted survival curve(s) -- see [er_style()]'s
#'   `?er_plot_add_summary()`-analogous corner-placement idiom).
#' @param stratify Logical: whether this layer was added with
#'   `keep_strata = TRUE` (the default whenever `stratify_by` was set in
#'   [er_tte()]) -- see [er_tte_add_summary()].
#' @param time `object$time` (`name`/`label`/`limits`).
#' @param strata `object$strata` (`var`/`label`).
#' @param theme `object$theme` -- `theme$format_p`/`theme$format_number`
#'   format the annotation's numbers.
#' @param ... Additional named arguments forwarded from
#'   [er_tte_add_summary()]'s own `...`.
#' @param inset Distance from the panel edge for the annotation label,
#'   as a fraction of the panel's width/height. Default `0.05`.
#' @param label_size Label text size. Defaults to `NULL` ([ggplot2::geom_label()]'s own default).
#' @param label_colour Label text colour. Defaults to `NULL` ([ggplot2::geom_label()]'s own default).
#' @param label_fill Label background fill. Defaults to `NULL` ([ggplot2::geom_label()]'s own default).
#' @param fields Fields from `glance` to include for
#'   `er_style_tte_summary_gof()`, and the order they're shown in: one
#'   or more of `"n"` (labelled "N"), `"aic"` ("AIC"), `"bic"` ("BIC"),
#'   or `"r_squared"` (labelled "R-squared"). Defaults to all four, in
#'   that order. A field is shown only when both present and non-`NA`
#'   in the model's `glance` result.
#'
#' @details
#' `er_style_tte_summary_logrank()` (the default) places its annotation
#' in whichever of the panel's 4 corners is currently furthest from the
#' survival curve(s), using the same `(0, 1)`-rescaled corner-distance
#' calculation [er_plot_add_summary()]'s own p-value annotation uses to
#' avoid a plot's raw data points -- here applied to the curve's own
#' `(time, surv)` coordinates instead, since there's no raw per-subject
#' scatter in this grammar for the annotation to avoid. It draws nothing
#' if `config$logrank_p_value` is `NULL` (fewer than 2 strata levels
#' present, including an unstratified object).
#'
#' `er_style_tte_summary_n()` draws subject and event counts -- one line
#' per stratum when `stratify` is `TRUE`, a single overall line
#' otherwise -- and doesn't depend on a model or `stratify_by` at all.
#'
#' `er_style_tte_summary_coefficients()` draws one line per row of the
#' supplied model's `coefficients` table (see [er_summary()]'s
#' `coefficients` field); it draws nothing if `coefficients` wasn't
#' supplied, or if the layer is stratified. `er_style_tte_summary_gof()`
#' draws a single-line, comma-separated goodness-of-fit annotation from
#' the model's `glance` field -- a curated subset (`N`, `AIC`, `BIC`,
#' R-squared) rather than every reserved `glance` column, showing only
#' whichever of those four are actually present and non-`NA`; it draws
#' nothing if none of them are available, or if the layer is stratified.
#'
#' All four builders are tagged `er_style_tag(fn, layer =
#' "tte_summary")` -- distinct from [er_plot_add_summary()]'s own
#' `"summary"` tag, since the two grammars' summary builders share no
#' signature (`exposure`/`response` vs. `time`) -- so
#' [er_tte_add_summary()] errors informatively if a builder tagged for a
#' different layer is passed to it instead (including
#' [er_plot_add_summary()]'s own builders).
#'
#' @returns A geom, or a list of geoms.
#'
#' @examples
#' library(survival)
#' lung |>
#'   transform(sex = factor(sex, labels = c("Male", "Female"))) |>
#'   er_tte(time, status == 2, stratify_by = sex) |>
#'   er_tte_add_curve() |>
#'   er_tte_add_summary(style = er_style_tte_summary_logrank, label_fill = "white") |>
#'   plot()
#'
#' # a purely descriptive annotation, with no log-rank test at all
#' lung |>
#'   er_tte(time, status == 2) |>
#'   er_tte_add_curve() |>
#'   er_tte_add_summary(style = er_style_tte_summary_n) |>
#'   plot()
#'
#' @name er_style_tte_summary
#' @seealso [er_tte_add_summary()]
NULL

#' @rdname er_style_tte_summary
#' @export
er_style_tte_summary_logrank <- function(data, config, stratify, time, strata, theme, ...,
                                          inset = 0.05, label_size = NULL, label_colour = NULL, label_fill = NULL) {

  if (is.null(config$logrank_p_value)) return(list())

  corner <- names(sort(config$corner_distance)[4])
  summary_data <- tibble::tibble(lbl = paste0("Log-rank test: ", theme$format_p(config$logrank_p_value)))

  x_left  <- inset
  x_right <- 1 - inset
  y_top   <- 1 - inset
  y_bot   <- inset

  if (corner == "top_left") {
    geoms <- .summary_label_geom(summary_data, x_left, y_top, 0, 1,
                                 label_size = label_size, label_colour = label_colour, label_fill = label_fill)
  }

  if (corner == "top_right") {
    geoms <- .summary_label_geom(summary_data, x_right, y_top, 1, 1,
                                 label_size = label_size, label_colour = label_colour, label_fill = label_fill)
  }

  if (corner == "bottom_left") {
    geoms <- .summary_label_geom(summary_data, x_left, y_bot, 0, 0,
                                 label_size = label_size, label_colour = label_colour, label_fill = label_fill)
  }

  if (corner == "bottom_right") {
    geoms <- .summary_label_geom(summary_data, x_right, y_bot, 1, 0,
                                 label_size = label_size, label_colour = label_colour, label_fill = label_fill)
  }

  return(geoms)
}
er_style_tte_summary_logrank <- er_style_tag(er_style_tte_summary_logrank, layer = "tte_summary")

#' @rdname er_style_tte_summary
#' @export
er_style_tte_summary_n <- function(data, config, stratify, time, strata, theme,
                                    inset = 0.05, label_size = NULL, label_colour = NULL, label_fill = NULL, ...) {

  if (stratify && !is.null(strata$var)) {
    counts <- data |>
      dplyr::summarise(
        n = dplyr::n(),
        n_event = sum(.er_tte_event, na.rm = TRUE),
        .by = ".er_tte_strata"
      ) |>
      dplyr::mutate(lbl = paste0(.er_tte_strata, ": N=", n, ", events=", n_event))
    lbl <- paste(counts$lbl, collapse = "\n")
  } else {
    lbl <- paste0("N=", nrow(data), ", events=", sum(data$.er_tte_event, na.rm = TRUE))
  }

  corner <- names(sort(config$corner_distance)[4])
  summary_data <- tibble::tibble(lbl = lbl)
  x_left  <- inset
  x_right <- 1 - inset
  y_top   <- 1 - inset
  y_bot   <- inset

  if (corner == "top_left") {
    geoms <- .summary_label_geom(summary_data, x_left, y_top, 0, 1,
                                 label_size = label_size, label_colour = label_colour, label_fill = label_fill)
  }

  if (corner == "top_right") {
    geoms <- .summary_label_geom(summary_data, x_right, y_top, 1, 1,
                                 label_size = label_size, label_colour = label_colour, label_fill = label_fill)
  }

  if (corner == "bottom_left") {
    geoms <- .summary_label_geom(summary_data, x_left, y_bot, 0, 0,
                                 label_size = label_size, label_colour = label_colour, label_fill = label_fill)
  }

  if (corner == "bottom_right") {
    geoms <- .summary_label_geom(summary_data, x_right, y_bot, 1, 0,
                                 label_size = label_size, label_colour = label_colour, label_fill = label_fill)
  }

  return(geoms)
}
er_style_tte_summary_n <- er_style_tag(er_style_tte_summary_n, layer = "tte_summary")

#' @rdname er_style_tte_summary
#' @export
er_style_tte_summary_coefficients <- function(data, config, stratify, time, strata, theme,
                                               inset = 0.05, label_size = NULL, label_colour = NULL, label_fill = NULL, ...) {

  coefs <- config$summary$coefficients
  if (is.null(coefs) || stratify) return(list())

  # `label` falls back to `term`; `p_value` is optional per row -- see
  # `?er_model_interface`'s `coefficients` contract. Checked via `%in%`
  # names() rather than `$` directly, since tibble's `$` warns on access
  # to a column that isn't there.
  term_label <- if ("label" %in% names(coefs)) coefs$label else coefs$term
  row_p_value <- if ("p_value" %in% names(coefs)) coefs$p_value else rep(NA_real_, nrow(coefs))
  line <- ifelse(
    is.na(row_p_value),
    paste0(term_label, ": ", theme$format_number(coefs$estimate)),
    paste0(term_label, ": ", theme$format_number(coefs$estimate), " (", theme$format_p(row_p_value), ")")
  )

  corner <- names(sort(config$corner_distance)[4])
  summary_data <- tibble::tibble(lbl = paste(line, collapse = "\n"))
  x_left  <- inset
  x_right <- 1 - inset
  y_top   <- 1 - inset
  y_bot   <- inset

  if (corner == "top_left") {
    geoms <- .summary_label_geom(summary_data, x_left, y_top, 0, 1,
                                 label_size = label_size, label_colour = label_colour, label_fill = label_fill)
  }

  if (corner == "top_right") {
    geoms <- .summary_label_geom(summary_data, x_right, y_top, 1, 1,
                                 label_size = label_size, label_colour = label_colour, label_fill = label_fill)
  }

  if (corner == "bottom_left") {
    geoms <- .summary_label_geom(summary_data, x_left, y_bot, 0, 0,
                                 label_size = label_size, label_colour = label_colour, label_fill = label_fill)
  }

  if (corner == "bottom_right") {
    geoms <- .summary_label_geom(summary_data, x_right, y_bot, 1, 0,
                                 label_size = label_size, label_colour = label_colour, label_fill = label_fill)
  }

  return(geoms)
}
er_style_tte_summary_coefficients <- er_style_tag(er_style_tte_summary_coefficients, layer = "tte_summary")

#' @rdname er_style_tte_summary
#' @export
er_style_tte_summary_gof <- function(data, config, stratify, time, strata, theme,
                                      inset = 0.05, fields = c("n", "aic", "bic", "r_squared"),
                                      label_size = NULL, label_colour = NULL, label_fill = NULL, ...) {

  glance <- config$summary$glance
  if (is.null(glance) || stratify) return(list())

  # a curated, compact subset of `glance`'s reserved columns (see
  # `?er_model_interface`) -- `df_residual`/`logLik`/`deviance`/
  # `converged` are part of the contract but deliberately left out of
  # this compact annotation. Each field is shown only if the column is
  # both present and non-`NA`, so a model that only populates some of
  # `glance` (e.g. `aic` but not `r_squared`) still gets a sensible,
  # partial annotation rather than a blank or an error. `fields`
  # controls which of the four recognised fields to show and in what
  # order.
  field_specs <- list(
    n         = list(label = "N",   format = function(x) as.character(as.integer(x))),
    aic       = list(label = "AIC", format = theme$format_number),
    bic       = list(label = "BIC", format = theme$format_number),
    r_squared = list(label = "R\u00b2", format = theme$format_number)
  )

  line <- character(0)
  for (col in fields) {
    if (col %in% names(field_specs) && col %in% names(glance) && !is.na(glance[[col]])) {
      spec <- field_specs[[col]]
      line <- c(line, paste0(spec$label, " = ", spec$format(glance[[col]])))
    }
  }
  if (length(line) == 0) return(list())

  corner <- names(sort(config$corner_distance)[4])
  summary_data <- tibble::tibble(lbl = paste(line, collapse = ", "))
  x_left  <- inset
  x_right <- 1 - inset
  y_top   <- 1 - inset
  y_bot   <- inset

  if (corner == "top_left") {
    geoms <- .summary_label_geom(summary_data, x_left, y_top, 0, 1,
                                 label_size = label_size, label_colour = label_colour, label_fill = label_fill)
  }

  if (corner == "top_right") {
    geoms <- .summary_label_geom(summary_data, x_right, y_top, 1, 1,
                                 label_size = label_size, label_colour = label_colour, label_fill = label_fill)
  }

  if (corner == "bottom_left") {
    geoms <- .summary_label_geom(summary_data, x_left, y_bot, 0, 0,
                                 label_size = label_size, label_colour = label_colour, label_fill = label_fill)
  }

  if (corner == "bottom_right") {
    geoms <- .summary_label_geom(summary_data, x_right, y_bot, 1, 0,
                                 label_size = label_size, label_colour = label_colour, label_fill = label_fill)
  }

  return(geoms)
}
er_style_tte_summary_gof <- er_style_tag(er_style_tte_summary_gof, layer = "tte_summary")
