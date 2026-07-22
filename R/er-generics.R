
#' Model interface for exposure-response plots
#'
#' `erplots` draws exposure-response plots from *any* fitted model that
#' implements this small interface, rather than assuming a particular model
#' class (e.g. a logistic regression `glm`). To make a model usable with
#' [er_plot_add_model()] and friends, implement at least a method for
#' [er_predict()]. Implementing [er_simulate()] additionally enables
#' simulation-based visualisations (e.g. spaghetti plots, VPCs); implementing
#' [er_summary()] enables annotations such as p-value labels.
#'
#' @param model A fitted exposure-response model object
#' @param newdata A data frame of covariate values at which to predict
#' @param conf_level Confidence level for the prediction interval
#' @param nsim Number of simulation replicates
#' @param seed Optional RNG seed
#' @param ... Passed to methods
#'
#' @returns
#' - `er_predict()` returns `newdata` with three additional columns:
#'   `fit_resp` (point prediction), `ci_lower`, and `ci_upper`.
#' - `er_simulate()` returns a data frame containing `nsim` replicates of
#'   `newdata`, with a `sim_id` column identifying each replicate, and a
#'   `fit_resp` column giving the simulated prediction for that replicate
#'   (reflecting parameter uncertainty). Models that cannot support
#'   simulation-based visualisation should not implement a method; the
#'   default method returns `NULL`; callers should treat a `NULL` result
#'   as "not available" rather than an error.
#' - `er_summary()` returns `NULL` (nothing available -- the default method's
#'   behaviour), or a named list with any of the following independently
#'   optional keys. Unrecognized keys are permitted and ignored by built-in
#'   builders, giving a model package room to stash extra fields for its own
#'   custom builders.
#'   - `p_value`: a single headline p-value (or `NULL`) for "the" exposure
#'     effect, when the model has one unambiguous candidate (e.g. a GLM's
#'     exposure coefficient). A model with no single privileged parameter
#'     (e.g. a multi-parameter nonlinear Emax model, with separate `E0`/
#'     `Emax`/`EC50`/`Hill` terms and no obviously "the" effect) should
#'     return `NULL` here rather than picking an arbitrary term --
#'     [er_style_summary_pvalue()] already treats `NULL` as "nothing to
#'     show".
#'   - `coefficients`: a tibble/data frame with one row per model parameter,
#'     for builders (e.g. [er_style_summary_coefficients()]) that display
#'     more than a single p-value. Columns follow this package's snake_case
#'     convention rather than `broom::tidy()`'s dotted names:
#'     `term` (required), `label` (optional display name, falls back to
#'     `term`), `estimate` (required), and optional `std_error`,
#'     `statistic`, `p_value`, `conf_low`, `conf_high` (each `NA` if not
#'     computed/meaningful). `NULL` if not available.
#'   - `glance`: a single-row tibble/data frame of model-level
#'     goodness-of-fit, `broom::glance()`-style: optional `n`,
#'     `df_residual`, `logLik`, `aic`, `bic`, `deviance`, `r_squared`
#'     (`NA` where not meaningful, e.g. non-Gaussian models),
#'     `converged`. Reserved for future builders; no built-in builder
#'     currently consumes it. `NULL` if not available.
#'
#'   This is purely additive: a method that only ever returns
#'   `list(p_value = ...)` (as above) continues to work unchanged.
#'
#' @name er_model_interface
NULL

#' @rdname er_model_interface
#' @export
er_predict <- function(model, newdata, conf_level = 0.95, ...) {
  UseMethod("er_predict")
}

#' @export
er_predict.default <- function(model, newdata, conf_level = 0.95, ...) {
  rlang::abort(c(
    paste0("No `er_predict()` method is available for objects of class <", paste(class(model), collapse = "/"), ">."),
    "i" = "Implement `er_predict.<class>()` so erplots knows how to generate model predictions and confidence intervals."
  ))
}

#' @rdname er_model_interface
#' @export
er_simulate <- function(model, newdata, nsim = 100, seed = NULL, ...) {
  UseMethod("er_simulate")
}

#' @export
er_simulate.default <- function(model, newdata, nsim = 100, seed = NULL, ...) {
  NULL
}

#' @rdname er_model_interface
#' @export
er_summary <- function(model, ...) {
  UseMethod("er_summary")
}

#' @export
er_summary.default <- function(model, ...) {
  NULL
}
