

#' @rdname er_partial
#' @export
build_group_boxplot <- function(data, config, stratify, exposure, response, strata, style) {

  if (stratify == FALSE) {
    plot_map <- ggplot2::aes(
      x = .data[[exposure$name]], 
      y = lvl
    )
  } 
  if (stratify == TRUE) {
    plot_map <- ggplot2::aes(
      x = .data[[exposure$name]], 
      y = lvl, 
      fill = .data[[strata$name]]
    )
  }

  geoms <- list(
    ggplot2::geom_boxplot(
      data = config$data,
      mapping = plot_map,
      alpha = .5, 
      key_glyph = style$draw_key
    ),
    ggplot2::coord_cartesian(
      xlim = exposure$limits, 
      clip = "off"
    ) 
  )

  return(geoms)
}


#' @rdname er_partial
#' @export
build_group_histogram <- function(data, config, stratify, exposure, response, strata, style) {

  if (stratify == FALSE) {
    plot_map <- ggplot2::aes(x = .data[[exposure$name]])
  }
  if (stratify == TRUE) {
    plot_map <- ggplot2::aes(
      x = .data[[exposure$name]], 
      fill = .data[[strata$name]]
    )
  }

  geoms <- list(
    ggplot2::geom_histogram(
      data = config$data,
      mapping = plot_map,
      bins = 30,
      alpha = if (stratify) .5 else .8,
      position = if (stratify) "identity" else "stack",
      key_glyph = style$draw_key
    ),
    # unlike `build_group_boxplot()`/`build_group_violin()`, a histogram
    # needs its y-axis free for counts, so the group levels (`lvl`) go
    # on facet strips (one row per level) rather than the y-axis itself.
    # The `"er_group_y" = "count"` tag below (mirroring `er_layout()`'s
    # attribute-based approach for the data layer) tells `.polish_labels()`
    # to title this axis "Count" rather than the group variable's own
    # label, which is what it uses for `build_group_boxplot()`/
    # `build_group_violin()`, where the group variable *is* the y-axis.
    ggplot2::facet_grid(
      rows = ggplot2::vars(lvl), 
      switch = "y"
    ),
    ggplot2::coord_cartesian(
      xlim = exposure$limits, 
      clip = "off"
    ),
    # ggplot2's default for a left-hand strip (`switch = "y"`) rotates
    # the text 90 degrees, sized to fit the (short) row height rather
    # than the (longer) available width -- long `lvl` labels like
    # "Placebo (N=100)" get clipped vertically as a result. Rotating
    # back to horizontal lets the strip auto-expand to fit the full
    # label instead.
    ggplot2::theme(
      strip.text.y.left = ggplot2::element_text(angle = 0, hjust = 0)
    )
  )

  return(geoms)
}
attr(build_group_histogram, "er_group_y") <- "count"


#' @rdname er_partial
#' @export
build_group_violin <- function(data, config, stratify, exposure, response, strata, style) {

  if (stratify == FALSE) {
    plot_map <- ggplot2::aes(
      x = .data[[exposure$name]], 
      y = lvl
    )
  } 
  if (stratify == TRUE) {
    plot_map <- ggplot2::aes(
      x = .data[[exposure$name]], 
      y = lvl, 
      fill = .data[[strata$name]]
    )
  }

  geoms <- list(
    ggplot2::geom_violin(
      data = config$data,
      mapping = plot_map,
      quantile.linetype = "solid",
      alpha = 0.5, 
      key_glyph = style$draw_key
    ),
    ggplot2::coord_cartesian(
      xlim = exposure$limits, 
      clip = "off"
    ) 
  )

  return(geoms)
}
