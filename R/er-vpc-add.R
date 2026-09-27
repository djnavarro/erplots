
#' Add the observed-data layer to a VPC plot
#'
#' Bins the observed data for a VPC plot and computes binned 
#' response summaries for later comparison against a simulated data layer.
#'
#' @param object Partially constructed VPC (has S3 class `er_vpc`).
#' @param style Style used to draw the VPC observed data layer. Can 
#'   either be a string corresponding to one of the registered style labels
#'   (e.g., `"mean_errorbar"`, the default), or a builder function used to 
#'   compute the relevant plot object (see "Styles" below). 
#' @param ... Additional named arguments forwarded to the `style` builder
#'   function when the plot is built.
#'
#' @returns `object`, with `object$layer$observed` populated.
#'
#' @details `plot_by`/`n_bins`/`conf_level`/`probs` are set once on
#' [er_vpc()] itself (rather than here) so the observed and simulated
#' layers can't disagree about how the comparison is binned or
#' summarized.
#'
#' @section Styles:
#' The following pre-defined styles are available for this layer. Please
#' see the documentation for the corresponding builder function to see what 
#' customisation options are available:
#' 
#' | Label | Builder | Description |
#' | --- | --- | --- |
#' | `"mean_errorbar"` | [er_style_vpc_observed_mean_errorbar()] | Mean/rate + CI per bin, x-position adaptive to `plot_by`'s type (the default). |
#' | `"quantile_line"` | [er_style_vpc_observed_quantile_line()] | One line per requested percentile against a continuous `plot_by` axis. |
#' | `"quantile_errorbar"` | [er_style_vpc_observed_quantile_errorbar()] | Point + error bar per bin and per requested percentile. |
#'
#' See [er_style_vpc()] for details on how style builder functions are 
#' defined for the VPC mini-grammar, should a custom style be required.
#'
#' @seealso [er_vpc()], [er_vpc_add_simulated()], [er_style_vpc_observed()]
#'
#' @export
er_vpc_add_observed <- function(object, style = er_style_vpc_observed_mean_errorbar, ...) {

  dots <- rlang::list2(...)
  .check_dots_named(dots)

  if (!inherits(object, "er_vpc")) rlang::abort("`object` must be an er_vpc object.")
  if (!is.function(style) && !is.character(style)) {
    rlang::abort("`style` must be a function or a registered label string.")
  }
  if (is.character(style)) style <- .lookup_style_label("vpc_observed", style, arg = "style")
  .check_style_layer(style, "vpc_observed", arg = "style")
  .check_style_response_type(style, object$response$type, arg = "style")
  .check_style_plot_by_type(style, object$group$type, arg = "style")

  object$layer$observed <- .layer_vpc_observed(
    object = object,
    style = style,
    dots = dots
  )

  return(object)
}


#' Add the simulated-data layer to a VPC plot
#'
#' Bins the simulation data for a VPC plot and computes binned 
#' response summaries for comparison against the observed data layer.
#'
#' @param object Partially constructed VPC (has S3 class `er_vpc`), which
#'   must already have an observed layer (see [er_vpc_add_observed()]).
#' @param model A fitted model implementing [er_simulate()] with
#'   `sim_resp`. Mutually exclusive with `sim`.
#' @param sim Simulated data with matching exposure/response/`plot_by`
#'   columns and `sim_id`. Mutually exclusive with `model`.
#' @param nsim Number of simulation replicates, only used with `model`.
#'   Defaults to `100`.
#' @param seed Optional RNG seed. Used for `model`'s own simulation draws,
#'   and also (regardless of whether `sim`/`model` was supplied) to seed
#'   this layer's random tie-break when [er_vpc()]'s `ties` is
#'   `"split-even"` -- see [er_vpc()]'s own `seed` argument for the
#'   observed layer's independent tie-break seed.
#' @param style Style used to draw the VPC simulation layer. Can 
#'   either be a string corresponding to one of the registered style labels
#'   (e.g., `"mean_errorbar"`, the default), or a builder function used to 
#'   compute the relevant plot object (see "Styles" below).
#' @param simulate_args A named list of additional arguments forwarded to
#'   [er_simulate()] when simulating from the model.
#' @param ... Additional named arguments forwarded to the `style` builder
#'   function when the plot is built.
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
#' @section Styles:
#' The following pre-defined styles are available for this layer. Please
#' see the documentation for the corresponding builder function to see what 
#' customisation options are available:
#' 
#' | Label | Builder | Description |
#' | --- | --- | --- |
#' | `"mean_errorbar"` | [er_style_vpc_simulated_mean_errorbar()] | Mean/rate + CI per bin, x-position adaptive to `plot_by`'s type (the default). |
#' | `"quantile_ribbon"` | [er_style_vpc_simulated_quantile_ribbon()] | One ribbon per requested percentile against a continuous `plot_by` axis. |
#' | `"quantile_errorbar"` | [er_style_vpc_simulated_quantile_errorbar()] | Point + error bar per bin and per requested percentile. |
#'
#' See [er_style_vpc()] for details on how style builder functions are 
#' defined for the VPC mini-grammar, should a custom style be required.
#'
#' @seealso [er_vpc()], [er_vpc_add_observed()], [er_style_vpc_simulated()]
#'
#' @export
er_vpc_add_simulated <- function(object, model = NULL, sim = NULL, nsim = 100, seed = NULL,
                                  style = er_style_vpc_simulated_mean_errorbar,
                                  simulate_args = list(), ...) {

  dots <- rlang::list2(...)
  .check_dots_named(dots)
  .check_dots_named(simulate_args, arg = "simulate_args")

  if (!inherits(object, "er_vpc")) rlang::abort("`object` must be an er_vpc object.")
  if (is.null(object$layer$observed)) {
    rlang::abort(c(
      "`er_vpc_add_simulated()` requires an observed layer.",
      "i" = "Call `er_vpc_add_observed()` before `er_vpc_add_simulated()`."
    ))
  }
  if (!is.function(style) && !is.character(style)) {
    rlang::abort("`style` must be a function or a registered label string.")
  }
  if (is.character(style)) style <- .lookup_style_label("vpc_simulated", style, arg = "style")
  .check_style_layer(style, "vpc_simulated", arg = "style")
  .check_style_response_type(style, object$response$type, arg = "style")
  .check_style_plot_by_type(style, object$group$type, arg = "style")
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
    raw_sim <- rlang::exec(
      er_simulate, model, newdata = object$data, nsim = nsim, seed = seed, !!!simulate_args
    )
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
    dots = dots,
    seed = seed
  )

  return(object)
}
