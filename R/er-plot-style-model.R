
#' Model curve builders for exposure-response plots
#'
#' Builder functions for the `model` layer ([er_plot_add_model()]), drawing
#' the fitted exposure-response curve as a ribbon-and-line, a line alone, or a
#' spaghetti plot of simulated draws.
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
#' @param ribbon_fill Fill colour for `er_style_model_ribbonline()`'s
#'   ribbon. Only takes effect when the layer is unstratified -- a
#'   stratified ribbon already maps `fill` to the strata variable, so
#'   this argument is ignored in that case. Default `"grey40"`.
#' @param ribbon_alpha Transparency of `er_style_model_ribbonline()`'s
#'   ribbon (`0`-`1`), stratified or not. Default `0.25`.
#' @param ribbon_edges Whether `er_style_model_ribbonline()` additionally
#'   draws a dashed [ggplot2::geom_path()] along the ribbon's own
#'   `ci_lower`/`ci_upper` bounds, on top of the shaded ribbon fill.
#'   Default `FALSE` (ribbon fill only).
#' @param linewidth Width of the fitted curve's line, for all three
#'   model builders (`er_style_model_ribbonline()`/`_line()`'s single
#'   curve, `er_style_model_spaghetti()`'s mean curve drawn on top of
#'   the spaghetti draws). Default `1`.
#' @param alpha Transparency of `er_style_model_spaghetti()`'s individual
#'   simulated draws (`0`-`1`). Defaults to `NULL`, which uses `0.1`
#'   unstratified and `0.25` stratified. An explicit value overrides this
#'   for both cases uniformly.
#' @param nsim Number of simulated draws for `er_style_model_spaghetti()`,
#'   passed to [er_simulate()]. Default `100L`.
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
#'
#'   # overriding a builder's own visual defaults: a thicker, less
#'   # saturated ribbon with its bounds outlined, and fewer/fainter
#'   # spaghetti draws
#'   erglm_data |>
#'     er_plot(aucss, ae1) |>
#'     er_plot_add_model(
#'       mod,
#'       style = er_style_model_ribbonline,
#'       ribbon_fill = "steelblue",
#'       ribbon_alpha = 0.15,
#'       ribbon_edges = TRUE,
#'       linewidth = 1.5
#'     ) |>
#'     plot()
#'
#'   erglm_data |>
#'     er_plot(aucss, ae1) |>
#'     er_plot_add_model(
#'       mod,
#'       style = er_style_model_spaghetti,
#'       seed = 4821,
#'       nsim = 40L,
#'       alpha = 0.05
#'     ) |>
#'     plot()
#' }
#'
#' @name er_style_model
#' @seealso [er_style()]
NULL

#' @rdname er_style_model
#' @export
er_style_model_ribbonline <- function(data, config, stratify, exposure, response, strata, theme, ...,
                                       ribbon_fill = "grey40",
                                       ribbon_alpha = 0.25,
                                       ribbon_edges = FALSE,
                                       linewidth = 1) {

  if (stratify == FALSE) {

    model_ribbon <- ggplot2::geom_ribbon(
      data = config$predictions,
      mapping = ggplot2::aes(
        x = .data[[exposure$name]],
        ymin = ci_lower,
        ymax = ci_upper
      ),
      fill = ribbon_fill,
      alpha = ribbon_alpha,
      key_glyph = theme$draw_key
    )

    model_line <- ggplot2::geom_path(
      data = config$predictions,
      mapping = ggplot2::aes(
        x = .data[[exposure$name]], 
        y = fit_resp
      ),
      linewidth = linewidth,
      key_glyph = theme$draw_key
    )

    edge_map_lower <- ggplot2::aes(x = .data[[exposure$name]], y = ci_lower)
    edge_map_upper <- ggplot2::aes(x = .data[[exposure$name]], y = ci_upper)
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
      alpha = ribbon_alpha,
      key_glyph = theme$draw_key
    )

    model_line <- ggplot2::geom_path(
      data = config$predictions,
      mapping = ggplot2::aes(
        x = .data[[exposure$name]], 
        y = fit_resp,
        color = .data[[strata$name]]
      ),
      linewidth = linewidth,
      key_glyph = theme$draw_key
    )

    edge_map_lower <- ggplot2::aes(
      x = .data[[exposure$name]], y = ci_lower, color = .data[[strata$name]]
    )
    edge_map_upper <- ggplot2::aes(
      x = .data[[exposure$name]], y = ci_upper, color = .data[[strata$name]]
    )
  }

  geoms <- list(model_ribbon)

  # `ribbon_edges` is only ever included when requested, rather than as a
  # pair of `NULL` placeholders that rely on `ggplot2::ggplot_add.NULL`'s
  # silent no-op -- unlike the quantile layer's `_vlines` variants, this
  # builder's *own* return length is asserted on directly in tests, so a
  # `NULL`-padded list would be a visible (if harmless) behaviour change.
  if (ribbon_edges) {
    geoms <- c(
      geoms,
      list(
        ggplot2::geom_path(
          data = config$predictions,
          mapping = edge_map_lower,
          linetype = "dashed",
          key_glyph = theme$draw_key
        ),
        ggplot2::geom_path(
          data = config$predictions,
          mapping = edge_map_upper,
          linetype = "dashed",
          key_glyph = theme$draw_key
        )
      )
    )
  }

  geoms <- c(geoms, list(model_line))
  return(geoms)
}
er_style_model_ribbonline <- er_style_tag(er_style_model_ribbonline, layer = "model")


#' @rdname er_style_model
#' @export
er_style_model_line <- function(data, config, stratify, exposure, response, strata, theme, ...,
                                 linewidth = 1) {

  if (stratify == FALSE) {

    model_line <- ggplot2::geom_path(
      data = config$predictions,
      mapping = ggplot2::aes(
        x = .data[[exposure$name]],
        y = fit_resp
      ),
      linewidth = linewidth,
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
      linewidth = linewidth,
      key_glyph = theme$draw_key
    )
  }

  geoms <- list(model_line)
  return(geoms)
}
er_style_model_line <- er_style_tag(er_style_model_line, layer = "model")


#' @rdname er_style_model
#' @export
er_style_model_spaghetti <- function(data, config, stratify, exposure, response, strata, theme, ...,
                                      alpha = NULL,
                                      linewidth = 1,
                                      nsim = 100L) {

  # a user-supplied `seed` (via `er_plot_add_model()`'s `...`) takes
  # priority over `config$seed` (always `NULL` for the model layer at
  # present); this is the concrete motivating case for builder `...`
  # passthrough -- see `?er_style`'s "Passing extra arguments to a
  # builder" section -- since it lets a caller silence erglm's
  # auto-selected-seed message with a reproducible seed of their own.
  dots <- rlang::list2(...)
  seed <- dots$seed %||% config$seed

  # unlike `seed`, `alpha` is response-independent enough to be promoted
  # to its own explicit argument rather than staying in `...`; `NULL`
  # reproduces the previous fixed-per-stratify-status default.
  if (is.null(alpha)) alpha <- if (stratify) 0.25 else 0.1

  newdata <- config$predictions |> 
    dplyr::select(dplyr::all_of(c(exposure$name, strata$name))) |> 
    dplyr::distinct()

  sim <- er_simulate(config$model, newdata = newdata, nsim = nsim, seed = seed)

  if (is.null(sim)) {
    rlang::inform(paste0(
      "`er_simulate()` is not implemented for objects of class <",
      paste(class(config$model), collapse = "/"),
      ">; falling back to `style = er_style_model_ribbonline`."
    ))
    return(er_style_model_ribbonline(data, config, stratify, exposure, response, strata, theme, ..., linewidth = linewidth))
  }

  if (stratify == FALSE) {

    model_spaghetti <- ggplot2::geom_path(
      data = sim,
      mapping = ggplot2::aes(
        x = .data[[exposure$name]],
        y = .data[["fit_resp"]],
        group = .data[["sim_id"]]
      ),
      alpha = alpha,
      key_glyph = theme$draw_key
    )

    model_line <- ggplot2::geom_path(
      data = config$predictions,
      mapping = ggplot2::aes(
        x = .data[[exposure$name]], 
        y = fit_resp
      ),
      linewidth = linewidth,
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
      alpha = alpha,
      key_glyph = theme$draw_key
    )

    model_line <- ggplot2::geom_path(
      data = config$predictions,
      mapping = ggplot2::aes(
        x = .data[[exposure$name]], 
        y = fit_resp,
        color = .data[[strata$name]]
      ),
      linewidth = linewidth,
      key_glyph = theme$draw_key
    )    
  }
  
  geoms <- list(model_spaghetti, model_line)
  return(geoms)
}
er_style_model_spaghetti <- er_style_tag(er_style_model_spaghetti, layer = "model")
