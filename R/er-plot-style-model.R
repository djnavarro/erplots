
#' Model curve builders for exposure-response plots
#'
#' @param data The original data frame
#' @param config Configuration for the specific plot
#' @param stratify Logical indicating whether to stratify
#' @param exposure Exposure variable
#' @param response Response variable
#' @param strata Stratification variable
#' @param theme Theme components
#' @param ... Additional named arguments forwarded from
#'   [er_plot_add_model()]'s own `...`; see [er_style()]'s "Passing extra
#'   arguments to a builder" section. `er_style_model_spaghetti()` reads a
#'   `seed` from here (falling back to `config$seed` -- currently always
#'   `NULL` for the model layer -- when none is supplied) to pass to
#'   [er_simulate()], letting a caller override erglm's auto-selected seed.
#'
#' @details Builders for the `model` layer ([er_plot_add_model()]), which
#' draws the fitted curve (and, where applicable, its uncertainty) over
#' the exposure range: `er_style_model_ribbonline()` (ribbon plus line, the
#' default), `er_style_model_line()` (line only, no ribbon), and
#' `er_style_model_spaghetti()` (a spaghetti plot of simulated draws, for
#' models that implement [er_simulate()]). All three are tagged
#' `er_style_tag(fn, layer = "model")`, so [er_plot_add_model()]
#' errors informatively if handed one of these tagged for a different
#' layer entirely (e.g. `"summary"`, meant for [er_plot_add_summary()]).
#'
#' See [er_style()] for the shared builder interface these functions
#' implement, including how to write a custom builder of your own.
#'
#' @returns A geom, or a list of geoms; see [er_style()].
#'
#' @examples
#' if (requireNamespace("erglm", quietly = TRUE)) {
#'   library(erglm)
#'   mod <- erglm_model(ae1 ~ aucss, erglm_data, family = binomial())
#'
#'   # er_style_model_ribbonline(): ribbon + line, the default
#'   erglm_data |>
#'     er_plot(aucss, ae1) |>
#'     er_plot_add_model(mod, style = er_style_model_ribbonline) |>
#'     plot()
#'
#'   # er_style_model_line(): line only, no ribbon
#'   erglm_data |>
#'     er_plot(aucss, ae1) |>
#'     er_plot_add_model(mod, style = er_style_model_line) |>
#'     plot()
#'
#'   # er_style_model_spaghetti(): simulated draws instead of a ribbon;
#'   # `seed` is forwarded to `er_simulate()` via `...`
#'   erglm_data |>
#'     er_plot(aucss, ae1) |>
#'     er_plot_add_model(mod, style = er_style_model_spaghetti, seed = 4821) |>
#'     plot()
#' }
#'
#' @name er_style_model
#' @seealso [er_style()]
NULL

#' @rdname er_style_model
#' @export
er_style_model_ribbonline <- function(data, config, stratify, exposure, response, strata, theme, ...) {

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
      key_glyph = theme$draw_key
    )

    model_line <- ggplot2::geom_path(
      data = config$predictions,
      mapping = ggplot2::aes(
        x = .data[[exposure$name]], 
        y = fit_resp
      ),
      linewidth = 1,
      key_glyph = theme$draw_key
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
      key_glyph = theme$draw_key
    )

    model_line <- ggplot2::geom_path(
      data = config$predictions,
      mapping = ggplot2::aes(
        x = .data[[exposure$name]], 
        y = fit_resp,
        color = .data[[strata$name]]
      ),
      linewidth = 1,
      key_glyph = theme$draw_key
    )    
  }
  
  geoms <- list(model_ribbon, model_line)
  return(geoms)
}
er_style_model_ribbonline <- er_style_tag(er_style_model_ribbonline, layer = "model")


#' @rdname er_style_model
#' @export
er_style_model_line <- function(data, config, stratify, exposure, response, strata, theme, ...) {

  if (stratify == FALSE) {

    model_line <- ggplot2::geom_path(
      data = config$predictions,
      mapping = ggplot2::aes(
        x = .data[[exposure$name]],
        y = fit_resp
      ),
      linewidth = 1,
      key_glyph = theme$draw_key
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
      key_glyph = theme$draw_key
    )
  }

  geoms <- list(model_line)
  return(geoms)
}
er_style_model_line <- er_style_tag(er_style_model_line, layer = "model")


#' @rdname er_style_model
#' @export
er_style_model_spaghetti <- function(data, config, stratify, exposure, response, strata, theme, ...) {

  # a user-supplied `seed` (via `er_plot_add_model()`'s `...`) takes
  # priority over `config$seed` (always `NULL` for the model layer at
  # present); this is the concrete motivating case for builder `...`
  # passthrough -- see `?er_style`'s "Passing extra arguments to a
  # builder" section -- since it lets a caller silence erglm's
  # auto-selected-seed message with a reproducible seed of their own.
  dots <- rlang::list2(...)
  seed <- dots$seed %||% config$seed

  newdata <- config$predictions |> 
    dplyr::select(dplyr::all_of(c(exposure$name, strata$name))) |> 
    dplyr::distinct()

  sim <- er_simulate(config$model, newdata = newdata, nsim = 100L, seed = seed)

  if (is.null(sim)) {
    rlang::inform(paste0(
      "`er_simulate()` is not implemented for objects of class <",
      paste(class(config$model), collapse = "/"),
      ">; falling back to `style = er_style_model_ribbonline`."
    ))
    return(er_style_model_ribbonline(data, config, stratify, exposure, response, strata, theme, ...))
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
      key_glyph = theme$draw_key
    )

    model_line <- ggplot2::geom_path(
      data = config$predictions,
      mapping = ggplot2::aes(
        x = .data[[exposure$name]], 
        y = fit_resp
      ),
      linewidth = 1,
      key_glyph = theme$draw_key
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
      key_glyph = theme$draw_key
    )

    model_line <- ggplot2::geom_path(
      data = config$predictions,
      mapping = ggplot2::aes(
        x = .data[[exposure$name]], 
        y = fit_resp,
        color = .data[[strata$name]]
      ),
      linewidth = 1,
      key_glyph = theme$draw_key
    )    
  }
  
  geoms <- list(model_spaghetti, model_line)
  return(geoms)
}
er_style_model_spaghetti <- er_style_tag(er_style_model_spaghetti, layer = "model")
