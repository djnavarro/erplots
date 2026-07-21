
#' Model curve builders for exposure-response plots
#'
#' @param data The original data frame
#' @param config Configuration for the specific plot
#' @param stratify Logical indicating whether to stratify
#' @param exposure Exposure variable
#' @param response Response variable
#' @param strata Stratification variable
#' @param style Style components
#'
#' @details Builders for the `model` layer ([er_plot_show_model()]), which
#' draws the fitted curve (and, where applicable, its uncertainty) over
#' the exposure range: `build_model_ribbonline()` (ribbon plus line, the
#' default), `build_model_line()` (line only, no ribbon), and
#' `build_model_spaghetti()` (a spaghetti plot of simulated draws, for
#' models that implement [er_simulate()]).
#'
#' See [er_partial()] for the shared builder interface these functions
#' implement, including how to write a custom builder of your own.
#'
#' @returns A geom, or a list of geoms; see [er_partial()].
#'
#' @name build_model
#' @seealso [er_partial()]
NULL

#' @rdname build_model
#' @export
build_model_ribbonline <- function(data, config, stratify, exposure, response, strata, style) {

  if (stratify == FALSE) {

    model_ribbon <- ggplot2::geom_ribbon(
      data = config$predictions,
      mapping = ggplot2::aes(
        x = .data[[exposure$name]],
        ymin = ci_lower,
        ymax = ci_upper
      ),
      fill = "grey40",
      alpha = .25,
      key_glyph = style$draw_key
    )

    model_line <- ggplot2::geom_path(
      data = config$predictions,
      mapping = ggplot2::aes(
        x = .data[[exposure$name]], 
        y = fit_resp
      ),
      linewidth = 1,
      key_glyph = style$draw_key
    )
  }

  if (stratify == TRUE) {

    model_ribbon <- ggplot2::geom_ribbon(
      data = config$predictions,
      mapping = ggplot2::aes(
        x = .data[[exposure$name]],
        fill = .data[[strata$name]],
        ymin = ci_lower,
        ymax = ci_upper
      ),
      alpha = .25,
      key_glyph = style$draw_key
    )

    model_line <- ggplot2::geom_path(
      data = config$predictions,
      mapping = ggplot2::aes(
        x = .data[[exposure$name]], 
        y = fit_resp,
        color = .data[[strata$name]]
      ),
      linewidth = 1,
      key_glyph = style$draw_key
    )    
  }
  
  geoms <- list(model_ribbon, model_line)
  return(geoms)
}




#' @rdname build_model
#' @export
build_model_line <- function(data, config, stratify, exposure, response, strata, style) {

  if (stratify == FALSE) {

    model_line <- ggplot2::geom_path(
      data = config$predictions,
      mapping = ggplot2::aes(
        x = .data[[exposure$name]],
        y = fit_resp
      ),
      linewidth = 1,
      key_glyph = style$draw_key
    )
  }

  if (stratify == TRUE) {

    model_line <- ggplot2::geom_path(
      data = config$predictions,
      mapping = ggplot2::aes(
        x = .data[[exposure$name]],
        y = fit_resp,
        color = .data[[strata$name]]
      ),
      linewidth = 1,
      key_glyph = style$draw_key
    )
  }

  geoms <- list(model_line)
  return(geoms)
}


#' @rdname build_model
#' @export
build_model_spaghetti <- function(data, config, stratify, exposure, response, strata, style) {

  newdata <- config$predictions |> 
    dplyr::select(dplyr::all_of(c(exposure$name, strata$name))) |> 
    dplyr::distinct()

  sim <- er_simulate(config$model, newdata = newdata, nsim = 100L, seed = config$seed)

  if (is.null(sim)) {
    rlang::inform(paste0(
      "`er_simulate()` is not implemented for objects of class <",
      paste(class(config$model), collapse = "/"),
      ">; falling back to `style = \"ribbonline\"`."
    ))
    return(build_model_ribbonline(data, config, stratify, exposure, response, strata, style))
  }

  if (stratify == FALSE) {

    model_spaghetti <- ggplot2::geom_path(
      data = sim,
      mapping = ggplot2::aes(
        x = .data[[exposure$name]],
        y = .data[["fit_resp"]],
        group = .data[["sim_id"]]
      ),
      alpha = .1,
      key_glyph = style$draw_key
    )

    model_line <- ggplot2::geom_path(
      data = config$predictions,
      mapping = ggplot2::aes(
        x = .data[[exposure$name]], 
        y = fit_resp
      ),
      linewidth = 1,
      key_glyph = style$draw_key
    )
  }

  if (stratify == TRUE) {

    model_spaghetti <- ggplot2::geom_path(
      data = sim |> 
        dplyr::mutate(sim_id2 = paste(.data[["sim_id"]], .data[[strata$name]])),
      mapping = ggplot2::aes(
        x = .data[[exposure$name]],
        y = .data[["fit_resp"]],
        color = .data[[strata$name]],
        group = .data[["sim_id2"]]
      ),
      alpha = .25,
      key_glyph = style$draw_key
    )

    model_line <- ggplot2::geom_path(
      data = config$predictions,
      mapping = ggplot2::aes(
        x = .data[[exposure$name]], 
        y = fit_resp,
        color = .data[[strata$name]]
      ),
      linewidth = 1,
      key_glyph = style$draw_key
    )    
  }
  
  geoms <- list(model_spaghetti, model_line)
  return(geoms)
}
