
#' Model interface for exposure-response plots
#'
#' `erplots` draws exposure-response plots from fitted models that implement this small interface, rather than assuming a particular model class. Implement `er_predict()` for basic plotting support; implement `er_simulate()` for simulation-based visualisations; implement `er_summary()` for summary annotations; implement `er_predict_survival()` for a parametric survival-curve overlay in the `er_tte()` grammar ([er_tte_add_model()]).
#'
#' @param model A fitted exposure-response model object.
#' @param newdata A data frame of covariate values at which to predict.
#'   For `er_predict_survival()`, one row per covariate profile (e.g. one
#'   per stratum level) -- it does *not* include a time column; times
#'   come from `time_grid` instead (see "Details").
#' @param conf_level Confidence level for the prediction interval.
#' @param nsim Number of simulation replicates.
#' @param seed Optional RNG seed.
#' @param ... Passed to methods.
#'
#' @details
#' `er_plot_add_model()` does not verify that `model` was fit on the same exposure/response variables as the plot; that compatibility is the caller's responsibility. When `er_plot_add_model()` builds `newdata`, it always includes the exposure and, if stratified, strata variables, plus reference values for any other covariates in the model's original fitting data.
#'
#' A method may rely on caller-supplied extra arguments being forwarded through `...`: [er_plot_add_model()]'s `predict_args`, [er_plot_add_summary()]'s `summary_args`, and [er_vpc_add_simulated()]'s `simulate_args` are each spliced into the corresponding generic call (`er_predict()`/`er_summary()`/`er_simulate()` respectively), so a model-specific argument beyond the fixed contract below (e.g. a landmark time for a time-to-event model) has a documented path to reach the method. These are deliberately kept separate from each `er_plot_add_*()`/`er_vpc_add_*()` function's own `...`, which is reserved for the `style` builder instead (see [er_style()]'s "Passing extra arguments to a builder" section) -- a method should not assume it receives anything passed via that `...`.
#'
#' `er_predict()` should return `newdata` with `fit_resp`, `ci_lower`, and `ci_upper`. `er_simulate()` should return `newdata` replicates with `sim_id` and `fit_resp`; it may additionally return `sim_resp` for response-level simulations. `er_summary()` should return `NULL` or a named list with optional keys such as `p_value`, `coefficients`, and `glance`.
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
#'
#'   A method may *additionally* return a `sim_resp` column: a full
#'   response-scale draw for that replicate/observation, reflecting both
#'   parameter uncertainty (as `fit_resp` already does) and
#'   observation-level sampling/residual noise (e.g. a 0/1 draw for a
#'   binary response, an integer draw for a count response, a draw
#'   including residual variance for a continuous response) -- not just
#'   the fitted mean/probability. This is what [er_vpc_add_simulated()]'s
#'   `model` argument requires: a visual predictive check needs simulated
#'   observations comparable to the actually observed data, not points on
#'   the mean curve, which is a genuinely different question from the one
#'   `fit_resp` (used by [er_style_model_spaghetti()]) answers. `sim_resp`
#'   is independently optional -- a method can supply `fit_resp` alone (as
#'   every implementation did before `sim_resp` existed, and as remains
#'   sufficient for spaghetti plots), or both columns from the same call.
#'   [er_vpc_add_simulated()] treats a `sim_resp`-less result the same way
#'   it treats an outright `NULL`: "predictive simulation not available
#'   for this model."
#' - `er_summary()` returns `NULL` (nothing available -- the default method's
#'   behaviour), or a named list with any of the following independently
#'   optional keys. Unrecognised keys are permitted and ignored by built-in
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
#' - `er_predict_survival()` returns `newdata`, cross-joined with
#'   `time_grid` (one row per `newdata` row x `time_grid` value), with
#'   three additional columns: `time`, `fit_survival` (the point estimate
#'   of `S(time | newdata row)`), `ci_lower`, and `ci_upper`. Unlike
#'   `er_predict()`, `newdata` here never includes a time/exposure
#'   column itself -- `time_grid` is a separate argument, so a method can
#'   build the full time grid in one call per covariate profile rather
#'   than being handed a pre-crossed data frame. There is no default
#'   method that returns `NULL`; a model with no survival-curve support
#'   should simply not implement this generic, and [er_tte_add_model()]
#'   errors informatively (via the default method above) if called with
#'   one.
#'
#' @details
#' Strata membership for `er_predict_survival()` is carried on `newdata`
#' as an ordinary column (named after the `er_tte()` object's own
#' `stratify_by` variable), the same way [er_plot_add_model()]'s
#' `newdata` carries strata -- it is never implicit in `model` itself.
#' [er_tte_add_model()] builds one `newdata` row per stratum level (or a
#' single row, unstratified), filling any other covariate the model
#' references with a reference value exactly as [er_plot_add_model()]
#' already does (see its "Details").
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

#' @rdname er_model_interface
#' @param time_grid Numeric vector of times at which to predict `S(t)`.
#' @export
er_predict_survival <- function(model, newdata, time_grid, conf_level = 0.95, ...) {
  UseMethod("er_predict_survival")
}

#' @export
er_predict_survival.default <- function(model, newdata, time_grid, conf_level = 0.95, ...) {
  rlang::abort(c(
    paste0("No `er_predict_survival()` method is available for objects of class <", paste(class(model), collapse = "/"), ">."),
    "i" = "Implement `er_predict_survival.<class>()` so erplots knows how to generate a survival-curve prediction for `er_tte_add_model()`."
  ))
}
