
# builders for the three plot types -------------------------------------------

.build_base_plot <- function(object) {

  base <- ggplot2::ggplot() +
    object$theme$theme_base +
    ggplot2::scale_y_continuous(
      oob = scales::oob_keep, 
      expand = ggplot2::expansion(mult = .01, add = 0)
    )  +
    ggplot2::coord_cartesian(
      xlim = object$exposure$limits, 
      ylim = object$response$limits, 
      clip = "off"
    ) 

  # an overlay builder tagged `draw_order = "background"` (e.g.
  # `er_style_data_hex()`) draws before the model/summary/quantile geoms,
  # so a full-panel-coverage data layer doesn't bury them; every other
  # overlay builder defaults to `"foreground"` and is instead added after
  # `.build_base_plot()` returns (see `er_plot_build()`), on top of
  # everything drawn here -- unchanged from before this tag existed.
  if (!is.null(object$layer$overlay) && identical(.style_draw_order(object$layer$overlay$config$style), "background")) {
    base <- base + .build_overlay_geoms(object)
  }
  if (!is.null(object$layer$model)) {
    base <- base + .build_model_geoms(object)
  }
  if (!is.null(object$layer$summary)) {
    base <- base + .build_summary_geoms(object)
  }
  if (!is.null(object$layer$quantile)) {
    base <- base + .build_quantile_geoms(object)
  }

  return(base)
}

.build_data_plot <- function(object) {

  data     <- object$data
  config   <- object$layer$data$config
  stratify <- object$layer$data$stratify
  exposure <- object$exposure
  response <- object$response
  strata   <- object$strata
  theme    <- object$theme

  # "panel"-layout data builders (e.g. `er_style_data_boxjitter()`) only
  # ever map exposure to an axis (the panel's own y is a discrete
  # strata/dummy row, not `response`) -- see `.clip_to_limits()`'s own
  # comment for why this drops rows rather than leaving them to spill
  # past the panel border
  data <- .clip_to_limits(
    data, exposure$name, exposure$limits,
    layer_label = "data-panel observations"
  )

  data_plots <- list()

  for (panel_name in config$panels) {
    panel_config <- config
    panel_config$panel <- panel_name
    data_plots[[panel_name]] <- ggplot2::ggplot() +
      theme$theme_base +
      do.call(panel_config$style, c(
        list(data, panel_config, stratify, exposure, response, strata, theme),
        panel_config$dots
      ))
  }

  return(data_plots)
}

.build_overlay_geoms <- function(object) {

  data     <- object$data
  config   <- object$layer$overlay$config
  stratify <- object$layer$overlay$stratify
  exposure <- object$exposure
  response <- object$response
  strata   <- object$strata
  theme    <- object$theme

  # overlay-layout data builders (`er_style_data_overlay()`/`_hex()`) map
  # both exposure and response to an axis -- see `.clip_to_limits()`'s own
  # comment for why this drops rows rather than leaving them to spill
  # past the panel border
  data <- .clip_to_limits(
    data, exposure$name, exposure$limits,
    response$name, response$limits,
    layer_label = "data-overlay observations"
  )

  overlay_geoms <- do.call(config$style, c(
    list(data, config, stratify, exposure, response, strata, theme),
    config$dots
  ))
  return(overlay_geoms)
}

.build_group_plot <- function(object) {

  data     <- object$data
  config   <- object$layer$group$config
  exposure <- object$exposure
  response <- object$response
  strata   <- object$strata
  theme    <- object$theme

  group_plots <- list()
  for(g in names(config)) {
    # each group's own `stratify` (set when it was added via
    # `er_plot_add_groups()`) rather than a single shared value, since
    # different calls may have used different `keep_strata` settings
    group_config <- config[[g]]

    # a group panel only ever maps exposure to an axis (group levels sit
    # on the other one) -- see `.clip_to_limits()`'s own comment for why
    # this drops rows rather than leaving them to spill past the panel
    # border. Filters `group_config$data` (the panel's own pre-joined
    # data, read by every group style builder -- e.g.
    # `er_style_group_boxplot()`'s `geom_boxplot(data = config$data, ...)`),
    # not the `data` argument passed positionally below.
    group_config$data <- .clip_to_limits(
      group_config$data, exposure$name, exposure$limits,
      layer_label = sprintf("group panel (\"%s\") observations", g)
    )

    group_plots[[g]] <- ggplot2::ggplot() + 
      theme$theme_base +
      do.call(group_config$style, c(
        list(data, group_config, group_config$stratify, exposure, response, strata, theme),
        group_config$dots
      ))
  }
  
  return(group_plots)  
}

.build_model_geoms <- function(object) {

  data     <- object$data
  config   <- object$layer$model$config
  stratify <- object$layer$model$stratify
  exposure <- object$exposure
  response <- object$response
  strata   <- object$strata
  theme    <- object$theme

  model_geoms <- do.call(config$style, c(
    list(data, config, stratify, exposure, response, strata, theme),
    config$dots
  ))
  return(model_geoms)
}

.build_summary_geoms <- function(object) {

  data     <- object$data
  config   <- object$layer$summary$config
  stratify <- object$layer$summary$stratify
  exposure <- object$exposure
  response <- object$response
  strata   <- object$strata
  theme    <- object$theme

  summary_geoms <- do.call(config$style, c(
    list(data, config, stratify, exposure, response, strata, theme),
    config$dots
  ))
  return(summary_geoms)
  
}

.build_quantile_geoms <- function(object) {

  data     <- object$data
  config   <- object$layer$quantile$config
  stratify <- object$layer$quantile$stratify
  exposure <- object$exposure
  response <- object$response
  strata   <- object$strata
  theme    <- object$theme

  # `config$summary`'s bin statistics are computed once from *all* of
  # `object$data` in `.layer_quantile()` and deliberately left
  # untouched here -- see `.clip_quantile_summary_to_limits()`'s own
  # comment for why only the marker (whether a bin's `x_mid`/`y_mid` is
  # drawn) is filtered, not the underlying mean/rate/CI
  config$summary <- .clip_quantile_summary_to_limits(
    config$summary, exposure$limits, response$limits
  )

  quantile_geoms <- do.call(config$style, c(
    list(data, config, stratify, exposure, response, strata, theme),
    config$dots
  ))
  return(quantile_geoms)
}

