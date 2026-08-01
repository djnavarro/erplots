
#' The exposure-response VPC mini-language
#'
#' Create an `er_vpc` specification for a visual predictive check.
#' Build the plot by adding an observed layer and a simulated layer,
#' and render with `plot()`/`print()` or [er_vpc_build()].
#'
#' @details
#' `er_vpc_add_observed()` bins the observed data and computes its
#' response summary; `er_vpc_add_simulated()` must be added afterwards,
#' since it reuses the observed layer's own binning decision so both
#' sides share identical bin boundaries. Both layers are singletons (a
#' second call replaces the previous one).
#'
#' Unlike [er_plot()], `er_vpc()` has no stratification concept and
#' always renders a single panel -- see [er_vpc_add_observed()] for
#' `group_by`, the (orthogonal) variable used to bin/group the
#' comparison.
#'
#' @param data Data frame or tibble containing the observed data.
#' @param exposure Exposure variable (one variable, unquoted).
#' @param response Response variable (one variable, unquoted).
#' @param response_type One of `"auto"`, `"binary"`, `"continuous"`, or `"count"`.
#'
#' @returns An (empty) plot object of class `er_vpc`.
#'
#' @examples
#' if (requireNamespace("erglm", quietly = TRUE)) {
#' library(erglm)
#' mod <- erglm_model(ae2 ~ aucss + sex, erglm_data, family = binomial())
#'
#' erglm_data |>
#'   er_vpc(aucss, ae2) |>
#'   er_vpc_add_observed(group_by = aucss) |>
#'   er_vpc_add_simulated(model = mod, seed = 9984) |>
#'   plot()
#' }
#'
#' @seealso [er_vpc_add_observed()], [er_vpc_add_simulated()],
#'   [er_vpc_build()], [er_model_interface]
#'
#' @name er_vpc
NULL

#' @rdname er_vpc
#' @export
er_vpc <- function(data, exposure, response, response_type = "auto") {

  # see `er_plot()`'s identical `dplyr::ungroup()` call for the rationale
  data <- dplyr::ungroup(data)

  response_type <- match.arg(response_type, c("auto", "binary", "continuous", "count"))

  exposure_name <- rlang::as_name(rlang::enquo(exposure))
  response_name <- rlang::as_name(rlang::enquo(response))

  missing_cols <- setdiff(c(exposure_name, response_name), names(data))
  if (length(missing_cols) > 0) {
    rlang::abort(c(
      sprintf(
        "Column%s not found in `data`: %s.",
        if (length(missing_cols) > 1) "s" else "",
        paste0("`", missing_cols, "`", collapse = ", ")
      ),
      "i" = "Check that `exposure`/`response` reference actual columns of `data`."
    ))
  }

  if (!is.numeric(data[[exposure_name]])) {
    rlang::abort(c(
      sprintf(
        "`exposure` (`%s`) must be numeric, not %s.",
        exposure_name, paste(class(data[[exposure_name]]), collapse = "/")
      ),
      "i" = "erplots' quantile-binning assumes a numeric exposure axis."
    ))
  }

  object <- structure(
    list(
      data = NULL,
      exposure = .plot_variable(role = "exposure"),
      response = .plot_variable(role = "response"),
      layer = list(observed = NULL, simulated = NULL),
      theme = list(),
      output = NULL
    ),
    class = "er_vpc"
  )

  object$data <- data
  object$exposure$name <- exposure_name
  object$response$name <- response_name
  object$exposure$label <- .get_label(object$data[[object$exposure$name]]) %||% object$exposure$name
  object$response$label <- .get_label(object$data[[object$response$name]]) %||% object$response$name

  if (response_type == "auto") {
    response_type <- .detect_response_type(object$data[[object$response$name]])
  }
  object$response$type <- response_type

  .validate_response_values(object$response$type, object$data[[object$response$name]], object$response$name)

  object$exposure$limits <- range(object$data[[object$exposure$name]])
  if (object$response$type == "binary") {
    object$response$limits <- c(0, 1)
  } else {
    object$response$limits <- range(object$data[[object$response$name]], na.rm = TRUE)
  }

  object$theme$format_percent <- scales::label_percent(accuracy = 1)
  object$theme$format_number <- scales::label_number(accuracy = 0.01)
  object$theme$theme_base <- ggplot2::theme_bw()
  object$theme$theme_extra <- ggplot2::theme(
    panel.border = ggplot2::element_rect(fill = NA, color = "grey80", linewidth = .5),
    legend.position = "bottom"
  )

  return(object)
}

# plot/print ------------------------------------------------------------------

#' @exportS3Method base::print
print.er_vpc <- function(x, ...) {

  layer_set <- !purrr::map_lgl(x$layer, is.null)

  cat("<er_vpc>\n")
  cat("  plot variables:\n")
  cat("    - exposure:  ", x$exposure$name %||% "<none>", "\n", sep = "")
  cat("    - response:  ", x$response$name %||% "<none>", "\n", sep = "")

  if (any(layer_set)) {
    cat("  plot layers:\n")
    if (layer_set["observed"])  cat("    - observed:  group_by = ", x$layer$observed$config$group_var, ", ", x$layer$observed$config$n_bins, " bins\n", sep = "")
    if (layer_set["simulated"]) cat("    - simulated: ", x$layer$simulated$config$n_sim_rows, " simulated rows\n", sep = "")
  } else {
    cat("  plot layers: <none>\n")
  }

  if (is.null(x$output)) cat("  output built: no")
  if (!is.null(x$output)) cat("  output built: yes")

  return(invisible(x))
}

#' @exportS3Method graphics::plot
plot.er_vpc <- function(x, y = NULL, ...) {
  object <- er_vpc_build(x)
  plot(object$output)
}


# top level build function ----------------------------------------------------

#' Build and render an `er_vpc` object
#'
#' Assembles the observed/simulated layers into a single ggplot2 object.
#'
#' @param object Partially constructed VPC (has S3 class `er_vpc`).
#'
#' @returns The input `object`, with `object$output` (the composed
#'   ggplot2 plot) populated.
#'
#' @details
#' The user does not typically invoke this function directly. Instead, it is
#' called automatically when `plot()` is called.
#'
#' @seealso [er_vpc()]
#'
#' @export
er_vpc_build <- function(object) {
  if (!inherits(object, "er_vpc")) rlang::abort("`object` must be an er_vpc object")
  object$output <- .build_vpc_plot(object)
  return(object)
}
