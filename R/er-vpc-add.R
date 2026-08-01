
#' Add the observed-data layer to an `er_vpc` VPC
#'
#' Bins the observed data by `group_by` and computes its response summary
#' (rate/mean + confidence interval, plus empirical percentiles for a
#' continuous/count response), for later comparison against a simulated
#' layer added via [er_vpc_add_simulated()].
#'
#' @param object Partially constructed VPC (has S3 class `er_vpc`).
#' @param group_by Variable (unquoted) used to bin/group the comparison.
#'   Defaults to the plot's own exposure variable. A numeric variable is
#'   split into `n_bins` quantile bins (placebo, i.e. `0`, kept in its own
#'   bin when `group_by` is the exposure variable itself); a categorical
#'   variable is used as-is, with no binning.
#' @param n_bins Number of quantile bins, when `group_by` is numeric.
#' @param conf_level Confidence level for the observed-side interval.
#' @param probs Percentiles to compute for the continuous-x line/ribbon
#'   builders (ignored by the default pointrange builder). Only computed
#'   for a continuous/count response binned on a numeric `group_by`.
#' @param style A function determining how the observed layer is drawn;
#'   see [er_style_vpc_observed()].
#' @param ... Additional named arguments forwarded to `style`.
#'
#' @returns `object`, with `object$layer$observed` populated.
#'
#' @seealso [er_vpc()], [er_vpc_add_simulated()], [er_style_vpc_observed()]
#'
#' @export
er_vpc_add_observed <- function(object, group_by = NULL, n_bins = 4, conf_level = 0.95,
                                 probs = c(0.1, 0.5, 0.9),
                                 style = er_style_vpc_observed_pointrange, ...) {

  dots <- rlang::list2(...)
  .check_dots_named(dots)

  if (!inherits(object, "er_vpc")) rlang::abort("`object` must be an er_vpc object.")
  if (!is.function(style)) rlang::abort("`style` must be a function.")
  .check_style_layer(style, "observed", arg = "style")

  group_quo <- rlang::enquo(group_by)
  group_var <- if (rlang::quo_is_null(group_quo)) object$exposure$name else rlang::as_name(group_quo)

  if (!(group_var %in% names(object$data))) {
    rlang::abort(sprintf("Column `%s` not found in the data used to build `object`.", group_var))
  }

  if (!is.numeric(n_bins) || length(n_bins) != 1L || !is.finite(n_bins) || n_bins < 1 || n_bins != round(n_bins)) {
    rlang::abort("`n_bins` must be a single positive whole number.")
  }

  object$layer$observed <- .layer_vpc_observed(
    object = object,
    group_var = group_var,
    n_bins = n_bins,
    conf_level = conf_level,
    probs = probs,
    style = style,
    dots = dots
  )

  return(object)
}


#' Add the simulated-data layer to an `er_vpc` VPC
#'
#' Bins simulated data using the same cutpoints [er_vpc_add_observed()]
#' already computed, and summarizes it (mean + a percentile interval
#' across replicates, plus simulated percentile bands for a
#' continuous/count response).
#'
#' @param object Partially constructed VPC (has S3 class `er_vpc`), which
#'   must already have an observed layer (see [er_vpc_add_observed()]).
#' @param model A fitted model implementing [er_simulate()] with
#'   `sim_resp`. Mutually exclusive with `sim`.
#' @param sim Simulated data with matching exposure/response/`group_by`
#'   columns and `sim_id`. Mutually exclusive with `model`.
#' @param nsim Number of simulation replicates, only used with `model`.
#' @param seed Optional RNG seed, only used with `model`.
#' @param conf_level Confidence level for the simulated-side interval.
#' @param probs Percentiles to compute for the continuous-x ribbon
#'   builder; should match whatever `probs` was passed to
#'   [er_vpc_add_observed()] (ignored by the default errorbar builder).
#' @param style A function determining how the simulated layer is drawn;
#'   see [er_style_vpc_simulated()].
#' @param ... Additional named arguments forwarded to `style`.
#'
#' @returns `object`, with `object$layer$simulated` populated.
#'
#' @details
#' `sim` and `model` are mutually exclusive; supply exactly one. `model`
#' is preferred when it implements [er_simulate()] with `sim_resp`,
#' since a VPC needs response-level simulated observations rather than
#' only mean predictions -- this function errors informatively if
#' `sim_resp` isn't available.
#'
#' @seealso [er_vpc()], [er_vpc_add_observed()], [er_style_vpc_simulated()]
#'
#' @export
er_vpc_add_simulated <- function(object, model = NULL, sim = NULL, nsim = 100, seed = NULL,
                                  conf_level = 0.95, probs = c(0.1, 0.5, 0.9),
                                  style = er_style_vpc_simulated_errorbar, ...) {

  dots <- rlang::list2(...)
  .check_dots_named(dots)

  if (!inherits(object, "er_vpc")) rlang::abort("`object` must be an er_vpc object.")
  if (is.null(object$layer$observed)) {
    rlang::abort(c(
      "`er_vpc_add_simulated()` requires an observed layer.",
      "i" = "Call `er_vpc_add_observed()` before `er_vpc_add_simulated()`."
    ))
  }
  if (!is.function(style)) rlang::abort("`style` must be a function.")
  .check_style_layer(style, "simulated", arg = "style")

  if (is.null(sim) && is.null(model)) {
    rlang::abort("Supply exactly one of `sim` or `model` to `er_vpc_add_simulated()`.")
  }
  if (!is.null(sim) && !is.null(model)) {
    rlang::abort("Supply exactly one of `sim` or `model` to `er_vpc_add_simulated()`, not both.")
  }

  rsp_var <- object$response$name

  if (!is.null(model)) {
    .check_nsim(nsim)
    raw_sim <- er_simulate(model, newdata = object$data, nsim = nsim, seed = seed)
    if (is.null(raw_sim) || !("sim_resp" %in% names(raw_sim))) {
      rlang::abort(c(
        paste0(
          "`er_simulate()` does not provide predictive simulation (a `sim_resp` column) for objects of class <",
          paste(class(model), collapse = "/"), ">."
        ),
        "i" = paste0(
          "`er_vpc_add_simulated()`'s `model` argument needs an `er_simulate()` method returning `sim_resp` ",
          "(see `?er_model_interface`) -- this is a stricter requirement than the `fit_resp`-only ",
          "simulation that suffices for `er_style_model_spaghetti()`."
        ),
        "i" = "Alternatively, pass a pre-built `sim` data frame directly."
      ))
    }
    # defensive: a model's own `er_simulate()` method controls `raw_sim`'s
    # class, not erplots -- ungroup it too in case it comes back grouped
    sim <- dplyr::ungroup(raw_sim)
    sim[[rsp_var]] <- sim[["sim_resp"]]
  } else {
    sim <- dplyr::ungroup(sim)
  }

  object$layer$simulated <- .layer_vpc_simulated(
    object = object,
    sim = sim,
    conf_level = conf_level,
    probs = probs,
    style = style,
    dots = dots
  )

  return(object)
}
