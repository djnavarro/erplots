
# layer_vpc_observed -----------------------------------------------------------

.layer_vpc_observed <- function(object, style, dots = list()) {

  layer <- list()
  config <- list()

  group_var <- object$group$var
  n_bins <- object$group$n_bins
  conf_level <- object$group$conf_level
  probs <- object$group$probs

  config$group_var <- group_var
  config$n_bins <- n_bins
  config$conf_level <- conf_level
  config$probs <- probs
  config$group_label <- object$group$label

  exp_var <- object$exposure$name
  rsp_var <- object$response$name
  response_type <- object$response$type

  dat <- object$data
  config$is_numeric_group <- is.numeric(dat[[group_var]])

  if (config$is_numeric_group) {
    is_placebo <- if (group_var == exp_var) dat[[exp_var]] == 0 else rep(FALSE, nrow(dat))
    exposure_bins <- cut_exposure_quantile(dat[[group_var]], n = n_bins, is_placebo = is_placebo)
    config$breaks <- attr(exposure_bins, "breaks")
    dat$.vpc_bin <- exposure_bins
  } else {
    config$breaks <- NULL
    dat$.vpc_bin <- dat[[group_var]]
  }

  # response-type-dispatched observed summary (rate/mean + CI) -- mirrors
  # `.layer_quantile()`'s own binary/continuous/count dispatch
  if (response_type == "binary") {
    format_y_mid <- object$theme$format_percent
    summary_tbl <- dat |>
      dplyr::summarise(
        n1 = sum(.data[[rsp_var]] == 1, na.rm = TRUE),
        n0 = sum(.data[[rsp_var]] == 0, na.rm = TRUE),
        x_mid = if (config$is_numeric_group) mean(.data[[group_var]], na.rm = TRUE) else NA_real_,
        y_mid = n1 / (n0 + n1),
        ci_lower = ci_clopper_pearson(n1, n0 + n1, conf_level)["lower"],
        ci_upper = ci_clopper_pearson(n1, n0 + n1, conf_level)["upper"],
        .by = ".vpc_bin"
      ) |>
      dplyr::select(-n1, -n0)
  } else if (response_type == "count") {
    format_y_mid <- object$theme$format_number
    summary_tbl <- dat |>
      dplyr::summarise(
        n_units = sum(!is.na(.data[[rsp_var]])),
        x_mid = if (config$is_numeric_group) mean(.data[[group_var]], na.rm = TRUE) else NA_real_,
        y_mid = mean(.data[[rsp_var]], na.rm = TRUE),
        ci_lower = ci_poisson(sum(.data[[rsp_var]], na.rm = TRUE), n_units, conf_level)["lower"],
        ci_upper = ci_poisson(sum(.data[[rsp_var]], na.rm = TRUE), n_units, conf_level)["upper"],
        .by = ".vpc_bin"
      ) |>
      dplyr::select(-n_units)
  } else {
    format_y_mid <- object$theme$format_number
    summary_tbl <- dat |>
      dplyr::summarise(
        x_mid = if (config$is_numeric_group) mean(.data[[group_var]], na.rm = TRUE) else NA_real_,
        y_mid = mean(.data[[rsp_var]], na.rm = TRUE),
        ci_lower = ci_t(.data[[rsp_var]], conf_level)["lower"],
        ci_upper = ci_t(.data[[rsp_var]], conf_level)["upper"],
        .by = ".vpc_bin"
      )
  }
  summary_tbl$y_mid_lbl <- format_y_mid(summary_tbl$y_mid)
  config$summary <- summary_tbl

  # empirical response percentiles per bin, for the continuous-x
  # line/ribbon builders -- meaningful only for a continuous/count
  # response binned on a numeric `plot_by` (a categorical `plot_by`,
  # e.g. sex, has no continuous x-axis to plot percentiles against; a
  # binary response's full distribution is already captured by its rate,
  # so there's nothing more informative a percentile would show)
  config$percentiles <- NULL
  if (response_type != "binary" && config$is_numeric_group) {
    config$percentiles <- dat |>
      dplyr::reframe(
        {
          # captured as plain locals rather than referenced via `.data`
          # inside the `tibble::tibble()` call below -- `tibble()` has
          # its own `.data` pronoun (referring to columns already built
          # within that same call), which would shadow dplyr's per-group
          # data mask
          resp <- .data[[rsp_var]]
          grp <- .data[[group_var]]
          # per-percentile CI via the order-statistic method (see
          # `ci_quantile()`) -- the observed-side analogue of the
          # across-replicate percentile interval `.layer_vpc_simulated()`
          # computes from simulated data
          ci <- vapply(probs, function(p) ci_quantile(resp, p, conf_level), numeric(2))
          tibble::tibble(
            x_mid = mean(grp, na.rm = TRUE),
            prob = probs,
            y = unname(stats::quantile(resp, probs = probs, na.rm = TRUE)),
            ci_lower = ci["lower", ],
            ci_upper = ci["upper", ]
          )
        },
        .by = ".vpc_bin"
      )
  }

  config$corner_distance <- .compute_corner_distance(object$data, object$exposure, object$response)

  # `style` is the escape hatch documented in `?er_style`; `er_vpc_add_observed()`
  # has already resolved a default when the caller didn't supply one
  config$style <- style
  config$dots <- dots

  layer$config <- config
  return(layer)
}


# layer_vpc_simulated ------------------------------------------------------------

.layer_vpc_simulated <- function(object, sim, style, dots = list()) {

  layer <- list()
  config <- list()

  obs_config <- object$layer$observed$config
  group_var <- object$group$var
  conf_level <- object$group$conf_level
  probs <- object$group$probs
  exp_var <- object$exposure$name
  rsp_var <- object$response$name
  response_type <- object$response$type

  config$conf_level <- conf_level
  config$n_sim_rows <- nrow(sim)
  config$is_numeric_group <- obs_config$is_numeric_group

  # bin simulated rows against the *observed* layer's own cutpoints,
  # rather than re-deriving fresh quantiles from the simulated data --
  # see `.apply_exposure_breaks()` for why this matters
  if (obs_config$is_numeric_group) {
    is_placebo <- if (group_var == exp_var) sim[[exp_var]] == 0 else rep(FALSE, nrow(sim))
    sim$.vpc_bin <- .apply_exposure_breaks(sim[[group_var]], obs_config$breaks, is_placebo)
  } else {
    sim$.vpc_bin <- sim[[group_var]]
  }

  alpha <- (1 - conf_level) / 2
  format_y_mid <- if (response_type == "binary") object$theme$format_percent else object$theme$format_number

  # stage 1: per-replicate mean within bin; stage 2: mean + percentile
  # interval of that per-replicate quantity across replicates
  summary_tbl <- sim |>
    dplyr::summarise(
      x_mid = if (obs_config$is_numeric_group) mean(.data[[group_var]], na.rm = TRUE) else NA_real_,
      y = mean(.data[[rsp_var]], na.rm = TRUE),
      .by = c(".vpc_bin", "sim_id")
    ) |>
    dplyr::summarise(
      x_mid = if (obs_config$is_numeric_group) mean(x_mid, na.rm = TRUE) else NA_real_,
      y_mid = mean(y, na.rm = TRUE),
      ci_lower = stats::quantile(y, probs = alpha, na.rm = TRUE),
      ci_upper = stats::quantile(y, probs = 1 - alpha, na.rm = TRUE),
      .by = ".vpc_bin"
    )
  summary_tbl$y_mid_lbl <- format_y_mid(summary_tbl$y_mid)
  config$summary <- summary_tbl

  # simulated percentile bands -- same scoping as the observed side
  # (continuous/count response, numeric `plot_by` only)
  config$percentiles <- NULL
  if (response_type != "binary" && obs_config$is_numeric_group) {
    stage1 <- sim |>
      dplyr::reframe(
        x_mid = if (obs_config$is_numeric_group) mean(.data[[group_var]], na.rm = TRUE) else NA_real_,
        prob = probs,
        y = unname(stats::quantile(.data[[rsp_var]], probs = probs, na.rm = TRUE)),
        .by = c(".vpc_bin", "sim_id")
      )
    config$percentiles <- stage1 |>
      dplyr::summarise(
        x_mid = if (obs_config$is_numeric_group) mean(x_mid, na.rm = TRUE) else NA_real_,
        y_mid = stats::median(y, na.rm = TRUE),
        ci_lower = stats::quantile(y, probs = alpha, na.rm = TRUE),
        ci_upper = stats::quantile(y, probs = 1 - alpha, na.rm = TRUE),
        .by = c(".vpc_bin", "prob")
      )
  }

  # `style` is the escape hatch documented in `?er_style`; `er_vpc_add_simulated()`
  # has already resolved a default when the caller didn't supply one
  config$style <- style
  config$dots <- dots

  layer$config <- config
  return(layer)
}
