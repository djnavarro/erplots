
#' The exposure-response plotting mini-language
#'
#' Create an `er_plot` specification for exposure-response visualization. Build the plot by adding layers (model, summary, quantiles, data, groups) and render with `plot()`/`print()` or [er_plot_build()].
#'
#'
#' @details
#' Layers are either singleton or additive: model, summary, quantile, and data layers are singleton (a second call replaces the previous); groups are additive (each call adds a panel).
#'
#' `stratify_by` declares a discrete variable used for color/fill across layers; each layer's `keep_strata` controls whether it uses stratification. Rows with `NA` in the stratification variable are kept as their own level.
#'
#' `response_type` governs response-scale defaults and which interval method the quantile and VPC layers use; see `response_type` below and [er_plot_add_quantiles()] for details.
#'
#' @param data Data frame or tibble containing the observed data.
#' @param exposure Exposure variable (one variable, unquoted).
#' @param response Response variable (one variable, unquoted).
#' @param stratify_by Stratification variable used for color and fill (one variable, unquoted).
#' @param response_type One of `"auto"`, `"binary"`, `"continuous"`, or `"count"`.
#'
#' @returns An (empty) plot object of class `er_plot`.
#'
#' @examples
#' if (requireNamespace("erglm", quietly = TRUE)) {
#' library(erglm)
#' mod <- erglm_model(ae1 ~ aucss, erglm_data, family = binomial())
#'
#' erglm_data |>
#'   er_plot(aucss, ae1) |>
#'   er_plot_add_model(mod) |>
#'   er_plot_add_quantiles() |>
#'   er_plot_add_groups(aucss) |>
#'   plot()
#' }
#'
#' @seealso [er_plot_add_model()], [er_plot_add_summary()],
#'   [er_plot_add_quantiles()],
#'   [er_plot_add_data()], [er_plot_add_groups()],
#'   [er_plot_build()], [er_plot_theme()], [er_model_interface]
#'
#' @name er_plot
NULL


# setup -----------------------------------------------------------------------

#' @rdname er_plot
#' @export
er_plot <- function(data, exposure, response, stratify_by = NULL, response_type = "auto") {

  # a grouped/rowwise tibble (dplyr::group_by()/dplyr::rowwise()) is a
  # realistic accidental input -- e.g. piping straight from a `group_by()`
  # call -- but every internal `.by = `/`dplyr::mutate()` computation
  # downstream assumes an ungrouped frame. Left ungrouped, a grouped
  # tibble either errors opaquely ("Can't supply `.by` when `.data` is a
  # grouped data frame") or, worse, silently changes what gets computed
  # (e.g. a rowwise tibble runs `cut_exposure_quantile()` once per row).
  # `dplyr::ungroup()` is a no-op for a plain data.frame or an
  # already-ungrouped tibble, so this is safe to call unconditionally.
  data <- dplyr::ungroup(data)

  response_type <- match.arg(response_type, c("auto", "binary", "continuous", "count"))

  # validate that exposure/response/stratify_by actually name columns of
  # `data` -- without this, a typo'd column name silently produces
  # `NULL`/`Inf`/`-Inf` limits (via `data[[name]]` returning `NULL`) rather
  # than an error at the point of the actual mistake
  exposure_name <- rlang::as_name(rlang::enquo(exposure))
  response_name <- rlang::as_name(rlang::enquo(response))
  strata_quo <- rlang::enquo(stratify_by)
  strata_name <- if (!rlang::quo_is_null(strata_quo)) rlang::as_name(strata_quo) else NULL

  missing_cols <- setdiff(c(exposure_name, response_name, strata_name), names(data))
  if (length(missing_cols) > 0) {
    rlang::abort(c(
      sprintf(
        "Column%s not found in `data`: %s.",
        if (length(missing_cols) > 1) "s" else "",
        paste0("`", missing_cols, "`", collapse = ", ")
      ),
      "i" = "Check that `exposure`/`response`/`stratify_by` reference actual columns of `data`."
    ))
  }

  # validate that exposure is numeric -- without this, a factor/character/
  # logical exposure column fails much later with an opaque low-level error
  # (e.g. "'range' not meaningful for factors" from the `range()` call
  # below), rather than a clear message naming the actual problem
  if (!is.numeric(data[[exposure_name]])) {
    rlang::abort(c(
      sprintf(
        "`exposure` (`%s`) must be numeric, not %s.",
        exposure_name, paste(class(data[[exposure_name]]), collapse = "/")
      ),
      "i" = "erplots' quantile-binning and model-prediction grid assume a numeric exposure axis."
    ))
  }

  # empty plot object
  object <- structure(
    list(
      data  = NULL,
      exposure = .plot_variable(role = "exposure"),
      response = .plot_variable(role = "response"),
      strata = .plot_variable(role = "strata"),
      layer = list(
        model    = NULL, 
        summary  = NULL,
        quantile = NULL, 
        data     = NULL,
        overlay  = NULL,
        group    = NULL
      ),
      plot = list(
        base = NULL, 
        data = NULL, 
        group = NULL
      ),
      theme = list(),
      output = NULL 
    ),
    class = "er_plot"
  )

  # store observed data
  object$data <- data

  # store variable names
  object$exposure$name <- exposure_name
  object$response$name <- response_name
  if (!is.null(strata_name)) object$strata$name <- strata_name
  
  # store (default) variable labels
  object$exposure$label <- .get_label(object$data[[object$exposure$name]]) %||% object$exposure$name
  object$response$label <- .get_label(object$data[[object$response$name]]) %||% object$response$name    
  if (!is.null(object$strata$name)) {
    object$strata$label <- .get_label(object$data[[object$strata$name]]) %||% object$strata$name
  }

  # resolve and store response type ("binary", "continuous", or "count";
  # "auto" only ever resolves to "binary"/"continuous" -- "count" must be
  # declared explicitly, see `?er_plot`'s `response_type` docs)
  if (response_type == "auto") {
    response_type <- .detect_response_type(object$data[[object$response$name]])
  }
  object$response$type <- response_type

  # `response_type = "binary"` was explicitly declared but the response
  # column isn't actually confined to {0, 1} (impossible when "auto"
  # resolves to "binary", since `.detect_response_type()` already checks
  # this) -- warn, since a row with an out-of-range value is silently
  # excluded from both `n0`/`n1` in the quantile layer's rate calculation
  # (shrinking the denominator with no other indication), rather than
  # erroring or being counted
  if (object$response$type == "binary") {
    resp_vals <- object$data[[object$response$name]]
    if (!is.logical(resp_vals)) {
      n_out_of_range <- sum(!is.na(resp_vals) & !(resp_vals %in% c(0, 1)))
      if (n_out_of_range > 0) {
        rlang::warn(c(
          sprintf(
            "`response_type = \"binary\"` was declared for `%s`, but %d value%s outside {0, 1}.",
            object$response$name, n_out_of_range, if (n_out_of_range == 1) " is" else "s are"
          ),
          "i" = "Rows with an out-of-range value are silently excluded from the quantile layer's rate calculation (neither a responder nor a non-responder), shrinking the effective denominator.",
          "i" = "Pass `response_type = \"continuous\"` if this isn't actually a binary response."
        ))
      }
    }
  }

  # `response_type = "count"` was declared but the response contains a
  # negative value -- unlike the binary case above, this isn't a silent
  # exclusion, it's a genuinely broken computation: `ci_poisson()`'s
  # exact Poisson interval is undefined for a negative total (its
  # internal `qgamma()` call returns `NaN`), so this errors rather than
  # warns
  if (object$response$type == "count") {
    resp_vals <- object$data[[object$response$name]]
    n_negative <- sum(!is.na(resp_vals) & resp_vals < 0)
    if (n_negative > 0) {
      rlang::abort(c(
        sprintf(
          "`response_type = \"count\"` was declared for `%s`, but %d value%s negative.",
          object$response$name, n_negative, if (n_negative == 1) " is" else "s are"
        ),
        "i" = "A count response must be non-negative -- the exact Poisson interval used by the quantile and VPC layers (`ci_poisson()`) is undefined for a negative total.",
        "i" = "Pass `response_type = \"continuous\"` if this isn't actually a count response."
      ))
    }
  }

  # store limits
  object$exposure$limits <- range(object$data[[object$exposure$name]])
  if (object$response$type == "binary") {
    object$response$limits <- c(0, 1)
  } else {
    object$response$limits <- range(object$data[[object$response$name]], na.rm = TRUE)
  }
  if (!is.null(object$strata$name)) {
    object$strata$limits <- unique(object$data[[object$strata$name]])
  }

  # theming information
  object$theme$format_p <- scales::label_pvalue(accuracy = .001, add_p = TRUE)
  object$theme$format_percent <- scales::label_percent(accuracy = 1)
  object$theme$format_number <- scales::label_number(accuracy = 0.01)
  object$theme$height <- list(base = 6, data = 2, group = 3) 
  object$theme$theme_base <- ggplot2::theme_bw()
  object$theme$theme_extra <- ggplot2::theme(
    panel.border = ggplot2::element_rect(
      fill = NA, 
      color = "grey80", 
      linewidth = .5
    ),
    legend.position = "bottom"
  )
  object$theme$draw_key <- ggplot2::draw_key_rect
  object$theme$dodge_width <- 0.015 # deliberately narrow to avoid distortion
  object$theme$color_discrete <- NULL
  object$theme$fill_discrete <- NULL
  object$theme$color_continuous <- NULL
  object$theme$fill_continuous <- NULL
  object$theme$title <- NULL
  object$theme$subtitle <- NULL
  object$theme$caption <- NULL
 
  return(object)
}

# plot/print ------------------------------------------------------------------

#' @exportS3Method base::print
print.er_plot <- function(x, ...) {

  layer_set <- !purrr::map_lgl(x$layer, is.null)
  plot_set <- !purrr::map_lgl(x$plot, is.null)

  cat("<er_plot>\n")
  cat("  plot variables:\n")
  cat("    - exposure:        ", x$exposure$name  %||% "<none>", "\n", sep = "")
  cat("    - response:        ", x$response$name  %||% "<none>", "\n", sep = "")
  cat("    - stratification:  ", x$strata$name    %||% "<none>", "\n", sep = "")
  
  if (any(layer_set)) {
    cat("  plot layers:\n")
    if (layer_set["model"])    cat("    - model:           ", paste(class(x$layer$model$config$model), collapse = "/"), "\n", sep = "")
    if (layer_set["summary"])  cat("    - summary:         ", if (is.null(x$layer$summary$config$model)) "descriptive" else "model-derived", "\n", sep = "")
    if (layer_set["quantile"]) cat("    - quantile:        ", x$layer$quantile$config$n_quantiles, " bins\n", sep = "")
    if (layer_set["data"])     cat("    - data:            ", x$layer$data$config$layout, " ", x$layer$data$config$panel, "\n", sep = "")
    if (layer_set["overlay"])  cat("    - overlay:         ", if (x$layer$overlay$stratify) "stratified" else "unstratified", "\n", sep = "")
    if (layer_set["group"])    cat("    - group:           ", paste(names(x$layer$group$config), collapse = ", "), "\n", sep = "")
  } else {
    cat("  plot layers: <none>\n")
  }

  if (any(plot_set)) {
    cat("  plots built:\n")
    if (plot_set["base"])   cat("    - model\n", sep = "")
    if (plot_set["data"])   cat("    - data\n", sep = "")
    if (plot_set["group"])  cat("    - group\n", sep = "")
  } else {
    cat("  plots built: <none>\n")
  }

  if (is.null(x$output))  cat("  output built: no")
  if (!is.null(x$output)) cat("  output built: yes")
  
  return(invisible(x))
}

#' @exportS3Method graphics::plot
plot.er_plot <- function(x, y = NULL, ...) {
  object <- er_plot_build(x)
  plot(object$output)
}


# top level build function ----------------------------------------------------

#' Build and render an `er_plot` object
#'
#' Assembles the layers into ggplot2 objects, applies shared theming and legend
#' deduplication across layers, and composes the final output with
#' patchwork. 
#' 
#' @param object Partially constructed plot (has S3 class `er_plot`).
#'
#' @returns The input `object`, with `object$plot` (per-layer ggplot2
#'   objects) and `object$output` (the final composed plot) populated.
#' 
#' @details
#' The user does not typically invoke this function directly. Instead, it is 
#' called automatically when `plot()` is called.
#' 
#'
#' @seealso [er_plot()]
#'
#' @export
er_plot_build <- function(object) {
  if (!inherits(object, "er_plot")) rlang::abort("`object` must be an er_plot object")
  
  # build
  has_base_layer <- !is.null(object$layer$model) || !is.null(object$layer$summary) ||
    !is.null(object$layer$quantile) || !is.null(object$layer$overlay)
  has_any_layer <- has_base_layer || !is.null(object$layer$data) || !is.null(object$layer$group)

  # an er_plot with no layers at all still renders as an empty canvas
  # (axes only, no geoms) rather than erroring inside patchwork when handed
  # an empty plot list -- see `?er_plot`'s "empty plot" example
  if (has_base_layer || !has_any_layer) {
    object$plot$base <- .build_base_plot(object)
  }
  if (!is.null(object$layer$data)) object$plot$data <- .build_data_plot(object)
  if (!is.null(object$layer$group)) object$plot$group <- .build_group_plot(object)
  if (!is.null(object$layer$overlay) && !identical(.style_zorder(object$layer$overlay$config$style), "background")) {
    object$plot$base <- object$plot$base + .build_overlay_geoms(object)
  }

  # polish
  object$plot <- .polish_margins(object)
  object$plot <- .polish_labels(object)
  object$plot <- .polish_scales(object)
  composition <- .polish_arrangement(object)
  composition <- .polish_legends(object, composition)
  composition <- .polish_theme(object, composition)

  # output
  object$output <- patchwork::wrap_plots(
    composition$plots, 
    ncol = 1, 
    heights = composition$info$size,
    guides = "collect",
    axes = "collect"
  ) + patchwork::plot_annotation(
    title = object$theme$title,
    subtitle = object$theme$subtitle,
    caption = object$theme$caption,
    theme = object$theme$theme_extra
  )

  return(object)
}
