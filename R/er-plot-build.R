
# builders for the three plot types -------------------------------------------

.build_base_plot <- function(object) {

  base <- ggplot2::ggplot() +
    object$style$theme_base() +
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

.build_strip_plot <- function(object) {

  data     <- object$data
  config   <- object$part$strip$config
  stratify <- object$part$strip$stratify
  exposure <- object$exposure
  response <- object$response
  strata   <- object$strata
  style    <- object$style

  strip_plots <- list()

  if (config$upper) {
    config$panel <- "upper"
    strip_plots$upper <- ggplot2::ggplot() +
      style$theme_base() +
      config$builder(
        data, config, stratify, exposure, response, strata, style
      )
  }
  if (config$lower) {
    config$panel <- "lower"
    strip_plots$lower <- ggplot2::ggplot() +
      style$theme_base() +
      config$builder(
        data, config, stratify, exposure, response, strata, style
      )
  }

  return(strip_plots)
}

.build_group_plot <- function(object) {

  data     <- object$data
  config   <- object$part$group$config
  stratify <- object$part$group$stratify
  exposure <- object$exposure
  response <- object$response
  strata   <- object$strata
  style    <- object$style

  group_plots <- list()
  for(g in names(config)) {
    group_plots[[g]] <- ggplot2::ggplot() + 
      style$theme_base() +
      config[[g]]$builder(
        data, config[[g]], stratify, exposure, response, strata, style
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
  style    <- object$style

  model_geoms <- config$builder$model(
    data, config, stratify, exposure, response, strata, style
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
  style    <- object$style

  summary_geoms <- config$builder$summary(
    data, config, stratify, exposure, response, strata, style
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
  style    <- object$style

  quantile_geoms <- config$builder(
    data, config, stratify, exposure, response, strata, style
  )
  return(quantile_geoms)
}

