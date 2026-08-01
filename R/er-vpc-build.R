
# Assembles an `er_vpc` object's observed/simulated layers into a single
# ggplot2 object. Unlike `er_plot()`'s multi-panel machinery, a VPC is
# always a single panel in v1 (no stratification/faceting), so there's
# no patchwork composition step here.
#' @noRd
.build_vpc_plot <- function(object) {

  exposure <- object$exposure
  response <- object$response
  theme <- object$theme

  p <- ggplot2::ggplot() +
    theme$theme_base +
    theme$theme_extra +
    # x-axis is `plot_by`, not necessarily `exposure` -- they coincide
    # only when the caller didn't supply `plot_by` (or supplied the
    # exposure variable itself)
    ggplot2::labs(x = object$group$label, y = response$label, color = "Source")

  # the simulated layer is added first (drawn underneath), so a ribbon
  # band never buries the observed points/line on top of it -- there's
  # no alternative here, unlike the data layer's overlay `zorder` problem
  # in `er_plot()`, so no tag/config is needed to control this
  if (!is.null(object$layer$simulated)) {
    config <- object$layer$simulated$config
    geoms <- do.call(config$style, c(
      list(object$data, config, exposure, response, theme),
      config$dots
    ))
    p <- p + geoms
  }

  if (!is.null(object$layer$observed)) {
    config <- object$layer$observed$config
    geoms <- do.call(config$style, c(
      list(object$data, config, exposure, response, theme),
      config$dots
    ))
    p <- p + geoms
  }

  return(p)
}
