#' Group panel builders for exposure-response plots
#'
#' Builder functions for the `group` layer ([er_plot_add_groups()]), drawing
#' the exposure distribution for a grouping variable as a boxplot, violin, or
#' histogram panel.
#'
#' @include er-plot-style.R
#' @param data The original data frame.
#' @param config Configuration for the specific plot.
#' @param stratify Logical: whether to stratify.
#' @param exposure Exposure variable.
#' @param response Response variable.
#' @param strata Stratification variable.
#' @param theme Theme components.
#' @param alpha Transparency of the geom.
#' @param bins Number of histogram bins for `er_style_group_histogram()`.
#' @param quantiles,quantile_linetype Violin quantile positions and linetype for `er_style_group_violin()`.
#' @param size Overall size multiplier for `er_style_group_linerange()`'s dot and lines.
#' @param inner_range,outer_range Quantile probabilities (length 2) for `er_style_group_linerange()`'s thick and thin lines.
#' @param alpha_dot,alpha_inner,alpha_outer Per-part transparency for `er_style_group_linerange()`'s dot, inner line, and outer line.
#' @param ... Additional named arguments forwarded from [er_plot_add_groups()]'s own `...`.
#'
#' @details Builders for the `group` layer ([er_plot_add_groups()]) draw exposure distributions for grouping variables. `er_style_group_boxplot()` and `er_style_group_violin()` put group levels on the y-axis; `er_style_group_histogram()` puts them on facet strips and frees the y-axis for counts; `er_style_group_linerange()` also puts group levels on the y-axis, summarising each level's exposure distribution as a median dot flanked by an inner-range and outer-range line rather than a full boxplot/violin shape. All built-in group builders are tagged `layer = "group"`, so [er_plot_add_groups()] errors if given one tagged for another layer.
#'
#' See [er_style()] for the shared builder interface these functions implement.
#'
#' @returns A geom, or a list of geoms; see [er_style()].
#'
#' @examples
#' if (requireNamespace("erglm", quietly = TRUE)) {
#'   library(erglm)
#'   mod <- erglm_model(ae1 ~ aucss, erglm_data, family = binomial())
#'
#'   # er_style_group_boxplot(): the default
#'   erglm_data |>
#'     er_plot(aucss, ae1) |>
#'     er_plot_add_model(mod) |>
#'     er_plot_add_groups(aucss, style = er_style_group_boxplot) |>
#'     plot()
#'
#'   # er_style_group_violin(): a violin instead of a boxplot
#'   erglm_data |>
#'     er_plot(aucss, ae1) |>
#'     er_plot_add_model(mod) |>
#'     er_plot_add_groups(aucss, style = er_style_group_violin) |>
#'     plot()
#'
#'   # er_style_group_histogram(): group levels on facet strips, with
#'   # the y-axis freed for counts
#'   erglm_data |>
#'     er_plot(aucss, ae1) |>
#'     er_plot_add_model(mod) |>
#'     er_plot_add_groups(aucss, style = er_style_group_histogram) |>
#'     plot()
#'
#'   # er_style_group_linerange(): median dot + inner/outer range lines,
#'   # instead of a full boxplot/violin shape
#'   erglm_data |>
#'     er_plot(aucss, ae1) |>
#'     er_plot_add_model(mod) |>
#'     er_plot_add_groups(aucss, style = er_style_group_linerange) |>
#'     plot()
#' }
#'
#' @name er_style_group
#' @seealso [er_style()]
NULL

#' @rdname er_style_group
#' @export
er_style_group_boxplot <- function(data, config, stratify, exposure, response, strata, theme,
                                    alpha = 0.5, ...) {

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
      alpha = alpha, 
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
er_style_group_histogram <- function(data, config, stratify, exposure, response, strata, theme,
                                      bins = 30, alpha = NULL, ...) {

  if (stratify == FALSE) {
    plot_map <- ggplot2::aes(x = .data[[exposure$name]])
  }
  if (stratify == TRUE) {
    plot_map <- ggplot2::aes(
      x = .data[[exposure$name]], 
      fill = .data[[strata$name]]
    )
  }

  resolved_alpha <- if (is.null(alpha)) (if (stratify) .5 else .8) else alpha

  geoms <- list(
    ggplot2::geom_histogram(
      data = config$data,
      mapping = plot_map,
      bins = bins,
      alpha = resolved_alpha,
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
er_style_group_violin <- function(data, config, stratify, exposure, response, strata, theme,
                                   alpha = 0.5, quantiles = NULL, quantile_linetype = "solid", ...) {

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

  geom_args <- list(
    data = config$data,
    mapping = plot_map,
    alpha = alpha,
    key_glyph = theme$draw_key
  )
  if (!is.null(quantiles)) {
    geom_args$quantiles <- quantiles
    geom_args$quantile.linetype <- quantile_linetype
  }

  geoms <- list(
    do.call(ggplot2::geom_violin, geom_args),
    ggplot2::coord_cartesian(
      xlim = exposure$limits, 
      clip = "off"
    ) 
  )

  return(geoms)
}
er_style_group_violin <- er_style_tag(er_style_group_violin, layer = "group")


#' @rdname er_style_group
#' @export
er_style_group_linerange <- function(data, config, stratify, exposure, response, strata, theme,
                                      size = 1, inner_range = c(0.25, 0.75), outer_range = c(0.05, 0.95),
                                      alpha_dot = 1, alpha_inner = 0.8, alpha_outer = 0.4, ...) {

  if (length(inner_range) != 2 || inner_range[1] >= inner_range[2] ||
      any(inner_range < 0) || any(inner_range > 1)) {
    rlang::abort("`inner_range` must be a length-2 numeric vector with 0 <= inner_range[1] < inner_range[2] <= 1.")
  }
  if (length(outer_range) != 2 || outer_range[1] >= outer_range[2] ||
      any(outer_range < 0) || any(outer_range > 1)) {
    rlang::abort("`outer_range` must be a length-2 numeric vector with 0 <= outer_range[1] < outer_range[2] <= 1.")
  }

  grp_cols <- if (stratify) c("lvl", strata$name) else "lvl"

  summary_df <- config$data |>
    dplyr::summarise(
      .by = dplyr::all_of(grp_cols),
      med = stats::median(.data[[exposure$name]]),
      inner_lo = unname(stats::quantile(.data[[exposure$name]], inner_range[1])),
      inner_hi = unname(stats::quantile(.data[[exposure$name]], inner_range[2])),
      outer_lo = unname(stats::quantile(.data[[exposure$name]], outer_range[1])),
      outer_hi = unname(stats::quantile(.data[[exposure$name]], outer_range[2]))
    )

  # a single overall `size` argument scales all three parts together --
  # the outer line is deliberately the thinnest, the inner line about
  # half the dot's diameter, and the dot itself the most visually
  # prominent of the three, matching the issue's stated visual design.
  dot_size <- 2.5 * size
  inner_linewidth <- 1.25 * size
  outer_linewidth <- 0.5 * size

  if (stratify == FALSE) {

    outer <- ggplot2::geom_linerange(
      data = summary_df,
      mapping = ggplot2::aes(y = lvl, xmin = outer_lo, xmax = outer_hi),
      orientation = "y",
      linewidth = outer_linewidth,
      alpha = alpha_outer,
      key_glyph = theme$draw_key
    )
    inner <- ggplot2::geom_linerange(
      data = summary_df,
      mapping = ggplot2::aes(y = lvl, xmin = inner_lo, xmax = inner_hi),
      orientation = "y",
      linewidth = inner_linewidth,
      alpha = alpha_inner,
      key_glyph = theme$draw_key
    )
    dot <- ggplot2::geom_point(
      data = summary_df,
      mapping = ggplot2::aes(y = lvl, x = med),
      size = dot_size,
      alpha = alpha_dot,
      key_glyph = theme$draw_key
    )
  }

  if (stratify == TRUE) {

    # all three geoms share one `position_dodge()` object so the dot
    # lines up with the centre of its own stratum's inner/outer lines
    dodge <- ggplot2::position_dodge(width = 0.6)

    outer <- ggplot2::geom_linerange(
      data = summary_df,
      mapping = ggplot2::aes(
        y = lvl, xmin = outer_lo, xmax = outer_hi,
        color = .data[[strata$name]]
      ),
      orientation = "y",
      position = dodge,
      linewidth = outer_linewidth,
      alpha = alpha_outer,
      key_glyph = theme$draw_key
    )
    inner <- ggplot2::geom_linerange(
      data = summary_df,
      mapping = ggplot2::aes(
        y = lvl, xmin = inner_lo, xmax = inner_hi,
        color = .data[[strata$name]]
      ),
      orientation = "y",
      position = dodge,
      linewidth = inner_linewidth,
      alpha = alpha_inner,
      key_glyph = theme$draw_key
    )
    dot <- ggplot2::geom_point(
      data = summary_df,
      mapping = ggplot2::aes(
        y = lvl, x = med,
        color = .data[[strata$name]]
      ),
      position = dodge,
      size = dot_size,
      alpha = alpha_dot,
      key_glyph = theme$draw_key
    )
  }

  geoms <- list(
    outer,
    inner,
    dot,
    ggplot2::coord_cartesian(
      xlim = exposure$limits,
      clip = "off"
    )
  )

  return(geoms)
}
er_style_group_linerange <- er_style_tag(er_style_group_linerange, layer = "group")
