
# The VPC analogue of `.clip_quantile_summary_to_limits()` (see
# `R/utils-helpers.R`). `config$summary`/`config$percentiles` are
# bin/percentile-level summaries computed once from the full data (see
# `.layer_vpc_observed()`/`.layer_vpc_simulated()`), deliberately never
# touched by `er_vpc_theme(xlim = )`/`ylim = )` -- those stay purely
# cosmetic, feeding only `ggplot2::coord_cartesian()` below. Because that
# coord uses `clip = "off"`, a summary marker that ends up outside a
# narrowed window still gets drawn, bleeding past the panel border with
# no indication anything is missing -- the same silent-spillover shape
# fixed for `er_plot()`'s data/quantile/group layers in #16 (see #17).
#
# This filters (and warns about) only the marker position `config$style`
# actually renders, not the bin's own statistic: `x_mid` for the
# continuous-x percentile-band idiom (`.style_vpc_layout(style) ==
# "continuous"`), or `x_median` for the adaptive mean/errorbar and
# quantile-errorbar idioms when `plot_by` is numeric -- a categorical
# `plot_by`'s discrete `.vpc_bin` position is never filtered, since a
# numeric `xlim` has no meaningful bearing on it. `y_mid`/`y` (not the CI
# bounds) is the only y-position checked, mirroring
# `.clip_quantile_summary_to_limits()`'s own "marker, not the whole
# errorbar" scope.
#
# `config$style`'s own `marker_source` tag (see `er_style_tag()`) says
# whether it draws from `config$summary` or `config$percentiles` --
# built-in VPC builders draw from exactly one, never both, so clipping
# (and warning about) the other would flag rows that were never going to
# be plotted regardless of `xlim`/`ylim`. An untagged style has both
# tables checked (always safe, just possibly over-warns for a custom
# builder that only uses one) -- the same opt-in treatment every other
# `er_style_tag()` attribute gets.
#' @noRd
.clip_vpc_config_to_limits <- function(config, xlim, ylim, source_label) {
  if (is.null(xlim) && is.null(ylim)) return(config)

  marker_source <- .style_vpc_marker_source(config$style)

  in_range <- function(x, limits) {
    if (is.null(limits)) return(rep(TRUE, length(x)))
    is.na(x) | (x >= limits[1] & x <= limits[2])
  }

  x_col <- if (identical(.style_vpc_layout(config$style), "continuous")) {
    "x_mid"
  } else if (isTRUE(config$is_numeric_group)) {
    "x_median"
  } else {
    NULL # categorical `.vpc_bin` position, not filterable by a numeric `xlim`
  }

  label_bin <- function(tbl) {
    if (length(unique(tbl$.vpc_stratum)) > 1) {
      paste0(tbl$.vpc_bin, " [", tbl$.vpc_stratum, "]")
    } else {
      as.character(tbl$.vpc_bin)
    }
  }

  clip_table <- function(tbl, y_col, label_fn) {
    if (is.null(tbl) || nrow(tbl) == 0) return(tbl)

    keep_x <- if (is.null(x_col)) rep(TRUE, nrow(tbl)) else in_range(tbl[[x_col]], xlim)
    keep_y <- in_range(tbl[[y_col]], ylim)
    keep <- keep_x & keep_y

    n_dropped <- sum(!keep)
    if (n_dropped > 0) {
      hidden <- label_fn(tbl[!keep, , drop = FALSE])
      rlang::warn(c(
        sprintf(
          "%d of %d %s VPC marker%s fall%s outside the plotted axis limits and %s not shown: %s.",
          n_dropped, nrow(tbl), source_label, if (n_dropped == 1) "" else "s",
          if (n_dropped == 1) "s" else "", if (n_dropped == 1) "is" else "are",
          paste(hidden, collapse = ", ")
        ),
        "i" = "The bin's own summary statistic is still computed from every observation in it -- only its marker's position falls outside the current `xlim`/`ylim`.",
        "i" = "Widen `xlim`/`ylim` (via `er_vpc_theme()`) to show it."
      ))
    }

    tbl[keep, , drop = FALSE]
  }

  if (is.null(marker_source) || identical(marker_source, "summary")) {
    config$summary <- clip_table(config$summary, "y_mid", label_bin)
  }
  if (!is.null(config$percentiles) && (is.null(marker_source) || identical(marker_source, "percentiles"))) {
    # `.layer_vpc_observed()`'s percentile column is named `y`;
    # `.layer_vpc_simulated()`'s is named `y_mid` -- pick whichever this
    # config actually has rather than assuming one name
    percentile_y_col <- if ("y" %in% names(config$percentiles)) "y" else "y_mid"
    config$percentiles <- clip_table(
      config$percentiles, percentile_y_col,
      function(tbl) paste0(label_bin(tbl), " (p", tbl$prob, ")")
    )
  }

  config
}

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
    config <- .clip_vpc_config_to_limits(config, theme$xlim, theme$ylim, source_label = "simulated")
    geoms <- do.call(config$style, c(
      list(object$data, config, exposure, response, theme),
      config$dots
    ))
    p <- p + geoms
  }

  if (!is.null(object$layer$observed)) {
    config <- object$layer$observed$config
    config <- .clip_vpc_config_to_limits(config, theme$xlim, theme$ylim, source_label = "observed")
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
