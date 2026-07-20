
#' @rdname er_partial
#' @export
build_data_boxjitter <- er_layout(function(data, config, stratify, exposure, response, strata, style) {

  # binary-response-only panel builder: filters to responders (upper
  # panel, response == 1) or non-responders (lower panel, response == 0),
  # then draws a boxplot of the exposure values underneath the jittered
  # points, so the panel shows the *distribution* of exposure conditional
  # on response (not just raw points) -- see PLAN.md's "Data layer
  # panel-based builders" section for why this replaced the older
  # `build_data_jitter()`, whose typical use case turned out to be
  # covered already by `build_data_overlay()`. Follows the same fill
  # (box) / color (jitter) split for strata that `build_model_ribbonline()`
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
  # discrete row automatically (the same trick `build_group_boxplot()`
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
          key_glyph = style$draw_key
        ),
        ggplot2::geom_jitter(
          data = dat,
          mapping = jitter_map,
          width = 0,
          height = if (stratify) 0.3 else 0.15,
          size = 1,
          alpha = 0.6,
          key_glyph = style$draw_key
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
}, layout = "panel")


#' @rdname er_partial
#' @export
build_data_overlay <- er_layout(function(data, config, stratify, exposure, response, strata, style) {

  # unlike `build_data_boxjitter()`, this builder draws points at their
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
          key_glyph = style$draw_key
        )
      )
    }
  )

  return(geoms)
}, layout = "overlay")
