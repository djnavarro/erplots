# Internal layer-assembly helpers for the TTE grammar (`er_tte()`).
# Mirrors `R/er-plot-layer.R`/`R/er-vpc-layer.R`'s role: this is where a
# plot's raw Kaplan-Meier fit (already computed once, in `er_tte()`
# itself, and stored on `object$km`) gets turned into the `config` a
# style builder receives. No `er_predict()`/`er_simulate()`/`er_summary()`
# calls happen here -- the curve/censor/risktable/pvalue layers all read
# from the shared KM fit. `.layer_tte_model()` (below) is the one
# exception: it calls `er_predict_survival()` on the caller-supplied
# `model`, mirroring `R/er-plot-layer.R`'s own `.layer_model()`.

# Prepends a `time = 0, surv = 1` origin row -- one per stratum, when
# stratified -- to a tidy KM table (`.tidy_survfit()`'s output), so a
# plotted curve starts at the usual Kaplan-Meier `(0, 1)` origin rather
# than at the first observed event/censoring time.
#' @noRd
.add_km_origin <- function(km_table, strata) {
  if (is.null(strata)) {
    origin <- tibble::tibble(
      time = 0, n_risk = NA_real_, n_event = NA_real_, n_censor = NA_real_,
      surv = 1, lower = 1, upper = 1
    )
    return(dplyr::bind_rows(origin, km_table) |> dplyr::arrange(time))
  }

  strata_levels <- unique(km_table$strata)
  origin <- tibble::tibble(
    strata = strata_levels, time = 0, n_risk = NA_real_, n_event = NA_real_,
    n_censor = NA_real_, surv = 1, lower = 1, upper = 1
  )
  dplyr::bind_rows(origin, km_table) |> dplyr::arrange(strata, time)
}

# curve -----------------------------------------------------------------------

# Assembles the `curve` layer's config: the KM table with its `(0, 1)`
# origin row(s) prepended, and the time-axis upper limit a step-shaped
# confidence ribbon's final interval needs to extend to (there's no
# "next event time" for the last interval to stop at, unlike every
# earlier interval).
#
# `config$time_upper` is recomputed at build time by
# `.refresh_tte_time_upper()` (see issue #18), so this add-time value is
# only ever a snapshot for what would otherwise be an unpopulated field
# between `er_tte_add_curve()` and the first `er_tte_build()` call.
#' @noRd
.layer_tte_curve <- function(object, style, dots) {
  config <- list()
  config$table <- .add_km_origin(object$km$table, object$strata)
  config$time_upper <- object$time$limits[2]
  config$conf_level <- object$km$conf_level
  list(config = config, style = style, dots = dots)
}

# censor ------------------------------------------------------------------

# Assembles the `censor` layer's config: the subset of the KM table's
# rows where a censoring event actually occurred (`n_censor > 0`), read
# directly off `object$km$table` -- unlike `.layer_tte_curve()`, no
# `(0, 1)` origin row is needed here, since censoring at time 0 isn't a
# thing a tick mark needs to represent. A censoring-only row's `surv`
# value is already the survival curve's current step height (KM
# survival only changes at an *event* time, not a censoring time), so
# plotting a tick at `(time, surv)` lands it exactly on the curve.
#' @noRd
.layer_tte_censor <- function(object, style, dots) {
  config <- list()
  config$table <- object$km$table |> dplyr::filter(n_censor > 0)
  list(config = config, style = style, dots = dots)
}

# risktable -----------------------------------------------------------------

# Default time breaks for the risktable layer, when the caller doesn't
# supply `times` explicitly: `pretty()`'s usual axis-break algorithm,
# clipped to `time$limits` (`pretty()` commonly proposes a point just
# past the requested range's upper end, which `survival::summary.survfit()`
# would then have to extrapolate beyond the fit -- harmless with
# `extend = TRUE`, but a break with no visual meaning past the curve's
# own x-axis limit). Falls back to the two range endpoints themselves if
# clipping happens to leave fewer than 2 points (a degenerate/very
# narrow time range).
#' @noRd
.default_risktable_times <- function(time_limits, n_times) {
  breaks <- pretty(time_limits, n = n_times)
  breaks <- breaks[breaks >= time_limits[1] & breaks <= time_limits[2]]
  if (length(breaks) < 2) breaks <- time_limits
  breaks
}

# Assembles the `risktable` layer's config: a `time`/`n_risk` table (one
# row per stratum per requested time break, when stratified) read from
# `summary.survfit(object$km$fit, times = breaks, extend = TRUE)` --
# `extend = TRUE` guarantees a row at every requested break for every
# stratum, even past that stratum's own last observed time (where it
# would otherwise be silently dropped), so every panel row has the same
# set of x-positions to plot at.
#
# `times`/`n_times` (the caller's own, possibly-`NULL`, arguments) are
# stashed on `config` so `.refresh_tte_risktable_breaks()` (called from
# `er_tte_build()`, see issue #18) can recompute `breaks`/`table` against
# whatever `object$time$limits` looks like at build time, rather than
# being stuck with the snapshot taken here. An explicit `times` is never
# regenerated -- only the `NULL` (default-breaks) case depends on
# `time$limits` at all.
#' @noRd
.layer_tte_risktable <- function(object, style, dots, times, n_times) {
  config <- .compute_tte_risktable_config(object, times, n_times)
  config$times_arg <- times
  config$n_times <- n_times
  list(config = config, style = style, dots = dots)
}

# Shared by `.layer_tte_risktable()` (add-time) and
# `.refresh_tte_risktable_breaks()` (build-time, see issue #18) -- the
# actual `breaks`/`table` computation, factored out so both call sites
# stay in sync.
#' @noRd
.compute_tte_risktable_config <- function(object, times, n_times) {
  breaks <- times %||% .default_risktable_times(object$time$limits, n_times)
  breaks <- sort(unique(breaks))

  fit_summary <- summary(object$km$fit, times = breaks, extend = TRUE)

  if (is.null(object$strata)) {
    table <- tibble::tibble(time = fit_summary$time, n_risk = fit_summary$n.risk, strata = "All")
  } else {
    table <- tibble::tibble(
      time    = fit_summary$time,
      n_risk  = fit_summary$n.risk,
      strata  = sub("^[^=]+=", "", as.character(fit_summary$strata))
    )
  }

  list(table = table, breaks = breaks)
}

# model ---------------------------------------------------------------------

# Assembles the `model` layer's config: a `newdata` prediction grid (one
# row per stratum level, or a single row unstratified, crossed with a
# `time_grid` spanning `object$time$limits` inside `er_predict_survival()`
# itself -- unlike `.get_model_predictions()`'s `er_plot()` analogue,
# `time_grid` is a separate generic argument, not a `newdata` column, so
# no cross-join happens here), the model's survival predictions (via
# `er_predict_survival()`), and `conf_level`.
#
# Strata membership is carried on `newdata` as a column named after
# `object$strata$var` (never implicit in `model`) -- see
# `?er_model_interface`'s "Details". The values used are `.er_tte_strata`'s
# own levels (the same levels the curve/censor/pvalue layers show), i.e.
# `stratify_by`'s own discrete levels -- `stratify_by` is required to be
# discrete (see `?er_tte`), so there's no numeric-variable case to
# approximate here.
#
# `model`/`stratify`/`predict_args`/`time_grid` (the caller's own,
# possibly-`NULL`, `time_grid` argument) are all stashed on `config` so
# `.refresh_tte_model_predictions()` (called from `er_tte_build()`, see
# issue #18 -- the TTE-grammar analogue of `er_plot()`'s own
# `.refresh_model_predictions()`/issue #14) can recompute
# `config$predictions` against whatever `object$time$limits` looks like
# at build time, rather than being stuck with the snapshot taken here.
# An explicit `time_grid` is never regenerated -- only the `NULL`
# (default-grid) case depends on `time$limits` at all. This is still an
# eager, add-time computation purely so a bad `model`/`predict_args`
# combination fails immediately at the `er_tte_add_model()` call site
# rather than silently, much later, inside `plot()`/`print()`; the value
# computed here is unconditionally replaced by
# `.refresh_tte_model_predictions()` at build time, so it never actually
# reaches a builder.
#' @noRd
.layer_tte_model <- function(object, model, stratify, conf_level, time_grid, predict_args, style, dots) {
  config <- list()

  config$model <- model
  config$stratify <- stratify
  config$conf_level <- conf_level
  config$predict_args <- predict_args
  config$time_grid_arg <- time_grid

  config <- .compute_tte_model_config(object, config)

  list(config = config, style = style, dots = dots)
}

# Shared by `.layer_tte_model()` (add-time) and
# `.refresh_tte_model_predictions()` (build-time, see issue #18) -- the
# actual `newdata`/prediction computation, factored out so both call
# sites stay in sync. `config` must already carry `model`/`stratify`/
# `conf_level`/`predict_args`/`time_grid_arg`; this fills in (or
# recomputes) `config$time_grid`/`config$predictions`.
#' @noRd
.compute_tte_model_config <- function(object, config) {
  time_grid <- config$time_grid_arg %||% seq(object$time$limits[1], object$time$limits[2], length.out = 100L)

  if (!config$stratify) {
    newdata <- data.frame(matrix(nrow = 1, ncol = 0))
  } else {
    strata_levels <- levels(factor(object$data[[".er_tte_strata"]]))
    newdata <- data.frame(strata_levels) |> .set_names(object$strata$var)
  }

  # a fitted model's formula may reference covariates beyond the strata
  # variable -- fill every other column of the original fitting data
  # with a single reference value, exactly like `er_plot_add_model()`'s
  # `.get_model_predictions()` does (see its comment for the rationale)
  newdata <- .fill_reference_covariates(newdata, object$data)

  config$time_grid <- time_grid
  config$predictions <- rlang::exec(
    er_predict_survival, model = config$model, newdata = newdata,
    time_grid = time_grid, conf_level = config$conf_level, !!!config$predict_args
  )

  config
}


# pvalue ------------------------------------------------------------------

# Assembles the `pvalue` layer's config: a log-rank test comparing all
# strata (`survival::survdiff()`, the standard chi-squared log-rank
# statistic on `length(strata) - 1` degrees of freedom), plus the same
# per-corner "how uncrowded is this corner" metric
# `.layer_summary()`/`.layer_quantile()` use in the `er_plot()` grammar,
# computed here from the survival curve's own `(time, surv)` coordinates
# (rescaled via `time$limits`/`c(0, 1)`) rather than raw exposure/response
# data -- there is no raw per-subject scatter to avoid in this grammar,
# but the curve itself is exactly what a corner-placed annotation risks
# overlapping.
#' @noRd
.layer_tte_pvalue <- function(object, style, dots) {
  config <- list()

  lr_formula <- stats::reformulate(
    termlabels = ".er_tte_strata",
    response = "survival::Surv(.er_tte_time, .er_tte_event)"
  )
  lr <- survival::survdiff(lr_formula, data = object$data)
  lr_df <- length(lr$n) - 1
  config$p_value <- stats::pchisq(lr$chisq, df = lr_df, lower.tail = FALSE)

  config$corner_distance <- .compute_corner_distance(
    data = object$km$table,
    exposure = list(name = "time", limits = object$time$limits),
    response = list(name = "surv", limits = c(0, 1))
  )

  list(config = config, style = style, dots = dots)
}


# build-time refreshes (issue #18) -----------------------------------------

# `object$time$limits` is structural: `er_tte_theme(xlim = ...)`
# overwrites it directly (unlike `er_plot()`'s `exposure$limits`/
# `er_vpc()`'s purely cosmetic `theme$xlim`). Three layers cache a value
# derived from it at *add* time -- the curve layer's `time_upper`, the
# model layer's default `time_grid`, and the risktable layer's default
# `breaks` (which also become the curve panel's shared x-axis ticks, see
# `er_tte_build()`) -- and none of them used to be revisited if
# `er_tte_theme(xlim = ...)` was called afterward. Narrowing turned out
# to be self-correcting (`er_tte_build()` uses hard
# `ggplot2::scale_x_continuous(limits = ...)`, not
# `coord_cartesian(clip = "off")`, so ggplot2's own scale mechanism drops
# and warns about the overflow), but *widening* was genuinely silent: the
# curve's confidence ribbon, the model curve/ribbon, and the risktable's
# reported time points all simply stopped at the old, narrower boundary,
# leaving the rest of the widened panel blank with no warning at all.
#
# These three functions are called unconditionally from the top of
# `er_tte_build()`, mirroring `er_plot_build()`'s own
# `.refresh_model_predictions()` (issue #14) -- each is a no-op when its
# layer isn't present, and recomputing is cheap (no model refit; at most
# a fresh `er_predict_survival()` prediction call or a `summary.survfit()`
# call against the already-computed KM fit), so this keeps
# `er_tte_theme(xlim = ...)`'s effect on every time-dependent default
# order-independent regardless of whether it's called before or after
# the layer that reads it.

#' @noRd
.refresh_tte_time_upper <- function(object) {
  if (is.null(object$layer$curve)) return(object)
  object$layer$curve$config$time_upper <- object$time$limits[2]
  object
}

#' @noRd
.refresh_tte_model_predictions <- function(object) {
  layer <- object$layer$model
  if (is.null(layer)) return(object)

  layer$config <- .compute_tte_model_config(object, layer$config)
  object$layer$model <- layer
  object
}

#' @noRd
.refresh_tte_risktable_breaks <- function(object) {
  layer <- object$layer$risktable
  if (is.null(layer)) return(object)

  refreshed <- .compute_tte_risktable_config(object, layer$config$times_arg, layer$config$n_times)
  layer$config$table  <- refreshed$table
  layer$config$breaks <- refreshed$breaks
  object$layer$risktable <- layer
  object
}
