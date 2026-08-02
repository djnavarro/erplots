
# Assembles an `er_vpc` object's observed/simulated layers into a single
# ggplot2 object. Unlike `er_plot()`'s multi-panel machinery, a VPC never
# needs `patchwork` composition -- even with `stratify_by` faceting (see
# below), it's still exactly one ggplot2 object.
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
    ggplot2::labs(
      x = object$group$label, y = response$label, color = "Source",
      title = theme$title, subtitle = theme$subtitle, caption = theme$caption
    ) +
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
    ggplot2::scale_fill_hue(limits = .vpc_source_levels) +
    # `xlim`/`ylim` (set via `er_vpc_theme()`, `NULL` by default -- i.e.
    # ggplot2's own automatic range) -- `clip = "off"` matches every
    # `er_plot()` builder's own `coord_cartesian()` call, so a point
    # sitting exactly on a supplied limit isn't clipped at the panel edge
    ggplot2::coord_cartesian(xlim = theme$xlim, ylim = theme$ylim, clip = "off")

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

  # `object$strata` is `NULL` unless the caller supplied `stratify_by` --
  # a `.vpc_stratum` column is always computed (see `.layer_vpc_observed()`),
  # but it's a constant single-level column in that case, so faceting on
  # it is skipped rather than producing a single, redundant facet panel.
  if (!is.null(object$strata)) {
    strata_label <- object$strata$label
    p <- p + ggplot2::facet_wrap(
      ggplot2::vars(.vpc_stratum),
      labeller = ggplot2::as_labeller(function(x) paste0(strata_label, ": ", x))
    )
  }

  return(p)
}
