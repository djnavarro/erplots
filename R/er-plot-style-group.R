
#' Group panel builders for exposure-response plots
#'
#' @param data The original data frame
#' @param config Configuration for the specific plot
#' @param stratify Logical indicating whether to stratify
#' @param exposure Exposure variable
#' @param response Response variable
#' @param strata Stratification variable
#' @param theme Theme components
#' @param ... Additional named arguments forwarded from
#'   [er_plot_add_groups()]'s own `...`; see [er_style()]'s "Passing
#'   extra arguments to a builder" section.
#'
#' @details Builders for the `group` layer ([er_plot_add_groups()]),
#' which draws the exposure distribution for a grouping variable (e.g.
#' treatment arm) below the main panel: `er_style_group_boxplot()` (the
#' default), `er_style_group_violin()`, and `er_style_group_histogram()`.
#' The first two put the group levels on the y-axis; `er_style_group_histogram()`
#' instead puts them on facet strips and frees the y-axis for counts (see
#' `Details` in the package's `AGENTS.md`/`PLAN.md` for the rationale).
#' All three are tagged `er_style_tag(fn, layer = "group")`, so
#' [er_plot_add_groups()] errors informatively if handed a builder
#' tagged for a different layer.
#'
#' See [er_style()] for the shared builder interface these functions
#' implement, including how to write a custom builder of your own.
#'
#' @returns A geom, or a list of geoms; see [er_style()].
#'
#' @name er_style_group
#' @seealso [er_style()]
NULL

#' @rdname er_style_group
#' @export
er_style_group_boxplot <- function(data, config, stratify, exposure, response, strata, theme, ...) {

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
      key_glyph = theme$draw_key
    ),
    ggplot2::coord_cartesian(
      xlim = exposure$limits, 
      clip = "off"
    ) 
  )

  return(geoms)
}
er_style_group_boxplot <- er_style_tag(er_style_group_boxplot, layer = "group")


#' @rdname er_style_group
#' @export
er_style_group_histogram <- function(data, config, stratify, exposure, response, strata, theme, ...) {

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
      key_glyph = theme$draw_key
    ),
    # unlike `er_style_group_boxplot()`/`er_style_group_violin()`, a histogram
    # needs its y-axis free for counts, so the group levels (`lvl`) go
    # on facet strips (one row per level) rather than the y-axis itself.
    # The `er_style_tag(builder, y_role = "count")` call below (mirroring
    # `er_style_tag()`'s `layout` argument for the data layer) tells
    # `.polish_labels()` to title this axis "Count" rather than the
    # group variable's own label, which is what it uses for
    # `er_style_group_boxplot()`/`er_style_group_violin()`, where the
    # group variable *is* the y-axis.
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
er_style_group_histogram <- er_style_tag(er_style_group_histogram, y_role = "count", layer = "group")


#' @rdname er_style_group
#' @export
er_style_group_violin <- function(data, config, stratify, exposure, response, strata, theme, ...) {

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
      key_glyph = theme$draw_key
    ),
    ggplot2::coord_cartesian(
      xlim = exposure$limits, 
      clip = "off"
    ) 
  )

  return(geoms)
}
er_style_group_violin <- er_style_tag(er_style_group_violin, layer = "group")
