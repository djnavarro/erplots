
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
#' doesn't have to originate from a fitted model at all.
#' `er_style_summary_coefficients()` draws one line per row of the model's
#' `coefficients` table (see [er_summary()]'s `coefficients` field), useful
#' for models with several parameters and no single privileged p-value
#' (e.g. a multi-parameter nonlinear model); it draws nothing if
#' `coefficients` wasn't supplied, or if the layer is stratified.
#' `er_style_summary_gof()` draws a single-line, comma-separated
#' goodness-of-fit annotation from the model's `glance` field (see
#' [er_summary()]) -- a curated subset (`N`, `AIC`, `BIC`, `R\u00b2`) rather
#' than every reserved `glance` column, showing only whichever of those
#' four are actually present and non-`NA`; it draws nothing if none of them
#' are available, or if the layer is stratified. All four builders are
#' tagged `er_style_tag(fn, layer = "summary")`, so [er_plot_add_summary()]
#' errors informatively if a builder tagged for a different layer is passed
#' to it instead.
#'
#' See [er_style()] for the shared builder interface these functions
#' implement, including how to write a custom builder of your own.
#'
#' @returns A geom, or a list of geoms; see [er_style()].
#'
#' @examples
#' if (requireNamespace("erglm", quietly = TRUE)) {
#'   library(erglm)
#'   mod <- erglm_model(ae1 ~ aucss, erglm_data, family = binomial())
#'
#'   # er_style_summary_pvalue(): the default, drawn from the model's own
#'   # er_summary()
#'   erglm_data |>
#'     er_plot(aucss, ae1) |>
#'     er_plot_add_model(mod) |>
#'     er_plot_add_summary(model = mod, style = er_style_summary_pvalue) |>
#'     plot()
#'
#'   # er_style_summary_n(): model-agnostic observation count
#'   erglm_data |>
#'     er_plot(aucss, ae1) |>
#'     er_plot_add_model(mod) |>
#'     er_plot_add_summary(style = er_style_summary_n) |>
#'     plot()
#' }
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

#' @rdname er_style_summary
#' @export
er_style_summary_coefficients <- function(data, config, stratify, exposure, response, strata, theme, ...) {

  coefs <- config$summary$coefficients
  if (is.null(coefs) || stratify) return(list())

  # `label` falls back to `term`; `p_value` is optional per row -- see
  # `?er_model_interface`'s `coefficients` contract. Checked via `%in%
  # names()` rather than `$` directly, since tibble's `$` warns on access
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
er_style_summary_coefficients <- er_style_tag(er_style_summary_coefficients, layer = "summary")

#' @rdname er_style_summary
#' @export
er_style_summary_gof <- function(data, config, stratify, exposure, response, strata, theme, ...) {

  glance <- config$summary$glance
  if (is.null(glance) || stratify) return(list())

  # a curated, compact subset of `glance`'s reserved columns (see
  # `?er_model_interface`) -- `df_residual`/`logLik`/`deviance`/
  # `converged` are part of the contract but deliberately left out of
  # this compact annotation; a model package wanting to show those can
  # write its own builder reading `config$summary$glance` directly.
  # Each field is shown only if the column is both present and non-`NA`,
  # so a model that only populates some of `glance` (e.g. `aic` but not
  # `r_squared`) still gets a sensible, partial annotation rather than a
  # blank or an error.
  fields <- list(
    n         = list(label = "N",   format = function(x) as.character(as.integer(x))),
    aic       = list(label = "AIC", format = theme$format_number),
    bic       = list(label = "BIC", format = theme$format_number),
    r_squared = list(label = "R\u00b2", format = theme$format_number)
  )

  line <- character(0)
  for (col in names(fields)) {
    if (col %in% names(glance) && !is.na(glance[[col]])) {
      spec <- fields[[col]]
      line <- c(line, paste0(spec$label, " = ", spec$format(glance[[col]])))
    }
  }
  if (length(line) == 0) return(list())

  corner <- names(sort(config$corner_distance)[4])
  summary_data <- tibble::tibble(lbl = paste(line, collapse = ", "))

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
er_style_summary_gof <- er_style_tag(er_style_summary_gof, layer = "summary")
