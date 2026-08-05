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
