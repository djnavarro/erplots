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
#' @noRd
.layer_tte_risktable <- function(object, style, dots, times, n_times) {
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

  config <- list(table = table, breaks = breaks)
  list(config = config, style = style, dots = dots)
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
# `?er_model_interface`'s "Details". When `object$strata$type ==
# "continuous"`, the values used are the already quantile-binned levels
# stored on `.er_tte_strata` (the same levels the curve/censor/pvalue
# layers show), not the raw numeric variable -- a documented
# approximation, the TTE-grammar analogue of `er_vpc()`'s own numeric
# `stratify_by` binning.
#' @noRd
.layer_tte_model <- function(object, model, stratify, conf_level, time_grid, predict_args, style, dots) {
  config <- list()

  time_grid <- time_grid %||% seq(object$time$limits[1], object$time$limits[2], length.out = 100L)

  if (!stratify) {
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
  config$conf_level <- conf_level
  config$predictions <- rlang::exec(
    er_predict_survival, model = model, newdata = newdata,
    time_grid = time_grid, conf_level = conf_level, !!!predict_args
  )

  list(config = config, style = style, dots = dots)
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
