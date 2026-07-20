
#' @rdname er_partial
#' @export
build_data_jitter <- function(data, config, stratify, exposure, response, strata, style) {

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
}


#' @rdname er_partial
#' @export
build_data_color <- function(data, config, stratify, exposure, response, strata, style) {

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
}
