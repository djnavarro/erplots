
#' Add the observed-data layer to an `er_vpc` VPC
#'
#' Bins the observed data by `plot_by` (see [er_vpc()]) and computes its
#' response summary (rate/mean + confidence interval, plus empirical
#' percentiles for a continuous/count response), for later comparison
#' against a simulated layer added via [er_vpc_add_simulated()].
#'
#' @param object Partially constructed VPC (has S3 class `er_vpc`).
#' @param style A function determining how the observed layer is drawn;
#'   see [er_style_vpc_observed()].
#' @param ... Additional named arguments forwarded to `style`.
#'
#' @returns `object`, with `object$layer$observed` populated.
#'
#' @details `plot_by`/`n_bins`/`conf_level`/`probs` are set once on
#' [er_vpc()] itself (rather than here) so the observed and simulated
#' layers can't disagree about how the comparison is binned or
#' summarized.
#'
#' @seealso [er_vpc()], [er_vpc_add_simulated()], [er_style_vpc_observed()]
#'
#' @export
er_vpc_add_observed <- function(object, style = er_style_vpc_observed_pointrange, ...) {

  dots <- rlang::list2(...)
  .check_dots_named(dots)

  if (!inherits(object, "er_vpc")) rlang::abort("`object` must be an er_vpc object.")
  if (!is.function(style)) rlang::abort("`style` must be a function.")
  .check_style_layer(style, "observed", arg = "style")

  object$layer$observed <- .layer_vpc_observed(
    object = object,
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
#' @param sim Simulated data with matching exposure/response/`plot_by`
#'   columns and `sim_id`. Mutually exclusive with `model`.
#' @param nsim Number of simulation replicates, only used with `model`.
#' @param seed Optional RNG seed, only used with `model`.
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
#' `conf_level`/`probs` are set once on [er_vpc()] itself (rather than
#' here), so the observed and simulated layers always agree on them.
#'
#' @seealso [er_vpc()], [er_vpc_add_observed()], [er_style_vpc_simulated()]
#'
#' @export
er_vpc_add_simulated <- function(object, model = NULL, sim = NULL, nsim = 100, seed = NULL,
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
  .check_vpc_layout_match(object$layer$observed$config$style, style)

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
    style = style,
    dots = dots
  )

  return(object)
}
