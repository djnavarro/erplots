
# part_model ------------------------------------------------------------------

.part_model <- function(object, model, stratify, conf_level, builder, summary_builder) {
  
  part_model <- list()
  config <- list()

  # the fitted model, supplied by the caller (erplots never fits models
  # itself -- see `er_model_interface`)
  config$model <- model

  # confidence level
  config$conf_level <- conf_level

  # model predictions, via the `er_predict()` generic
  config$predictions <- .get_model_predictions(
    config$model, 
    config$conf_level, 
    object$exposure, 
    object$strata, 
    stratify
  )

  # model summary (e.g. p-value), via the `er_summary()` generic. Only
  # shown when there is a single (non-stratified) curve to annotate.
  config["p_value"] <- list(NULL) # use `[` (not `$`) so the NULL is retained as a named element
  if (is.null(object$strata$name) || stratify == FALSE) {
    model_summary <- er_summary(config$model)
    config$p_value <- model_summary$p_value
  }

  # visual distance from corners (used for placement of summary). `y` is
  # rescaled onto [0, 1] using the response's own limits before computing
  # corner distances, since `fit_resp` lives on the response's scale (only
  # [0, 1] itself for a binary response) -- see `PLAN.md` Stage 0.
  response_lo <- object$response$limits[1]
  response_hi <- object$response$limits[2]
  config$corner_distance <- config$predictions |> 
    dplyr::select(dplyr::all_of(c(object$exposure$name, "fit_resp"))) |> 
    dplyr::rename(y = fit_resp, x = dplyr::all_of(object$exposure$name)) |> 
    dplyr::mutate(
      x = x / sum(x),
      y = (y - response_lo) / (response_hi - response_lo),
      tl_dist = sqrt(x^2 + (1-y)^2),
      tr_dist = sqrt((1-x)^2 + (1-y)^2),
      bl_dist = sqrt(x^2 + y^2),
      br_dist = sqrt((1-x)^2 + y^2)
    ) |> 
    dplyr::summarise(
      top_left     = min(tl_dist, na.rm = TRUE),
      top_right    = min(tr_dist, na.rm = TRUE),
      bottom_left  = min(bl_dist, na.rm = TRUE),
      bottom_right = min(br_dist, na.rm = TRUE)
    ) |> 
    unlist()  

  # `builder`/`summary_builder` are the escape hatch documented in
  # `?er_partial`: any function matching the standard `er_builder_*()`
  # signature can be plugged in without touching package internals.
  # `er_plot_add_model()` has already resolved a default when the
  # caller didn't supply one, so both are always functions here.
  config$builder <- list(model = builder, summary = summary_builder)

  # store and return
  part_model$stratify <- stratify
  part_model$config <- config

  return(part_model)
}


# part_quantile ---------------------------------------------------------------

.part_quantile <- function(object, stratify, bins, conf_level, builder) {

  part_quantile <- list()
  config <- list()

  config$n_quantiles <- bins
  config$conf_level <- conf_level

  binned <- object$data |>
    dplyr::mutate(
      response = .data[[object$response$name]],
      exposure_bins = cut_exposure_quantile(
        x = .data[[object$exposure$name]], 
        n = config$n_quantiles
      ),
      strata = .get_strata_values(.data, object$strata$name)   
    )

  # binary response: response *rate* per bin, via a Clopper-Pearson CI.
  # count response, when explicitly declared (`response_type = "count"`):
  # bin *mean*, via an exact Poisson interval (PLAN.md design decision (4)
  # fast-follow). continuous (and, when not explicitly declared "count",
  # an approximation for count) response: bin *mean*, via a t-interval --
  # see PLAN.md Stage 1. Label placement (y_lwr_lbl/y_upr_lbl/y_lbl) is
  # generalised across all branches below rather than duplicated, using
  # the response's own scale (`object$response$limits`) in place of the
  # binary-only [0, 1] assumption.
  if (object$response$type == "binary") {
    config$summary <- binned |> 
      dplyr::summarise(
        n1 = sum(response == 1, na.rm = TRUE),
        n0 = sum(response == 0, na.rm = TRUE),
        x_mid = mean(.data[[object$exposure$name]], na.rm = TRUE),
        y_mid = n1 / (n0 + n1),
        y_mid_lbl = object$style$format_percent(n1 / (n0 + n1)),
        ci_lower = ci_clopper_pearson(n1, n0 + n1, config$conf_level)["lower"], 
        ci_upper = ci_clopper_pearson(n1, n0 + n1, config$conf_level)["upper"],
        .by = c("exposure_bins", "strata")
      )
  } else if (object$response$type == "count") {
    config$summary <- binned |> 
      dplyr::summarise(
        n_units = sum(!is.na(response)),
        x_mid = mean(.data[[object$exposure$name]], na.rm = TRUE),
        y_mid = mean(response, na.rm = TRUE),
        y_mid_lbl = object$style$format_number(mean(response, na.rm = TRUE)),
        ci_lower = ci_poisson(sum(response, na.rm = TRUE), n_units, config$conf_level)["lower"], 
        ci_upper = ci_poisson(sum(response, na.rm = TRUE), n_units, config$conf_level)["upper"],
        .by = c("exposure_bins", "strata")
      ) |> 
      dplyr::select(-n_units)
  } else {
    config$summary <- binned |> 
      dplyr::summarise(
        x_mid = mean(.data[[object$exposure$name]], na.rm = TRUE),
        y_mid = mean(response, na.rm = TRUE),
        y_mid_lbl = object$style$format_number(mean(response, na.rm = TRUE)),
        ci_lower = ci_t(response, config$conf_level)["lower"], 
        ci_upper = ci_t(response, config$conf_level)["upper"],
        .by = c("exposure_bins", "strata")
      )
  }

  response_lo <- object$response$limits[1]
  response_hi <- object$response$limits[2]
  margin <- 0.05 * (response_hi - response_lo)

  config$summary <- config$summary |> 
    dplyr::mutate(
      y_lwr_lbl = ci_lower - margin,
      y_upr_lbl = ci_upper + margin,
      y_lbl = dplyr::if_else(
        (y_lwr_lbl - response_lo) > (response_hi - y_upr_lbl), 
        y_lwr_lbl, 
        y_upr_lbl
      )
    )
  
  # see `?er_partial` for the `builder` escape hatch; `er_plot_add_quantiles()`
  # has already resolved a default when the caller didn't supply one
  config$builder <- builder

  # store and return
  part_quantile$stratify <- stratify
  part_quantile$config <- config

  return(part_quantile)
}


# part_data -------------------------------------------------------------------

.part_data <- function(object, stratify, panel, builder) {

  part_data <- list()
  
  config <- list()
  config$layout <- "panel"
  config$panel <- panel
  config$seed  <- 1234L
  # `er_plot_add_data()` has already resolved `builder` (and confirmed
  # its layout is "panel") before calling here -- see `?er_partial` for
  # the `builder`/`er_builder_layout()` escape hatch
  config$builder <- builder

  # `panels` is a named list of panels to build, keyed by panel name, in
  # build order; `panel_position` records where each named panel sits
  # relative to the base plot ("above"/"below"), which the composition
  # helpers (R/er-plot-compose.R) use instead of hardcoding "upper"/"lower".
  # `color_role` tags what the layer's `colour` aesthetic means --
  # "strata" (the usual case, dispatched to via the shared strata legend)
  # or "response" (the continuous/count variant's color-encoded response
  # value, which needs its own label/legend and isn't deduplicated across
  # stratum panels) -- consumed by `.polish_labels()`/`.polish_legends()`
  # in R/er-plot-compose.R. See `PLAN.md`'s "Continuous-response data
  # strip" section.
  if (object$response$type == "binary") {
    config$color_role <- "strata"

    panels <- character(0)
    if (panel %in% c("upper", "both")) panels <- c(panels, "upper")
    if (panel %in% c("lower", "both")) panels <- c(panels, "lower")
    config$panels <- panels
    config$panel_position <- c(upper = "above", lower = "below")[panels]

  } else {
    # continuous/count response: a single panel, points colored
    # continuously by the response value, in place of the binary
    # upper/lower partition -- `er_plot_add_data()` guards `panel` to
    # "both" for this response type, since there's no upper/lower
    # partition to select from. When stratified, the color channel is
    # already spoken for by the response, so stratification becomes one
    # panel per stratum level instead (all placed "below" the base plot).
    config$color_role <- "response"

    if (stratify) {
      panels <- as.character(object$strata$limits)
    } else {
      panels <- "data"
    }
    config$panels <- panels
    config$panel_position <- stats::setNames(rep("below", length(panels)), panels)
  }

  part_data$stratify <- stratify
  part_data$config <- config 

  return(part_data)
}


# part_overlay ------------------------------------------------------------------

.part_overlay <- function(object, stratify, builder) {

  part_overlay <- list()

  config <- list()
  config$seed <- 1234L

  # unlike `.part_data()`, there's a single builder regardless of
  # response type -- `er_builder_data_overlay()` only needs to know the
  # response type to decide how much vertical jitter to apply (binary
  # responses get a small nudge so 0/1 points don't overplot into two
  # solid lines; continuous/count responses get none). `er_plot_add_data()`
  # has already resolved `builder` (and confirmed its layout is "overlay")
  # before calling here -- see `?er_partial` for the `builder`/`er_builder_layout()`
  # escape hatch.
  config$response_type <- object$response$type
  config$builder <- builder

  part_overlay$stratify <- stratify
  part_overlay$config <- config

  return(part_overlay)
}


# part_group ------------------------------------------------------------------

.part_group <- function(object, group_cols, stratify, bins, builder) {

  part_group <- list()
  part_group$stratify <- stratify
  part_group$config <- list()

  for(g in group_cols) {

    config <- list()
    # see `?er_partial` for the `builder` escape hatch; `er_plot_add_groups()`
    # has already resolved a default when the caller didn't supply one
    config$builder <- builder

    # data 
    dat <- object$data

    # create factor from continuous grouping variables
    if (is.numeric(dat[[g]])) {
      new_g <- paste0(".", g, "_quantile")
      new_g_sym <- dplyr::sym(new_g)
      if (g == object$exposure$name) {
        dat <- dat |> 
          dplyr::mutate(
            {{new_g_sym}} := .data[[g]] |> 
              cut_exposure_quantile() |> 
              .set_label(.get_label(dat[[g]]) %||% g)
          )
        
      } else {
        dat <- dat |> 
          dplyr::mutate(
            {{new_g_sym}} := .data[[g]] |> 
              cut_quantile() |> 
              .set_label(.get_label(dat[[g]]) %||% g)
          )
      }
      g <- new_g
    }

    # store the variable names used for grouping
    if (stratify)  config$groupings <- c(g, object$strata$name)
    if (!stratify) config$groupings <- g

    # store information about the y-axis variable
    config$y <- .plot_variable(
      name = g,
      label = .get_label(dat[[g]]) %||% g,
      role = paste("group", g, sep = "_")
    )

    # store sample size information (for merge into plot labels)
    config$counts <- dat |> 
      dplyr::summarise(
        n   = sum(!is.na(.data[[object$exposure$name]])),
        lbl = paste0("N=", n),
        .by = config$groupings
      ) |> 
      dplyr::mutate(lvl = paste0(.data[[g]], " (", lbl, ")")) |> 
      dplyr::arrange(.data[[g]])

    # store the number of groups plotted on the y-axis
    config$n_groups <- nrow(config$counts)

    # store a modified data set to use for plotting
    config$data <- dat |> 
      dplyr::select(dplyr::all_of(c(config$groupings, object$exposure$name))) |> 
      dplyr::left_join(config$counts, by = config$groupings)
    
    part_group$config[[g]] <- config
  }

  return(part_group)
}


# miscellaneous helpers -------------------------------------------------------

.plot_variable <- function(name = NULL, label = NULL, limits = NULL, role = NULL, type = NULL) {
  list(name = name, label = label, limits = limits, role = role, type = type)
}

.get_strata_values <- function(data, name) {
  if (is.null(name)) return(NA)
  data[[name]]
}

.get_model_predictions <- function(model, conf_level, exposure, strata, stratify) {

  pred_dat <- seq(exposure$limits[1], exposure$limits[2], length.out = 300L) |> 
    data.frame() |> .set_names(exposure$name)
  
  if (stratify) pred_dat <- pred_dat |> 
    dplyr::cross_join(data.frame(strata$limits) |> .set_names(strata$name))

  model_predictions <- er_predict(model = model, newdata = pred_dat, conf_level = conf_level)
  return(model_predictions)
}
