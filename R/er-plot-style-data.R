
#' Data layer builders for exposure-response plots
#'
#' @param data The original data frame
#' @param config Configuration for the specific plot
#' @param stratify Logical indicating whether to stratify
#' @param exposure Exposure variable
#' @param response Response variable
#' @param strata Stratification variable
#' @param theme Theme components
#' @param ... Additional named arguments forwarded from
#'   [er_plot_add_data()]'s own `...`; see [er_style()]'s "Passing extra
#'   arguments to a builder" section.
#' @param jitter_height Vertical jitter applied to the raw points, in
#'   response units (`er_style_data_overlay()`/`er_style_data_boxjitter()`
#'   only). Defaults to `NULL`, which reproduces the previous fixed
#'   behaviour: for `er_style_data_overlay()`, `0.05` for a binary
#'   response and `0` otherwise; for `er_style_data_boxjitter()`, `0.3`
#'   when stratified and `0.15` otherwise. An explicit value overrides
#'   this for both cases uniformly.
#' @param alpha Point transparency for `er_style_data_overlay()`'s raw
#'   points (`0`-`1`). Default `0.4`, matching the previous fixed value.
#' @param size Point size for `er_style_data_overlay()`'s raw points.
#'   Default `1`, matching the previous fixed value.
#' @param box_width Width of `er_style_data_boxjitter()`'s boxplot.
#'   Default `0.6`, matching the previous fixed value.
#' @param box_alpha Transparency of `er_style_data_boxjitter()`'s
#'   boxplot fill (`0`-`1`). Default `0.4`, matching the previous fixed
#'   value.
#' @param show_outliers Whether `er_style_data_boxjitter()`'s boxplot
#'   should draw its own outlier points (`geom_boxplot()`'s usual
#'   default), rather than suppressing them. Default `FALSE` (outliers
#'   hidden), matching the previous fixed behaviour -- raw points are
#'   already shown via the jitter layer, so a boxplot's own outlier
#'   points are normally redundant.
#' @param jitter_size Point size for `er_style_data_boxjitter()`'s
#'   jittered points. Default `1`, matching the previous fixed value.
#' @param jitter_alpha Point transparency for
#'   `er_style_data_boxjitter()`'s jittered points (`0`-`1`). Default
#'   `0.6`, matching the previous fixed value.
#' @param bins Number of hex bins along each axis for
#'   `er_style_data_hex()`'s [ggplot2::geom_hex()]. Default `30`,
#'   matching the previous fixed value.
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

  # raw points are already shown via the jitter layer, so the boxplot's
  # own outlier points are redundant by default
  outlier_shape <- if (show_outliers) 19 else NA

  if (is.null(jitter_height)) jitter_height <- if (stratify) 0.3 else 0.15

  withr::with_seed( # TODO: setting seed here isn't correct
    seed = config$seed,
    code = {
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
          width = 0,
          height = jitter_height,
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
  if (is.null(jitter_height)) {
    jitter_height <- if (config$response_type == "binary") 0.05 else 0
  }

  withr::with_seed( # TODO: setting seed here isn't correct
    seed = config$seed,
    code = {
      geoms <- list(
        ggplot2::geom_jitter(
          data = data,
          mapping = plot_map,
          width = 0,
          height = jitter_height,
          alpha = alpha,
          size = size,
          key_glyph = theme$draw_key
        )
      )
    }
  )

  return(geoms)
}, layout = "overlay", layer = "data")


#' @rdname er_style_data
#' @export
er_style_data_hex <- er_style_tag(function(data, config, stratify, exposure, response, strata, theme, ...,
                                            bins = 30) {

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
      bins = bins,
      key_glyph = theme$draw_key
    )
  )

  return(geoms)
}, layout = "overlay", fill_role = "density", layer = "data")
