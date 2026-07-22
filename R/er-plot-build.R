
# builders for the three plot types -------------------------------------------

.build_base_plot <- function(object) {

  base <- ggplot2::ggplot() +
    object$theme$theme_base() +
    ggplot2::scale_y_continuous(
      oob = scales::oob_keep, 
      expand = ggplot2::expansion(mult = .01, add = 0)
    )  +
    ggplot2::coord_cartesian(
      xlim = object$exposure$limits, 
      ylim = object$response$limits, 
      clip = "off"
    ) 
  if (!is.null(object$part$model)) {
    base <- base + 
      .build_model_geoms(object) +
      .build_summary_geoms(object)
  }
  if (!is.null(object$part$quantile)) {
    base <- base + .build_quantile_geoms(object)
  }

  return(base)
}

.build_data_plot <- function(object) {

  data     <- object$data
  config   <- object$part$data$config
  stratify <- object$part$data$stratify
  exposure <- object$exposure
  response <- object$response
  strata   <- object$strata
  theme    <- object$theme

  data_plots <- list()

  for (panel_name in config$panels) {
    panel_config <- config
    panel_config$panel <- panel_name
    data_plots[[panel_name]] <- ggplot2::ggplot() +
      theme$theme_base() +
      panel_config$style(
        data, panel_config, stratify, exposure, response, strata, theme
      )
  }

  return(data_plots)
}

.build_overlay_geoms <- function(object) {

  data     <- object$data
  config   <- object$part$overlay$config
  stratify <- object$part$overlay$stratify
  exposure <- object$exposure
  response <- object$response
  strata   <- object$strata
  theme    <- object$theme

  overlay_geoms <- config$style(
    data, config, stratify, exposure, response, strata, theme
  )
  return(overlay_geoms)
}

.build_group_plot <- function(object) {

  data     <- object$data
  config   <- object$part$group$config
  exposure <- object$exposure
  response <- object$response
  strata   <- object$strata
  theme    <- object$theme

  group_plots <- list()
  for(g in names(config)) {
    # each group's own `stratify` (set when it was added via
    # `er_plot_add_groups()`) rather than a single shared value, since
    # different calls may have used different `keep_strata` settings
    group_plots[[g]] <- ggplot2::ggplot() + 
      theme$theme_base() +
      config[[g]]$style(
        data, config[[g]], config[[g]]$stratify, exposure, response, strata, theme
      )
  }
  
  return(group_plots)  
}

.build_model_geoms <- function(object) {

  data     <- object$data
  config   <- object$part$model$config
  stratify <- object$part$model$stratify
  exposure <- object$exposure
  response <- object$response
  strata   <- object$strata
  theme    <- object$theme

  model_geoms <- config$style$model(
    data, config, stratify, exposure, response, strata, theme
  )
  return(model_geoms)
}

.build_summary_geoms <- function(object) {

  data     <- object$data
  config   <- object$part$model$config
  stratify <- object$part$model$stratify
  exposure <- object$exposure
  response <- object$response
  strata   <- object$strata
  theme    <- object$theme

  summary_geoms <- config$style$summary(
    data, config, stratify, exposure, response, strata, theme
  )
  return(summary_geoms)
  
}

.build_quantile_geoms <- function(object) {

  data     <- object$data
  config   <- object$part$quantile$config
  stratify <- object$part$quantile$stratify
  exposure <- object$exposure
  response <- object$response
  strata   <- object$strata
  theme    <- object$theme

  quantile_geoms <- config$style(
    data, config, stratify, exposure, response, strata, theme
  )
  return(quantile_geoms)
}

