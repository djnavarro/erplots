
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
#' `er_vpc()`'s own stratification (`stratify_by`) is real, but simpler
#' than [er_plot()]'s: a facet-only split via `ggplot2::facet_wrap()`,
#' with no colour/facet precedence rule to reconcile (see `stratify_by`
#' below). It's orthogonal to `plot_by` -- see [er_vpc_add_observed()]
#' for `plot_by`, the variable plotted on the x-axis and used to
#' bin/group the comparison. Whether `plot_by` is `"continuous"`
#' (numeric, quantile-binned) or `"discrete"` (used as-is) is
#' auto-detected from the column's type and stored on
#' `object$group$type`, mirroring how `object$response$type` records
#' the response's type.
#'
#' @param data Data frame or tibble containing the observed data.
#' @param exposure Exposure variable (one variable, unquoted).
#' @param response Response variable (one variable, unquoted).
#' @param response_type One of `"auto"` (the default), `"binary"`,
#'   `"continuous"`, or `"count"`.
#' @param plot_by Variable (unquoted) plotted on the x-axis and used to
#'   bin/group the observed vs. simulated comparison. Defaults to
#'   `exposure`. A numeric variable is split into `n_bins` quantile bins
#'   (placebo, i.e. `0`, kept in its own bin when `plot_by` is the
#'   exposure variable itself); a categorical variable is used as-is,
#'   with no binning.
#' @param n_bins Number of quantile bins, when `plot_by` is numeric.
#'   Defaults to `4`.
#' @param ties,quantile_type,labeller Control how a numeric `plot_by` is
#'   split into quantile bins -- passed straight through to
#'   [cut_exposure_quantile()], see its documentation for what each
#'   controls. Set here, on `er_vpc()` itself, rather than on
#'   [er_vpc_add_observed()]/[er_vpc_add_simulated()], because the two
#'   layers must always agree on how `plot_by` is binned --
#'   `er_vpc_add_simulated()` reuses these exact settings (via
#'   [cut_exposure_quantile()]'s attributes on the observed layer's own
#'   binned column) rather than re-resolving them, so both sides always
#'   stay in sync.
#' @param stratify_by Optional variable (unquoted) splitting the VPC into
#'   one facet panel per level, via `ggplot2::facet_wrap()`, used as-is.
#'   Must be discrete -- a numeric column errors; bin it yourself first
#'   with [cut_quantile()]/[cut_exposure_quantile()] and pass the
#'   resulting factor, for full control over bin count/tie-breaking/labels.
#'   Must resolve to a different variable than `plot_by`. Defaults to
#'   `NULL` (no faceting, a single panel, matching prior behaviour).
#' @param conf_level Confidence level for both the observed- and
#'   simulated-side intervals. Must be strictly between 0 and 1.
#'   Defaults to `0.95`.
#' @param probs Percentiles to compute for a percentile-based builder
#'   (e.g. [er_style_vpc_observed_quantile_line()]/[er_style_vpc_simulated_quantile_ribbon()]/
#'   [er_style_vpc_observed_quantile_errorbar()]/[er_style_vpc_simulated_quantile_errorbar()];
#'   ignored by the default adaptive mean/errorbar pair). Only computed
#'   for a continuous/count response. Defaults to `c(0.1, 0.5, 0.9)`.
#' @param seed Optional single number seeding the observed layer's random
#'   tie-break when `ties` is `"split-even"` (ignored otherwise). `NULL`
#'   (the default) draws from the ambient RNG stream. The simulated
#'   layer's own `"split-even"` tie-break is instead seeded by
#'   [er_vpc_add_simulated()]'s own `seed` argument -- the two are
#'   independent random draws over different data (the observed rows vs.
#'   the, typically larger, simulated replicate pool), so each is seeded
#'   by the call that actually performs it.
#'
#' @returns An (empty) plot object of class `er_vpc`.
#'
#' @examples
#' if (requireNamespace("erglm", quietly = TRUE)) {
#' library(erglm)
#' mod <- erglm_model(ae2 ~ aucss + sex, erglm_data, family = binomial())
#'
#' erglm_data |>
#'   er_vpc(aucss, ae2, plot_by = aucss) |>
#'   er_vpc_add_observed() |>
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
er_vpc <- function(data, exposure, response, response_type = "auto",
                    plot_by = NULL, n_bins = 4,
                    ties = "upward", quantile_type = 7, labeller = NULL,
                    stratify_by = NULL,
                    conf_level = 0.95, probs = c(0.1, 0.5, 0.9), seed = NULL) {

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

  group_quo <- rlang::enquo(plot_by)
  group_var <- if (rlang::quo_is_null(group_quo)) exposure_name else rlang::as_name(group_quo)

  if (!(group_var %in% names(data))) {
    rlang::abort(sprintf("Column `%s` not found in `data`.", group_var))
  }

  if (!is.numeric(n_bins) || length(n_bins) != 1L || !is.finite(n_bins) || n_bins < 1 || n_bins != round(n_bins)) {
    rlang::abort("`n_bins` must be a single positive whole number.")
  }
  ties <- match.arg(ties, c("upward", "downward", "split-even"))

  strata_quo <- rlang::enquo(stratify_by)
  strata_var <- if (rlang::quo_is_null(strata_quo)) NULL else rlang::as_name(strata_quo)

  if (!is.null(strata_var)) {
    if (!(strata_var %in% names(data))) {
      rlang::abort(sprintf("Column `%s` not found in `data`.", strata_var))
    }
    if (identical(strata_var, group_var)) {
      rlang::abort(c(
        sprintf("`stratify_by` (`%s`) resolves to the same variable as `plot_by`.", strata_var),
        "i" = "Faceting by the same variable already used for x-axis binning would give each panel a single bin."
      ))
    }
  }
  .check_stratify_by_discrete(data, strata_var)

  if (!is.numeric(conf_level) || length(conf_level) != 1L || !is.finite(conf_level) || conf_level <= 0 || conf_level >= 1) {
    rlang::abort("`conf_level` must be a single number strictly between 0 and 1.")
  }

  object <- structure(
    list(
      data = NULL,
      exposure = .plot_variable(role = "exposure"),
      response = .plot_variable(role = "response"),
      group = list(),
      strata = NULL,
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

  object$group$var <- group_var
  object$group$label <- .get_label(object$data[[group_var]]) %||% group_var
  object$group$type <- if (is.numeric(object$data[[group_var]])) "continuous" else "discrete"
  object$group$n_bins <- n_bins
  object$group$ties <- ties
  object$group$quantile_type <- quantile_type
  object$group$labeller <- labeller
  object$group$conf_level <- conf_level
  object$group$probs <- probs
  # this call's own randomness (the observed side's `ties = "split-even"`
  # tie-break only -- see `er_vpc_add_simulated()`'s own `seed` for the
  # simulated side's) -- lives on `object$group` alongside the rest of
  # this binning config rather than a new top-level field
  object$group$seed <- seed

  if (!is.null(strata_var)) {
    object$strata <- list()
    object$strata$var <- strata_var
    object$strata$label <- .get_label(object$data[[strata_var]]) %||% strata_var
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
  cat("    - plot_by:   ", x$group$var %||% "<none>", " (", x$group$type %||% "<none>", "), ",
    x$group$n_bins %||% "<none>", " bins\n", sep = "")
  if (!is.null(x$strata)) {
    cat("    - stratify_by: ", x$strata$var, "\n", sep = "")
  }

  if (any(layer_set)) {
    cat("  plot layers:\n")
    if (layer_set["observed"])  cat("    - observed:  layer built\n", sep = "")
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
