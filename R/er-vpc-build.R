
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
    # `fill = "Source"` is left to the individual builders that actually
    # map fill (e.g. `er_style_vpc_simulated_quantile_ribbon()`) -- setting
    # it here unconditionally would make `labs()` warn "ignoring unknown
    # labels" whenever a builder pair never maps fill at all.
    ggplot2::labs(x = object$group$label, y = response$label, color = "Source") +
    # Fixed, shared `limits` on both the colour and fill scales -- not
    # just their default palette -- so "Observed"/"Simulated" always
    # land on the same two hues whether a given pair of builders maps
    # the distinction via colour, fill, or one of each. Without this,
    # colour and fill each train independently on whatever single level
    # their own layer supplies (e.g. a colour-only observed builder
    # paired with a fill-only simulated builder), and both scales
    # independently assign the *first* hue in the default palette to
    # their one level, making observed and simulated indistinguishable.
    ggplot2::scale_colour_hue(limits = .vpc_source_levels) +
    ggplot2::scale_fill_hue(limits = .vpc_source_levels)

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
