#' Data layer builders for exposure-response plots
#'
#' Builder functions for the `data` layer ([er_plot_add_data()]), drawing raw
#' observations either as an overlay on the main panel or as separate
#' boxplot/jitter panels.
#'
#' @include er-plot-style.R
#' @param data The original data frame.
#' @param config Configuration for the specific plot.
#' @param stratify Logical: whether to stratify.
#' @param exposure Exposure variable.
#' @param response Response variable.
#' @param strata Stratification variable.
#' @param theme Theme components.
#' @param ... Additional named arguments forwarded from [er_plot_add_data()]'s own `...`.
#' @param jitter_height Vertical jitter applied to raw points.
#' @param alpha Point transparency for `er_style_data_overlay()`; fill
#'   transparency for `er_style_data_hex()`.
#' @param size Point size for `er_style_data_overlay()`.
#' @param box_width Width of `er_style_data_boxjitter()`'s boxplot.
#' @param box_alpha Transparency of `er_style_data_boxjitter()`'s boxplot fill.
#' @param show_outliers Logical: whether `er_style_data_boxjitter()` draws outlier points.
#' @param jitter_size Point size for `er_style_data_boxjitter()`'s jittered points.
#' @param jitter_alpha Transparency of `er_style_data_boxjitter()`'s jittered points.
#' @param bins Number of hex bins for `er_style_data_hex()`.
#'
#' @details Builders for the `data` layer ([er_plot_add_data()]) are tagged with the structural family they belong to via [er_style_tag()]. `er_style_data_overlay()` and `er_style_data_hex()` use the overlay layout, drawing in the main panel; `er_style_data_boxjitter()` uses the panel layout and is binary-response only. All built-in data builders are also tagged `layer = "data"`, so [er_plot_add_data()] errors if given a builder tagged for another layer.
#'
#' `er_style_data_hex()` defaults to a light-grey-to-navy (`"grey90"` to
#' `"#132B43"`) fill gradient, so a cell's fill fades toward the panel
#' background as its count approaches zero rather than starting at
#' ggplot2's own default mid-intensity blue. Override it with
#' `er_plot_theme(fill_continuous = ...)`.
#'
#' Because its geoms cover the whole panel, `er_style_data_hex()` is
#' tagged `er_style_tag(fn, zorder = "background")` (see [er_style_tag()]),
#' so it's drawn before the model/summary/quantile layers rather than on
#' top of them; its default `alpha = 0.85` gives those layers a little
#' extra visibility through even a densely populated hex cell.
#'
#' See [er_style()] for the shared builder interface these functions implement.
#'
#' @returns A geom, or a list of geoms; see [er_style()].
#'
#' @examples
#' if (requireNamespace("erglm", quietly = TRUE)) {
#'   library(erglm)
#'   mod2 <- erglm_model(ae2 ~ aucss + sex, erglm_data, family = binomial())
#'
#'   # er_style_data_overlay(): the default, raw points on the main panel
#'   erglm_data |>
#'     er_plot(aucss, ae2, stratify_by = sex) |>
#'     er_plot_add_model(mod2) |>
#'     er_plot_add_data(style = er_style_data_overlay) |>
#'     plot()
#'
#'   # er_style_data_boxjitter(): binary-response only, boxplot + jitter
#'   # panels above/below the main panel instead of an overlay
#'   erglm_data |>
#'     er_plot(aucss, ae2, stratify_by = sex) |>
#'     er_plot_add_model(mod2) |>
#'     er_plot_add_data(style = er_style_data_boxjitter) |>
#'     plot()
#'
#'   # overriding a builder's own visual defaults, e.g. larger/more
#'   # opaque points and a wider jitter
#'   erglm_data |>
#'     er_plot(aucss, ae2, stratify_by = sex) |>
#'     er_plot_add_model(mod2) |>
#'     er_plot_add_data(
#'       style = er_style_data_overlay,
#'       jitter_height = 0.1,
#'       alpha = 0.7,
#'       size = 2
#'     ) |>
#'     plot()
#' }
#'
#' @name er_style_data
#' @seealso [er_style()], [er_style_tag()]
NULL

#' @rdname er_style_data
#' @export
er_style_data_boxjitter <- er_style_tag(function(data, config, stratify, exposure, response, strata, theme, ...,
                                                  box_width = 0.6,
                                                  box_alpha = 0.4,
                                                  show_outliers = FALSE,
                                                  jitter_height = NULL,
                                                  jitter_size = 1,
                                                  jitter_alpha = 0.6) {

  # binary-response-only panel builder: filters to responders (upper
  # panel, response == 1) or non-responders (lower panel, response == 0),
  # then draws a boxplot of the exposure values underneath the jittered
  # points, so the panel shows the *distribution* of exposure conditional
  # on response (not just raw points)
  if (config$panel == "upper") dat <- data |> dplyr::filter(.data[[response$name]] == 1)
  if (config$panel == "lower") dat <- data |> dplyr::filter(.data[[response$name]] == 0)

  # `position_jitterdodge()`/`position_dodge()` dodge along the *discrete*
  # axis, which here would be y (`orientation = "y"`) -- but the exposure
  # values on x are continuous and (almost) never share an exact value
  # across rows, so ggplot has nothing sensible to dodge against and warns
  # ("requires non-overlapping x intervals"). Mapping y to the strata
  # factor directly sidesteps this: ggplot places each stratum at its own
  # discrete row automatically (the same trick `er_style_group_boxplot()`
  # uses via `y = lvl`), and `geom_jitter()`'s usual height-jitter spreads
  # points within that row without needing any dodge machinery.
  if (stratify == TRUE) {
    box_map <- ggplot2::aes(
      x = .data[[exposure$name]],
      y = .data[[strata$name]],
      fill = .data[[strata$name]]
    )
    jitter_map <- ggplot2::aes(
      x = .data[[exposure$name]],
      y = .data[[strata$name]],
      color = .data[[strata$name]]
    )
  }
  if (stratify == FALSE) {
    box_map <- ggplot2::aes(
      x = .data[[exposure$name]],
      y = 0
    )
    jitter_map <- ggplot2::aes(
      x = .data[[exposure$name]],
      y = 0
    )
  }

  # raw points are already shown via the jitter layer, so the boxplot's
  # own outlier points are redundant by default
  outlier_shape <- if (show_outliers) 19 else NA

  if (is.null(jitter_height)) jitter_height <- if (stratify) 0.3 else 0.15

  geoms <- list(
    ggplot2::geom_boxplot(
      data = dat,
      mapping = box_map,
      orientation = "y",
      width = box_width,
      alpha = box_alpha,
      outlier.shape = outlier_shape,
      key_glyph = theme$draw_key
    ),
    ggplot2::geom_jitter(
      data = dat,
      mapping = jitter_map,
      position = ggplot2::position_jitter(width = 0, height = jitter_height, seed = config$seed),
      size = jitter_size,
      alpha = jitter_alpha,
      key_glyph = theme$draw_key
    ),
    ggplot2::coord_cartesian(
      xlim = exposure$limits,
      clip = "off"
    ),
    if (stratify) {
      ggplot2::scale_y_discrete(breaks = NULL)
    } else {
      ggplot2::scale_y_continuous(breaks = NULL, minor_breaks = NULL, limits = c(-0.3, 0.3))
    }
  )

  return(geoms)
}, layout = "panel", layer = "data")


#' @rdname er_style_data
#' @export
er_style_data_overlay <- er_style_tag(function(data, config, stratify, exposure, response, strata, theme, ...,
                                                jitter_height = NULL,
                                                alpha = 0.4,
                                                size = 1) {

  # unlike `er_style_data_boxjitter()`, this builder draws points at their
  # true (exposure, response) coordinates and its output is meant to be
  # added to the *base* plot (see `.build_overlay_geoms()` in
  # R/er-plot-build.R), not a standalone above/below panel -- so there's
  # no response-type dispatch on which points to filter (no binary
  # upper/lower split) and no `color_role` juggling: colour, when mapped at
  # all, always means strata, since the response is already shown via
  # y-position.
  if (stratify == TRUE) {
    plot_map <- ggplot2::aes(
      x = .data[[exposure$name]],
      y = .data[[response$name]],
      color = .data[[strata$name]]
    )
  } else {
    plot_map <- ggplot2::aes(
      x = .data[[exposure$name]],
      y = .data[[response$name]]
    )
  }

  # a binary response's y-values are exactly 0/1, so without jitter points
  # overplot into two dense horizontal lines; continuous/count responses
  # need no such nudge, since their y-values are already spread out.
  if (is.null(jitter_height)) {
    jitter_height <- if (config$response_type == "binary") 0.015 else 0
  }

  geoms <- list(
    ggplot2::geom_jitter(
      data = data,
      mapping = plot_map,
      position = ggplot2::position_jitter(width = 0, height = jitter_height, seed = config$seed),
      alpha = alpha,
      size = size,
      key_glyph = theme$draw_key
    )
  )

  return(geoms)
}, layout = "overlay", layer = "data")


#' @rdname er_style_data
#' @export
er_style_data_hex <- er_style_tag(function(data, config, stratify, exposure, response, strata, theme, ...,
                                            bins = 30, alpha = 0.85) {

  # a 2D-binned density alternative to `er_style_data_overlay()`'s raw
  # scatter, for when N is large enough that individual points overplot
  # into an unreadable smear -- most useful for continuous/count
  # responses (where y-values are spread out rather than piled at 0/1).
  # `geom_hex()`'s fill aesthetic already encodes bin density, so unlike
  # `er_style_data_overlay()` there's no channel left for a `color = strata`
  # mapping; when stratified, all strata are pooled into a single
  # hex-binned density rather than partially or misleadingly encoding
  # strata (see `?er_style`'s "a layer's own encoding takes precedence"
  # rule). A stratum-faceted hexbin remains possible via a custom
  # builder, but isn't attempted here.
  #
  # Because this builder's `fill` is continuous (density) rather than
  # discrete (strata), it can't share the base plot's `fill` aesthetic
  # with a stratified `er_style_model_ribbonline()` (whose ribbon maps
  # `fill = strata`, discrete) -- ggplot2 errors ("Continuous value
  # supplied to a discrete scale") if both are combined. Pair a
  # stratified plot using `er_style_data_hex()` with a model builder that
  # doesn't map `fill`, e.g. `er_style_model_line()` (colour only). The
  # `fill_role = "density"` tag below tells `.polish_labels()` to title
  # the (sole) `fill` legend "Count" rather than the strata label it uses
  # by default.
  rlang::check_installed("hexbin", reason = "for `er_style_data_hex()`'s `geom_hex()`.")

  if (stratify == TRUE) {
    rlang::inform(paste0(
      "`er_style_data_hex()` does not encode `strata` -- its fill aesthetic ",
      "already encodes point density, so all strata are pooled into a ",
      "single hex-binned density."
    ))
  }

  geoms <- list(
    ggplot2::geom_hex(
      data = data,
      mapping = ggplot2::aes(
        x = .data[[exposure$name]],
        y = .data[[response$name]]
      ),
      bins = bins,
      alpha = alpha,
      key_glyph = theme$draw_key
    )
  )

  # Fade toward the panel background matching the default
  # `theme_bw()` base theme as a cell's count approaches zero, rather
  # than starting at ggplot2's default mid-intensity blue -- this is this
  # builder's own visual default. Only added when the user hasn't already
  # supplied `er_plot_theme(fill_continuous = ...)`, so overriding the
  # palette doesn't trip ggplot2's "already present" duplicate-scale
  # warning (`.polish_scales()` would otherwise be adding a second fill
  # scale on top of this one).
  if (is.null(theme$fill_continuous)) {
    geoms <- c(geoms, list(ggplot2::scale_fill_gradient(low = "grey90", high = "#132B43")))
  }

  return(geoms)
}, layout = "overlay", fill_role = "density", layer = "data", zorder = "background")
