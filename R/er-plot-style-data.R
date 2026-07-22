
#' Data layer builders for exposure-response plots
#'
#' @param data The original data frame
#' @param config Configuration for the specific plot
#' @param stratify Logical indicating whether to stratify
#' @param exposure Exposure variable
#' @param response Response variable
#' @param strata Stratification variable
#' @param theme Theme components
#'
#' @details Builders for the `data` layer ([er_plot_add_data()]), which
#' shows the raw observations alongside the fitted curve. Each builder is
#' tagged, via [er_style_tag()], with the *structural* family it belongs to:
#' `er_style_data_overlay()` (the default) and `er_style_data_hex()` use the
#' `"overlay"` layout, plotting directly on the model panel at the raw
#' `(exposure, response)` coordinates (points or, for `er_style_data_hex()`,
#' a 2D density); `er_style_data_boxjitter()` uses the `"panel"` layout
#' (binary response only), stacking boxplot-plus-jitter panels for
#' responders/non-responders below the base plot. See [er_style_tag()] and
#' [er_plot_add_data()] for how this tag is used. All three built-in
#' data builders are also tagged `layer = "data"`, so [er_plot_add_data()]
#' errors informatively if handed a builder tagged for a different layer.
#'
#' See [er_style()] for the shared builder interface these functions
#' implement, including how to write a custom builder of your own.
#'
#' @returns A geom, or a list of geoms; see [er_style()].
#'
#' @name er_style_data
#' @seealso [er_style()], [er_style_tag()]
NULL

#' @rdname er_style_data
#' @export
er_style_data_boxjitter <- er_style_tag(function(data, config, stratify, exposure, response, strata, theme) {

  # binary-response-only panel builder: filters to responders (upper
  # panel, response == 1) or non-responders (lower panel, response == 0),
  # then draws a boxplot of the exposure values underneath the jittered
  # points, so the panel shows the *distribution* of exposure conditional
  # on response (not just raw points) -- see PLAN.md's "Data layer
  # panel-based builders" section for why this replaced the older
  # `build_data_jitter()`, whose typical use case turned out to be
  # covered already by `er_style_data_overlay()`. Follows the same fill
  # (box) / color (jitter) split for strata that `er_style_model_ribbonline()`
  # uses for ribbon/line, so `.polish_labels()`/`.polish_legends()` need
  # no special-casing.
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
    .set_label(dat[[strata$name]], strata$label)
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

  withr::with_seed( # TODO: setting seed here isn't correct
    seed = config$seed,
    code = {
      geoms <- list(
        ggplot2::geom_boxplot(
          data = dat,
          mapping = box_map,
          orientation = "y",
          width = 0.6,
          alpha = 0.4,
          outlier.shape = NA, # raw points are already shown via the jitter layer
          key_glyph = theme$draw_key
        ),
        ggplot2::geom_jitter(
          data = dat,
          mapping = jitter_map,
          width = 0,
          height = if (stratify) 0.3 else 0.15,
          size = 1,
          alpha = 0.6,
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
    }
  )

  return(geoms)
}, layout = "panel", layer = "data")


#' @rdname er_style_data
#' @export
er_style_data_overlay <- er_style_tag(function(data, config, stratify, exposure, response, strata, theme) {

  # unlike `er_style_data_boxjitter()`, this builder draws points at their
  # true (exposure, response) coordinates and its output is meant to be
  # added to the *base* plot (see `.build_overlay_geoms()` in
  # R/er-plot-build.R), not a standalone above/below panel -- so there's
  # no response-type dispatch on which points to filter (no binary
  # upper/lower split) and no `color_role` juggling: color, when mapped at
  # all, always means strata, since the response is already shown via
  # y-position.
  if (stratify == TRUE) {
    .set_label(data[[strata$name]], strata$label)
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
  jitter_height <- if (config$response_type == "binary") 0.05 else 0

  withr::with_seed( # TODO: setting seed here isn't correct
    seed = config$seed,
    code = {
      geoms <- list(
        ggplot2::geom_jitter(
          data = data,
          mapping = plot_map,
          width = 0,
          height = jitter_height,
          alpha = 0.4,
          size = 1,
          key_glyph = theme$draw_key
        )
      )
    }
  )

  return(geoms)
}, layout = "overlay", layer = "data")


#' @rdname er_style_data
#' @export
er_style_data_hex <- er_style_tag(function(data, config, stratify, exposure, response, strata, theme) {

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
  # doesn't map `fill`, e.g. `er_style_model_line()` (color only). The
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
      bins = 30,
      key_glyph = theme$draw_key
    )
  )

  return(geoms)
}, layout = "overlay", fill_role = "density", layer = "data")
