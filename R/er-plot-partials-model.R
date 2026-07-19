

#' @rdname er_partial
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




#' @rdname er_partial
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
      fill = "grey40",
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
      fill = "grey40",
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
