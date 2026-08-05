# Internal layer-assembly helpers for the TTE grammar (`er_tte()`).
# Mirrors `R/er-plot-layer.R`/`R/er-vpc-layer.R`'s role: this is where a
# plot's raw Kaplan-Meier fit (already computed once, in `er_tte()`
# itself, and stored on `object$km`) gets turned into the `config` a
# style builder receives. No `er_predict()`/`er_simulate()`/`er_summary()`
# calls happen here -- nothing in this grammar (yet) is a model layer.

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
