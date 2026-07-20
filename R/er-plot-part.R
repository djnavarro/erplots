
# part_model ------------------------------------------------------------------

.part_model <- function(object, model, stratify, style, conf_level) {
  
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

  config$builder <- list()
  if (style == "ribbonline") config$builder$model <- build_model_ribbonline
  if (style == "spaghetti")  config$builder$model <- build_model_spaghetti
  config$builder$summary <- build_summary_pvalue # TODO: how to allow custom summary without breaking the style arg

  # store and return
  part_model$stratify <- stratify
  part_model$config <- config

  return(part_model)
}


# part_quantile ---------------------------------------------------------------

.part_quantile <- function(object, stratify, style, bins, conf_level) {

  part_quantile <- list()
  config <- list()

  config$n_quantiles <- bins
  config$conf_level <- conf_level

  config$summary <- object$data |>
    dplyr::mutate(
      response = .data[[object$response$name]],
      exposure_bins = cut_exposure_quantile(
        x = .data[[object$exposure$name]], 
        n = config$n_quantiles
      ),
      strata = .get_strata_values(.data, object$strata$name)   
    ) |> 
    dplyr::summarise(
      n1 = sum(.data[[object$response$name]] == 1, na.rm = TRUE),
      n0 = sum(.data[[object$response$name]] == 0, na.rm = TRUE),
      x_mid = mean(.data[[object$exposure$name]], na.rm = TRUE),
      y_mid = n1 / (n0 + n1),
      y_mid_lbl = object$style$format_percent(n1 / (n0 + n1)),
      ci_lower = clopper_pearson(n1, n0 + n1, config$conf_level)["lower"], 
      ci_upper = clopper_pearson(n1, n0 + n1, config$conf_level)["upper"],
      y_lwr_lbl = ci_lower - 0.05,
      y_upr_lbl = ci_upper + 0.05,
      y_lbl = dplyr::if_else(y_lwr_lbl > 1 - y_upr_lbl, y_lwr_lbl, y_upr_lbl),
      .by = c("exposure_bins", "strata")
    )
  
  if (style == "errorbar") config$builder <- build_quantile_errorbar
  
  # store and return
  part_quantile$stratify <- stratify
  part_quantile$config <- config

  return(part_quantile)
}


# part_strip ------------------------------------------------------------------

.part_strip <- function(object, stratify, style, panel) {

  part_strip <- list()
  
  config <- list()
  config$style <- style
  config$panel <- panel
  config$seed  <- 1234L
  
  if (style == "jitter") config$builder <- build_datastrip_jitter

  if (panel %in% c("lower", "both")) config$lower <- TRUE
  if (panel %in% c("upper", "both")) config$upper <- TRUE

  part_strip$stratify <- stratify
  part_strip$config <- config 

  return(part_strip)
}


# part_group ------------------------------------------------------------------

.part_group <- function(object, group_cols, stratify, style, bins) {

  part_group <- list()
  part_group$stratify <- stratify
  part_group$config <- list()

  for(g in group_cols) {

    config <- list()
    if (style == "boxplot") config$builder <- build_group_boxplot
    if (style == "violin")  config$builder <- build_group_violin

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
