
#' @rdname er_partial
#' @export
build_data_jitter <- er_layout(function(data, config, stratify, exposure, response, strata, style) {

  if (config$panel == "upper") dat <- data |> dplyr::filter(.data[[response$name]] == 1)
  if (config$panel == "lower") dat <- data |> dplyr::filter(.data[[response$name]] == 0)
  
  if (stratify == TRUE) {
    .set_label(dat[[strata$name]], strata$label)
    plot_map <- ggplot2::aes(
      x = .data[[exposure$name]], 
      y = 0, 
      color = .data[[strata$name]]
    )
  } 
  if (stratify == FALSE) {
    plot_map <- ggplot2::aes(
      x = .data[[exposure$name]], 
      y = 0
    )
  }

  withr::with_seed( # TODO: setting seed here isn't correct
    seed = config$seed,
    code = {
      geoms <- list( 
        ggplot2::geom_jitter(
          data = dat,
          mapping = plot_map,
          width = 0,
          height = 0.1,
          size = 1,
          key_glyph = style$draw_key
        ),
        ggplot2::coord_cartesian(
          xlim = exposure$limits, 
          ylim = c(-0.1, 0.1), 
          clip = "off"
        ),
        ggplot2::scale_y_continuous(
          breaks = NULL, 
          minor_breaks = NULL
        )
      )
    }
  )

  return(geoms)
}, layout = "panel")


#' @rdname er_partial
#' @export
build_data_overlay <- er_layout(function(data, config, stratify, exposure, response, strata, style) {

  # unlike `build_data_jitter()`/`build_data_color()`, this builder draws
  # points at their true (exposure, response) coordinates and its output
  # is meant to be added to the *base* plot (see `.build_overlay_geoms()`
  # in R/er-plot-build.R), not a standalone above/below panel -- so there's
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


#' @rdname er_partial
#' @export
build_data_color <- er_layout(function(data, config, stratify, exposure, response, strata, style) {

  # continuous/count-response variant of `build_data_jitter()` -- see
  # `PLAN.md`'s "Continuous-response data strip". There's no binary
  # partition to filter on, so `config$panel` here names either the
  # single unstratified panel ("data") or, when stratified, the stratum
  # level this panel belongs to; the `strata`/color aesthetic is already
  # spoken for by the response value (`config$color_role == "response"`,
  # set in `.part_data()`), so stratification falls back to one panel per
  # stratum level instead of a shared color aesthetic.
  if (stratify == TRUE) {
    dat <- data |> dplyr::filter(.data[[strata$name]] == config$panel)
  } else {
    dat <- data
  }

  plot_map <- ggplot2::aes(
    x = .data[[exposure$name]],
    y = 0,
    color = .data[[response$name]]
  )

  withr::with_seed( # TODO: setting seed here isn't correct
    seed = config$seed,
    code = {
      geoms <- list(
        ggplot2::geom_jitter(
          data = dat,
          mapping = plot_map,
          width = 0,
          height = 0.1,
          size = 1,
          key_glyph = style$draw_key
        ),
        ggplot2::coord_cartesian(
          xlim = exposure$limits,
          ylim = c(-0.1, 0.1),
          clip = "off"
        ),
        ggplot2::scale_y_continuous(
          breaks = NULL,
          minor_breaks = NULL
        )
      )
    }
  )

  return(geoms)
}, layout = "panel")
