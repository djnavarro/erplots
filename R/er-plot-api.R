
#' The exposure-response plotting mini-language
#'
#' `er_plot()` creates an (empty) plot object of S3 class `er_plot`. Build
#' up a plot by piping it through one or more layer functions --
#' [er_plot_add_model()] (fitted-model curve/ribbon),
#' [er_plot_add_summary()] (a summary annotation, e.g. a p-value or
#' descriptive label),
#' [er_plot_add_quantiles()] (exposure-quantile-binned response summary),
#' [er_plot_add_data()] (raw observations, by default overlaid on the
#' model panel), and/or
#' [er_plot_add_groups()] (grouped exposure-distribution panels) -- then
#' render with `plot()`/`print()`, or build the ggplot2/patchwork objects
#' directly with [er_plot_build()]. `er_plot()` never fits a model itself;
#' any model implementing the small interface in [er_model_interface] can
#' be passed to [er_plot_add_model()].
#'
#' @details
#' # Layers are either singleton or additive
#'
#' [er_plot_add_model()], [er_plot_add_summary()],
#' [er_plot_add_quantiles()], and
#' [er_plot_add_data()] are **singleton**: calling one of them twice
#' on the same object overwrites the first call's result rather than
#' combining the two. [er_plot_add_groups()] is **additive**: each call
#' adds another grouped-distribution panel alongside any already added,
#' rather than replacing them. This asymmetry is deliberate, not
#' accidental -- there is only one "the model" and one "the quantile
#' summary" to show per plot, but many legitimate ways to slice the
#' exposure distribution by different grouping variables. See `PLAN.md`'s
#' "Mini-language architecture review" for the design discussion,
#' including the one flagged future exception: overlaying two model
#' curves for comparison isn't currently supported, but is the one
#' singleton layer where an additive variant might eventually make sense.
#'
#' # Stratification
#'
#' `stratify_by` (set once, here in `er_plot()`) declares a single
#' discrete variable used to split layers by color/fill, with one shared,
#' deduplicated legend across the whole composed plot. Each layer
#' function's `keep_strata` argument controls whether *that* layer
#' actually uses the stratification (it defaults to `TRUE` whenever
#' `stratify_by` was set, `FALSE` otherwise). [er_plot_add_data()] is a
#' partial exception to the "always color/fill" rule for a
#' continuous/count response: its color aesthetic is already spoken for
#' by the response value itself, so stratification falls back to one
#' panel per stratum level instead of a shared legend -- see its own
#' documentation and `PLAN.md` for the general "a layer's own encoding
#' takes precedence" rule this follows.
#'
#' # Response type
#'
#' `response_type` (set once, here in `er_plot()`) governs the response's
#' scale (`object$response$limits`) and which summary/CI method
#' [er_plot_add_quantiles()] and [er_vpc_plot()] use; see the
#' `response_type` parameter below and [er_plot_add_quantiles()]'s own
#' documentation for the specifics of each response type's summary
#' statistic.
#'
#' @param data Observed data
#' @param exposure Exposure variable (one variable, unquoted). Must name a
#'   numeric column of `data`.
#' @param response Response variable (one variable, unquoted). Must name a
#'   column of `data`.
#' @param stratify_by Stratification variable used for color and fill (one
#'   variable, unquoted); see "Stratification" above. Must name a column of
#'   `data` if supplied.
#' @param response_type One of `"auto"` (the default), `"binary"`,
#'   `"continuous"`, or `"count"`. Governs response-scale defaults (e.g.
#'   axis limits) and which summary/CI method the quantile and VPC layers
#'   use. When `"auto"`, the response column is classified as `"binary"`
#'   if it is logical or takes only values in `{0, 1}`, and `"continuous"`
#'   otherwise -- this means a count (Poisson-style) response, e.g. an
#'   adverse-event count, auto-detects as `"continuous"` (counts aren't
#'   confined to `{0, 1}`) and is summarised as an approximately-continuous
#'   quantity (bin mean plus a t-interval). `"auto"` never resolves to
#'   `"count"`: pass `response_type = "count"` explicitly for a genuine
#'   count response to instead get bin mean plus an *exact* Poisson
#'   interval (see [ci_poisson()]), which -- unlike the t-interval
#'   approximation -- never produces a negative lower bound. See
#'   `PLAN.md`'s design decision (4) for the rationale. Explicitly
#'   declaring `response_type = "binary"` for a response column that
#'   isn't actually confined to `{0, 1}` (or logical) triggers a warning
#'   -- rows with an out-of-range value are silently excluded from the
#'   quantile layer's rate calculation rather than erroring, so this is
#'   a warning rather than an error, but the resulting rate is computed
#'   over a smaller effective denominator than the row count would
#'   suggest.
#'
#' @returns An (empty) plot object of class `er_plot`
#'
#' @examples
#' if (requireNamespace("erglm", quietly = TRUE)) {
#' library(erglm)
#' mod <- erglm_model(ae1 ~ aucss, erglm_data, family = binomial())
#'
#' erglm_data |>
#'   er_plot(aucss, ae1) |>
#'   er_plot_add_model(mod) |>
#'   er_plot_add_quantiles() |>
#'   er_plot_add_groups(aucss) |>
#'   plot()
#' }
#'
#' @seealso [er_plot_add_model()], [er_plot_add_summary()],
#'   [er_plot_add_quantiles()],
#'   [er_plot_add_data()], [er_plot_add_groups()],
#'   [er_plot_build()], [er_plot_theme()], [er_model_interface]
#'
#' @name er_plot
NULL


# setup -----------------------------------------------------------------------

#' @rdname er_plot
#' @export
er_plot <- function(data, exposure, response, stratify_by = NULL, response_type = "auto") {

  response_type <- match.arg(response_type, c("auto", "binary", "continuous", "count"))

  # validate that exposure/response/stratify_by actually name columns of
  # `data` -- without this, a typo'd column name silently produces
  # `NULL`/`Inf`/`-Inf` limits (via `data[[name]]` returning `NULL`) rather
  # than an error at the point of the actual mistake; see PLAN.md's
  # "stress-test findings" section
  exposure_name <- rlang::as_name(rlang::enquo(exposure))
  response_name <- rlang::as_name(rlang::enquo(response))
  strata_quo <- rlang::enquo(stratify_by)
  strata_name <- if (!rlang::quo_is_null(strata_quo)) rlang::as_name(strata_quo) else NULL

  missing_cols <- setdiff(c(exposure_name, response_name, strata_name), names(data))
  if (length(missing_cols) > 0) {
    rlang::abort(c(
      sprintf(
        "Column%s not found in `data`: %s.",
        if (length(missing_cols) > 1) "s" else "",
        paste0("`", missing_cols, "`", collapse = ", ")
      ),
      "i" = "Check that `exposure`/`response`/`stratify_by` reference actual columns of `data`."
    ))
  }

  # validate that exposure is numeric -- without this, a factor/character/
  # logical exposure column fails much later with an opaque low-level error
  # (e.g. "'range' not meaningful for factors" from the `range()` call
  # below), rather than a clear message naming the actual problem; see
  # PLAN.md's "stress-test findings" section
  if (!is.numeric(data[[exposure_name]])) {
    rlang::abort(c(
      sprintf(
        "`exposure` (`%s`) must be numeric, not %s.",
        exposure_name, paste(class(data[[exposure_name]]), collapse = "/")
      ),
      "i" = "erplots' quantile-binning and model-prediction grid assume a numeric exposure axis."
    ))
  }

  # empty plot object
  object <- structure(
    list(
      data  = NULL,
      exposure = .plot_variable(role = "exposure"),
      response = .plot_variable(role = "response"),
      strata = .plot_variable(role = "strata"),
      layer = list(
        model    = NULL, 
        summary  = NULL,
        quantile = NULL, 
        data     = NULL,
        overlay  = NULL,
        group    = NULL
      ),
      plot = list(
        base = NULL, 
        data = NULL, 
        group = NULL
      ),
      theme = list(),
      output = NULL 
    ),
    class = "er_plot"
  )

  # store observed data
  object$data <- data

  # store variable names
  object$exposure$name <- exposure_name
  object$response$name <- response_name
  if (!is.null(strata_name)) object$strata$name <- strata_name
  
  # store (default) variable labels
  object$exposure$label <- .get_label(object$data[[object$exposure$name]]) %||% object$exposure$name
  object$response$label <- .get_label(object$data[[object$response$name]]) %||% object$response$name    
  if (!is.null(object$strata$name)) {
    object$strata$label <- .get_label(object$data[[object$strata$name]]) %||% object$strata$name
  }

  # resolve and store response type ("binary", "continuous", or "count";
  # "auto" only ever resolves to "binary"/"continuous" -- "count" must be
  # declared explicitly, see `?er_plot`'s `response_type` docs)
  if (response_type == "auto") {
    response_type <- .detect_response_type(object$data[[object$response$name]])
  }
  object$response$type <- response_type

  # `response_type = "binary"` was explicitly declared but the response
  # column isn't actually confined to {0, 1} (impossible when "auto"
  # resolves to "binary", since `.detect_response_type()` already checks
  # this) -- warn, since a row with an out-of-range value is silently
  # excluded from both `n0`/`n1` in the quantile layer's rate calculation
  # (shrinking the denominator with no other indication), rather than
  # erroring or being counted; see PLAN.md's "stress-test findings" section
  if (object$response$type == "binary") {
    resp_vals <- object$data[[object$response$name]]
    if (!is.logical(resp_vals)) {
      n_out_of_range <- sum(!is.na(resp_vals) & !(resp_vals %in% c(0, 1)))
      if (n_out_of_range > 0) {
        rlang::warn(c(
          sprintf(
            "`response_type = \"binary\"` was declared for `%s`, but %d value%s outside {0, 1}.",
            object$response$name, n_out_of_range, if (n_out_of_range == 1) " is" else "s are"
          ),
          "i" = "Rows with an out-of-range value are silently excluded from the quantile layer's rate calculation (neither a responder nor a non-responder), shrinking the effective denominator.",
          "i" = "Pass `response_type = \"continuous\"` if this isn't actually a binary response."
        ))
      }
    }
  }

  # store limits
  object$exposure$limits <- range(object$data[[object$exposure$name]])
  if (object$response$type == "binary") {
    object$response$limits <- c(0, 1)
  } else {
    object$response$limits <- range(object$data[[object$response$name]], na.rm = TRUE)
  }
  if (!is.null(object$strata$name)) {
    object$strata$limits <- unique(object$data[[object$strata$name]])
  }

  # theming information
  object$theme$format_p <- scales::label_pvalue(accuracy = .001, add_p = TRUE)
  object$theme$format_percent <- scales::label_percent(accuracy = 1)
  object$theme$format_number <- scales::label_number(accuracy = 0.01)
  object$theme$height <- list(base = 6, data = 2, group = 3) 
  object$theme$theme_base <- ggplot2::theme_bw()
  object$theme$theme_extra <- ggplot2::theme(
    panel.border = ggplot2::element_rect(
      fill = NA, 
      color = "grey80", 
      linewidth = .5
    ),
    legend.position = "bottom"
  )
  object$theme$draw_key <- ggplot2::draw_key_rect
  object$theme$color_discrete <- NULL
  object$theme$fill_discrete <- NULL
  object$theme$color_continuous <- NULL
  object$theme$fill_continuous <- NULL
  object$theme$title <- NULL
  object$theme$subtitle <- NULL
  object$theme$caption <- NULL
 
  return(object)
}

#' Adjust theme/labels for an `er_plot` object
#'
#' Adjusts the styling knobs a ggplot2 user would expect to control --
#' axis/legend labels, plot title/subtitle/caption, axis limits, the
#' overall visual theme, the discrete color/fill palette used for
#' stratification, value formatters, the legend key glyph, and relative
#' panel heights -- without touching which variable is mapped to which
#' aesthetic (that's controlled by a layer's `style`; see [er_style()]).
#'
#' Every argument defaults to `NULL`, meaning "leave whatever was set
#' before unchanged" -- so `er_plot_theme()` can be called more than once
#' on the same object, each call only touching the arguments it actually
#' supplies (the same accumulate-by-default behaviour as
#' [ggplot2::theme()]'s own merging). There is no way to reset a field
#' back to its [er_plot()] default other than re-supplying that default's
#' value explicitly.
#'
#' `color_discrete`/`fill_discrete` only affect aesthetics that are
#' genuinely mapped to the stratification variable; `color_continuous`/
#' `fill_continuous` are the symmetric counterpart for aesthetics mapped to
#' something else continuous -- [er_style_data_hex()]'s density `fill`, or
#' a continuous/count response's color-encoded data layer (there's no
#' built-in builder for the latter today; see [er_style_tag()]'s `layout`
#' argument). Each of the four only ever touches the aesthetic role it
#' names -- supplying `color_continuous` never affects a discrete `colour`
#' mapping, and vice versa. If a custom builder adds its own
#' `scale_color_*()`/`scale_fill_*()` directly, supplying any of these four
#' here will add a second scale on top (ggplot2 will emit a message and the
#' later one wins) rather than detecting and deferring to the builder's own
#' choice.
#'
#' @param object Partially constructed plot (has S3 class `er_plot`)
#' @param xlab,ylab Exposure/response axis label (single string), written to
#'   `object$exposure$label`/`object$response$label`
#' @param strata_lab Stratification legend label (single string), written
#'   to `object$strata$label`. Errors if `stratify_by` wasn't set in
#'   [er_plot()] -- there's no stratification legend to label.
#' @param title,subtitle,caption Plot-level annotation text (single
#'   strings), applied via `patchwork::plot_annotation()` in
#'   [er_plot_build()]
#' @param xlim,ylim Exposure/response axis limits (length-2, increasing
#'   numeric vectors), written to `object$exposure$limits`/
#'   `object$response$limits`. These are read lazily by every builder at
#'   build time, so it doesn't matter whether `er_plot_theme()` is called
#'   before or after the layers that use them.
#' @param theme_base A ggplot2 theme object (e.g. [ggplot2::theme_minimal()]),
#'   written to `object$theme$theme_base` -- the swappable overall visual
#'   theme, defaulting to [ggplot2::theme_bw()]
#' @param theme_extra A ggplot2 theme object (e.g. from [ggplot2::theme()]),
#'   written to `object$theme$theme_extra` -- additional theme tweaks
#'   layered on top of `theme_base`, defaulting to a panel border plus
#'   `legend.position = "bottom"`. Supplying a new value fully replaces
#'   this default rather than merging with it, so re-include the border/
#'   legend-position settings too if you want to keep them alongside your
#'   own additions.
#' @param color_discrete,fill_discrete A discrete ggplot2 scale object
#'   (e.g. [ggplot2::scale_color_brewer()], [ggplot2::scale_fill_viridis_d()]),
#'   written to `object$theme$color_discrete`/`object$theme$fill_discrete`
#'   and applied to every plot whose `colour`/`fill` aesthetic is mapped to
#'   the stratification variable -- see "Details"
#' @param color_continuous,fill_continuous A continuous ggplot2 scale object
#'   (e.g. [ggplot2::scale_color_viridis_c()], [ggplot2::scale_fill_gradient()]),
#'   written to `object$theme$color_continuous`/`object$theme$fill_continuous`
#'   and applied to every plot whose `colour`/`fill` aesthetic is mapped to
#'   something continuous other than the stratification variable -- see
#'   "Details"
#' @param format_p,format_percent,format_number Formatter functions
#'   (typically from `scales::label_*()`), written to
#'   `object$theme$format_p` etc. Used by the summary/quantile layers to
#'   format p-values/rates/means for display
#' @param draw_key A key-glyph function (e.g. [ggplot2::draw_key_point()]),
#'   written to `object$theme$draw_key` and passed as every geom's
#'   `key_glyph` argument
#' @param height_base,height_data,height_group Relative panel heights
#'   (single positive numbers), merged into `object$theme$height` --
#'   supplying only one leaves the other two unchanged
#'
#' @returns The input `object`, with the requested theme fields updated
#'
#' @seealso [er_plot()], [er_style()]
#'
#' @export
er_plot_theme <- function(object,
                            xlab = NULL, ylab = NULL, strata_lab = NULL,
                            title = NULL, subtitle = NULL, caption = NULL,
                            xlim = NULL, ylim = NULL,
                            theme_base = NULL, theme_extra = NULL,
                            color_discrete = NULL, fill_discrete = NULL,
                            color_continuous = NULL, fill_continuous = NULL,
                            format_p = NULL, format_percent = NULL, format_number = NULL,
                            draw_key = NULL,
                            height_base = NULL, height_data = NULL, height_group = NULL) {

  if (!inherits(object, "er_plot")) rlang::abort("`object` must be an er_plot object")

  .check_theme_string(xlab, "xlab")
  .check_theme_string(ylab, "ylab")
  .check_theme_string(strata_lab, "strata_lab")
  .check_theme_string(title, "title")
  .check_theme_string(subtitle, "subtitle")
  .check_theme_string(caption, "caption")
  .check_theme_limits(xlim, "xlim")
  .check_theme_limits(ylim, "ylim")
  .check_theme_class(theme_base, "theme_base", "theme")
  .check_theme_class(theme_extra, "theme_extra", "theme")
  .check_theme_class(color_discrete, "color_discrete", "Scale")
  .check_theme_class(fill_discrete, "fill_discrete", "Scale")
  .check_theme_class(color_continuous, "color_continuous", "ScaleContinuous")
  .check_theme_class(fill_continuous, "fill_continuous", "ScaleContinuous")
  .check_theme_function(format_p, "format_p")
  .check_theme_function(format_percent, "format_percent")
  .check_theme_function(format_number, "format_number")
  .check_theme_function(draw_key, "draw_key")
  .check_theme_number(height_base, "height_base")
  .check_theme_number(height_data, "height_data")
  .check_theme_number(height_group, "height_group")

  if (!is.null(strata_lab) && is.null(object$strata$name)) {
    rlang::abort(c(
      "`strata_lab` was supplied, but no `stratify_by` was set in `er_plot()`.",
      "i" = "There is no stratification legend to label."
    ))
  }

  if (!is.null(xlab)) object$exposure$label <- xlab
  if (!is.null(ylab)) object$response$label <- ylab
  if (!is.null(strata_lab)) object$strata$label <- strata_lab

  if (!is.null(title)) object$theme$title <- title
  if (!is.null(subtitle)) object$theme$subtitle <- subtitle
  if (!is.null(caption)) object$theme$caption <- caption

  if (!is.null(xlim)) object$exposure$limits <- xlim
  if (!is.null(ylim)) object$response$limits <- ylim

  if (!is.null(theme_base)) object$theme$theme_base <- theme_base
  if (!is.null(theme_extra)) object$theme$theme_extra <- theme_extra

  if (!is.null(color_discrete)) object$theme$color_discrete <- color_discrete
  if (!is.null(fill_discrete)) object$theme$fill_discrete <- fill_discrete
  if (!is.null(color_continuous)) object$theme$color_continuous <- color_continuous
  if (!is.null(fill_continuous)) object$theme$fill_continuous <- fill_continuous

  if (!is.null(format_p)) object$theme$format_p <- format_p
  if (!is.null(format_percent)) object$theme$format_percent <- format_percent
  if (!is.null(format_number)) object$theme$format_number <- format_number

  if (!is.null(draw_key)) object$theme$draw_key <- draw_key

  new_height <- list(base = height_base, data = height_data, group = height_group)
  new_height <- new_height[!purrr::map_lgl(new_height, is.null)]
  if (length(new_height) > 0) {
    object$theme$height <- utils::modifyList(object$theme$height, new_height)
  }

  return(object)
}

#' @noRd
.check_theme_string <- function(x, arg) {
  if (is.null(x)) return(invisible(NULL))
  if (!is.character(x) || length(x) != 1L) {
    rlang::abort(paste0("`", arg, "` must be a single string."))
  }
  invisible(NULL)
}

#' @noRd
.check_theme_limits <- function(x, arg) {
  if (is.null(x)) return(invisible(NULL))
  if (!is.numeric(x) || length(x) != 2L || !(x[2] > x[1])) {
    rlang::abort(paste0("`", arg, "` must be a length-2, increasing numeric vector."))
  }
  invisible(NULL)
}

#' @noRd
.check_theme_class <- function(x, arg, class) {
  if (is.null(x)) return(invisible(NULL))
  if (!inherits(x, class)) {
    rlang::abort(paste0("`", arg, "` must be an object of class \"", class, "\"."))
  }
  invisible(NULL)
}

#' @noRd
.check_theme_function <- function(x, arg) {
  if (is.null(x)) return(invisible(NULL))
  if (!is.function(x)) {
    rlang::abort(paste0("`", arg, "` must be a function."))
  }
  invisible(NULL)
}

#' @noRd
.check_theme_number <- function(x, arg) {
  if (is.null(x)) return(invisible(NULL))
  if (!is.numeric(x) || length(x) != 1L || x <= 0) {
    rlang::abort(paste0("`", arg, "` must be a single positive number."))
  }
  invisible(NULL)
}


# model -----------------------------------------------------------------------

#' Add a fitted-model curve/ribbon layer
#'
#' Adds the model layer: a fitted exposure-response curve with an
#' uncertainty ribbon (the default, via [er_predict()]), or a spaghetti
#' plot of simulated draws (`style = er_style_model_spaghetti`, via
#' [er_simulate()]). This layer needs no `response_type` dispatch -- it
#' only ever consumes [er_predict()]'s output on the response's own
#' scale. For a summary annotation (e.g. a p-value, via [er_summary()]),
#' see [er_plot_add_summary()] -- a separate, independent layer that
#' doesn't require a model layer to also be present.
#'
#' This layer is **singleton** -- see [er_plot()]'s "Layers are either
#' singleton or additive" -- so calling it twice replaces the previous
#' model layer rather than overlaying two model curves.
#'
#' @param object Partially constructed plot (has S3 class `er_plot`)
#' @param model A fitted exposure-response model. Must implement
#'   [er_predict()]; implementing [er_simulate()] and [er_summary()]
#'   enables additional visualisations (see [er_model_interface]). If
#'   `model`'s formula references covariates beyond the exposure (and,
#'   when `keep_strata = TRUE`, strata) variable, those covariates are
#'   filled with a reference value (first factor level, or mean for a
#'   numeric column) when building the prediction grid -- see
#'   [er_model_interface]'s `newdata` documentation
#' @param keep_strata Logical, indicating whether this layer should be
#'   split by the plot's stratification variable; defaults to `TRUE` if
#'   `stratify_by` was set in [er_plot()], `FALSE` otherwise
#' @param style Function drawing the model curve/ribbon -- defaults to
#'   [er_style_model_ribbonline()] (mean prediction + confidence ribbon).
#'   [er_style_model_spaghetti()] (simulated draws, via [er_simulate()]) is
#'   the other built-in option; any function matching the standard
#'   `(data, config, stratify, exposure, response, strata, theme, ...)`
#'   signature can be supplied instead -- see [er_style()]. If `style` is
#'   tagged with a `layer` (via [er_style_tag()]) other than `"model"`,
#'   this errors informatively rather than passing a mismatched `config`
#'   shape to the builder; an untagged builder is never checked.
#' @param conf_level Confidence level for the prediction ribbon
#' @param ... Additional named arguments forwarded, unchanged, to `style`
#'   when it's called at build time (the builder is free to use only the
#'   arguments it recognizes, via its own `...`). Must be named -- see
#'   [er_style()]'s "Passing extra arguments to a builder" section. For
#'   example,
#'   `er_plot_add_model(mod, style = er_style_model_spaghetti, seed = 9626)`
#'   lets [er_style_model_spaghetti()] pass a reproducible `seed` to
#'   [er_simulate()] instead of relying on erglm's auto-selected one.
#'
#' @returns The input `object`, with the model layer added
#'
#' @examples
#' if (requireNamespace("erglm", quietly = TRUE)) {
#' library(erglm)
#' mod <- erglm_model(ae1 ~ aucss, erglm_data, family = binomial())
#' erglm_data |>
#'   er_plot(aucss, ae1) |>
#'   er_plot_add_model(mod) |>
#'   plot()
#'
#' # a spaghetti plot instead of the default ribbon
#' erglm_data |>
#'   er_plot(aucss, ae1) |>
#'   er_plot_add_model(mod, style = er_style_model_spaghetti) |>
#'   plot()
#'
#' # plug in a fully custom model-curve builder; see `?er_style` for the
#' # full contract
#' build_model_dashed <- function(data, config, stratify, exposure, response, strata, theme, ...) {
#'   ggplot2::geom_line(
#'     data = config$predictions,
#'     mapping = ggplot2::aes(x = .data[[exposure$name]], y = fit_resp),
#'     linetype = "dashed"
#'   )
#' }
#' erglm_data |>
#'   er_plot(aucss, ae1) |>
#'   er_plot_add_model(mod, style = build_model_dashed) |>
#'   plot()
#'
#' # a model with a covariate beyond the exposure variable -- `sex`, here
#' # -- still works even when this layer isn't stratifying by it (`sex`
#' # is filled in at a reference value when building the prediction grid)
#' mod_sex <- erglm_model(ae1 ~ aucss + sex, erglm_data, family = binomial())
#' erglm_data |>
#'   er_plot(aucss, ae1) |>
#'   er_plot_add_model(mod_sex) |>
#'   plot()
#' }
#'
#' @seealso [er_plot()], [er_plot_add_summary()], [er_plot_add_quantiles()],
#'   [er_plot_add_data()], [er_plot_add_groups()], [er_style()]
#'
#' @export
er_plot_add_model <- function(object, model, keep_strata = NULL,
                                style = NULL, conf_level = 0.95, ...) {

  dots <- rlang::list2(...)
  .check_dots_named(dots)
  if (!inherits(object, "er_plot")) rlang::abort("`object` must be an er_plot object")
  if (!is.null(style) && !is.function(style)) rlang::abort("`style` must be a function or NULL")
  if (is.null(keep_strata)) keep_strata <- !is.null(object$strata$name)

  style <- style %||% er_style_model_ribbonline
  .check_style_layer(style, "model", arg = "style")

  object$layer$model <- .layer_model(
    object = object, 
    model = model,
    stratify = keep_strata, 
    conf_level = conf_level,
    style = style,
    dots = dots
  )
  
  return(object)
}


# summary -----------------------------------------------------------------

#' Add a summary annotation layer
#'
#' Adds the summary layer: a text/label annotation placed in whichever
#' corner of the base panel is furthest from the observed data (see
#' [er_style_tag()]'s `corner_distance`-based placement, computed from
#' `object$data`'s raw `(exposure, response)` coordinates -- not any
#' fitted curve). Unlike [er_plot_add_model()], this layer doesn't require
#' a model: [er_style_summary_pvalue()] (the default) draws a p-value
#' derived from a supplied model's own [er_summary()] method, but
#' [er_style_summary_n()] is purely descriptive (total observation count,
#' or one count per stratum level) and needs no `model` at all.
#'
#' This layer is **singleton** -- see [er_plot()]'s "Layers are either
#' singleton or additive" -- so calling it twice replaces the previous
#' summary annotation rather than combining two. A builder wanting to show
#' several statistics at once composes them into one label/one set of
#' geoms itself, the way [er_style_summary_n()] does for multiple strata.
#'
#' @param object Partially constructed plot (has S3 class `er_plot`)
#' @param model A fitted exposure-response model, or `NULL` (the default).
#'   Only needed by a model-summary builder (e.g.
#'   [er_style_summary_pvalue()], which calls [er_summary()] on it); a
#'   purely descriptive builder (e.g. [er_style_summary_n()]) ignores it.
#' @param keep_strata Logical, indicating whether this layer should be
#'   split by the plot's stratification variable; defaults to `TRUE` if
#'   `stratify_by` was set in [er_plot()], `FALSE` otherwise. Passed
#'   through to `style` as `stratify` -- whether/how a builder changes its
#'   behaviour when `TRUE` is up to the builder itself (e.g.
#'   [er_style_summary_pvalue()] draws nothing at all, since one p-value
#'   doesn't unambiguously describe multiple curves).
#' @param style Function drawing the summary annotation -- defaults to
#'   [er_style_summary_pvalue()]. [er_style_summary_n()] is the other
#'   built-in option; any function matching the standard `(data, config,
#'   stratify, exposure, response, strata, theme, ...)` signature can be
#'   supplied instead -- see [er_style()]. `config$p_value` (`NULL` unless
#'   `model` was supplied) and `config$corner_distance` are the
#'   pre-computed pieces specific to this layer. If `style` is tagged with
#'   a `layer` (via [er_style_tag()]) other than `"summary"`, this errors
#'   informatively; an untagged builder is never checked.
#' @param ... Additional named arguments forwarded, unchanged, to `style`
#'   when it's called at build time -- see [er_style()]'s "Passing extra
#'   arguments to a builder" section. Must be named.
#'
#' @returns The input `object`, with the summary layer added
#'
#' @examples
#' if (requireNamespace("erglm", quietly = TRUE)) {
#' library(erglm)
#' mod <- erglm_model(ae1 ~ aucss, erglm_data, family = binomial())
#' erglm_data |>
#'   er_plot(aucss, ae1) |>
#'   er_plot_add_model(mod) |>
#'   er_plot_add_summary(model = mod) |>
#'   plot()
#'
#' # a purely descriptive annotation, with no model at all
#' erglm_data |>
#'   er_plot(aucss, ae1) |>
#'   er_plot_add_summary(style = er_style_summary_n) |>
#'   plot()
#' }
#'
#' @seealso [er_plot()], [er_plot_add_model()], [er_plot_add_quantiles()],
#'   [er_plot_add_data()], [er_plot_add_groups()], [er_style()]
#'
#' @export
er_plot_add_summary <- function(object, model = NULL, keep_strata = NULL, style = NULL, ...) {

  dots <- rlang::list2(...)
  .check_dots_named(dots)
  if (!inherits(object, "er_plot")) rlang::abort("`object` must be an er_plot object")
  if (!is.null(style) && !is.function(style)) rlang::abort("`style` must be a function or NULL")
  if (is.null(keep_strata)) keep_strata <- !is.null(object$strata$name)

  style <- style %||% er_style_summary_pvalue
  .check_style_layer(style, "summary")

  object$layer$summary <- .layer_summary(
    object = object,
    model = model,
    stratify = keep_strata,
    style = style,
    dots = dots
  )

  return(object)
}


# quantiles -------------------------------------------------------------------

#' Add a quantile-binned response summary layer
#'
#' Adds the quantile layer: exposure is cut into quantile bins (see
#' [cut_exposure_quantile()]) and, within each bin, the response is
#' summarised with a point estimate and confidence interval. Which
#' summary/CI method is used dispatches on the plot's `response_type`
#' (set in [er_plot()]):
#' * `"binary"` -- response *rate*, with a Clopper-Pearson interval (see [ci_clopper_pearson()])
#' * `"continuous"` -- bin *mean*, with a t-interval (see [ci_t()])
#' * `"count"` -- bin *mean*, with an exact Poisson interval (see [ci_poisson()])
#'
#' Count responses auto-detect as `"continuous"` (see [er_plot()]'s
#' `response_type` parameter) and are summarised the same way as any other
#' continuous response unless `response_type = "count"` is declared
#' explicitly.
#'
#' This layer is **singleton** -- see [er_plot()]'s "Layers are either
#' singleton or additive" -- so calling it twice replaces the previous
#' quantile summary rather than combining bins from both calls.
#'
#' @param object Partially constructed plot (has S3 class `er_plot`)
#' @param keep_strata Logical, indicating whether this layer should be
#'   split by the plot's stratification variable; defaults to `TRUE` if
#'   `stratify_by` was set in [er_plot()], `FALSE` otherwise
#' @param style Function drawing the quantile summary -- defaults to
#'   [er_style_quantile_errorbar()] (point + error bar).
#'   [er_style_quantile_pointrange()] (a single [ggplot2::geom_pointrange()])
#'   is another built-in option, as are `_vlines` variants of each
#'   ([er_style_quantile_errorbar_vlines()],
#'   [er_style_quantile_pointrange_vlines()]) that additionally draw a
#'   dotted line at each interior quantile-bin boundary; any function
#'   matching the standard
#'   `(data, config, stratify, exposure, response, strata, theme, ...)`
#'   signature can be supplied instead -- see [er_style()].
#'   `config$summary` is the pre-computed per-bin data frame (point
#'   estimate + CI) to draw. If `style` is tagged with a `layer` (via
#'   [er_style_tag()]) other than `"quantile"`, this errors
#'   informatively; an untagged builder is never checked.
#' @param bins Number of exposure bins (not counting placebo)
#' @param conf_level Confidence level for the interval
#' @param ... Additional named arguments forwarded, unchanged, to `style`
#'   when it's called at build time -- see [er_style()]'s "Passing extra
#'   arguments to a builder" section. Must be named.
#'
#' @returns The input `object`, with the quantile layer added
#'
#' @examples
#' if (requireNamespace("erglm", quietly = TRUE)) {
#' library(erglm)
#' mod <- erglm_model(ae1 ~ aucss, erglm_data, family = binomial())
#' erglm_data |>
#'   er_plot(aucss, ae1) |>
#'   er_plot_add_model(mod) |>
#'   er_plot_add_quantiles() |>
#'   plot()
#'
#' # continuous response: bin means/t-intervals instead of rates/
#' # Clopper-Pearson intervals, auto-detected from the response column
#' mod3 <- erglm_model(biomarker_change ~ aucss, erglm_data, family = gaussian())
#' erglm_data |>
#'   er_plot(aucss, biomarker_change) |>
#'   er_plot_add_model(mod3) |>
#'   er_plot_add_quantiles() |>
#'   plot()
#'
#' # count response: declare response_type = "count" explicitly for an
#' # exact Poisson interval instead of the t-interval approximation used
#' # by the auto-detected ("continuous") default
#' mod4 <- erglm_model(ae_count ~ aucss, erglm_data, family = poisson())
#' erglm_data |>
#'   er_plot(aucss, ae_count, response_type = "count") |>
#'   er_plot_add_model(mod4) |>
#'   er_plot_add_quantiles() |>
#'   plot()
#'
#' # a pointrange instead of the default errorbar
#' erglm_data |>
#'   er_plot(aucss, ae1) |>
#'   er_plot_add_model(mod) |>
#'   er_plot_add_quantiles(style = er_style_quantile_pointrange) |>
#'   plot()
#'
#' # the default errorbar, with dotted lines marking the quantile-bin
#' # boundaries
#' erglm_data |>
#'   er_plot(aucss, ae1) |>
#'   er_plot_add_model(mod) |>
#'   er_plot_add_quantiles(style = er_style_quantile_errorbar_vlines) |>
#'   plot()
#'
#' # plug in a fully custom builder; see `?er_style` for the full contract
#' build_quantile_crossbar <- function(data, config, stratify, exposure,
#'                                      response, strata, theme, ...) {
#'   ggplot2::geom_crossbar(
#'     data = config$summary,
#'     mapping = ggplot2::aes(x = x_mid, y = y_mid, ymin = ci_lower, ymax = ci_upper),
#'     inherit.aes = FALSE
#'   )
#' }
#' erglm_data |>
#'   er_plot(aucss, ae1) |>
#'   er_plot_add_model(mod) |>
#'   er_plot_add_quantiles(style = build_quantile_crossbar) |>
#'   plot()
#' }
#'
#' @seealso [er_plot()], [er_plot_add_model()], [er_plot_add_summary()],
#'   [er_plot_add_data()], [er_plot_add_groups()], [er_vpc_plot()],
#'   [er_style()]
#'
#' @export
er_plot_add_quantiles <- function(object, keep_strata = NULL, style = NULL,
                                    bins = 4, conf_level = 0.95, ...) {

  dots <- rlang::list2(...)
  .check_dots_named(dots)
  if (!inherits(object, "er_plot")) rlang::abort("`object` must be an er_plot object")
  if (!is.null(style) && !is.function(style)) rlang::abort("`style` must be a function or NULL")
  if (is.null(keep_strata)) keep_strata <- !is.null(object$strata$name)

  style <- style %||% er_style_quantile_errorbar
  .check_style_layer(style, "quantile")

  object$layer$quantile <- .layer_quantile(
    object = object,
    stratify = keep_strata,
    bins = bins,
    conf_level = conf_level,
    style = style,
    dots = dots
  )
  
  return(object)
}


# data --------------------------------------------------------------------

#' Tag a builder with structural/aesthetic metadata
#'
#' Attaches the self-declared metadata a custom `er_style_*()`-style
#' function can carry, in a single call: which *structural* family a
#' data-layer builder belongs to (`layout`), what a builder's `fill`
#' aesthetic means when it isn't strata (`fill_role`), what a group-layer
#' builder's y-axis means when it isn't the group variable itself
#' (`y_role`), and which layer a builder is meant to be plugged into
#' (`layer`). All four arguments are optional and independent -- pass
#' only the ones a given builder needs, in one call, rather than chaining
#' separate setters. See [er_style()]'s "Writing your own builder"
#' section for the full contract.
#'
#' `layout` is the one required tag for a data-layer builder:
#' [er_plot_add_data()] reads it off `style` to decide whether to route
#' through `.layer_overlay()` (`"overlay"`: a single call merged into the
#' main panel, at the observations' true `(exposure, response)`
#' coordinates) or `.layer_data()` (`"panel"`: one-or-more panels stacked
#' below the base plot), *before* it can call the builder -- so the choice
#' can't be inferred from the builder's return value. Both built-in data
#' builders ([er_style_data_overlay()], [er_style_data_boxjitter()])
#' already carry this tag.
#'
#' `fill_role` and `y_role` are both optional, read by `.polish_labels()`
#' to title a legend/axis correctly: `fill_role = "density"` (used by
#' [er_style_data_hex()]) says a builder's `fill` aesthetic encodes bin
#' density rather than strata; `y_role = "count"` (used by
#' [er_style_group_histogram()]) says a group-layer builder's y-axis
#' means counts rather than the group variable itself. A builder that
#' omits either tag keeps the default behaviour (`fill` means strata;
#' the y-axis is titled with the group variable's label), which is
#' correct for most builders.
#'
#' `layer` is also optional, but unlike `fill_role`/`y_role` it isn't read
#' for labelling -- it's read by every `er_plot_add_*()` function
#' (`er_plot_add_model()` checks `style` against `"model"`;
#' `er_plot_add_summary()` checks `style` against `"summary"`;
#' `er_plot_add_quantiles()`
#' against `"quantile"`; `er_plot_add_data()` against `"data"`;
#' `er_plot_add_groups()` against `"group"`) to catch a builder plugged
#' into the wrong layer -- e.g. passing a quantile builder to
#' `er_plot_add_data()` -- with an informative error instead of whatever
#' failure results from that layer's `config` shape not matching what the
#' builder expects. All built-in builders carry this tag. A custom
#' builder that omits it is never checked -- `layer` is opt-in, not a
#' requirement like `layout` is for a data-layer builder.
#'
#' @param style A function matching the standard `er_style_*()` signature
#'   (see [er_style()])
#' @param layout One of `"overlay"` or `"panel"`, or `NULL` (the default) to
#'   leave this tag unset -- see [er_plot_add_data()] for what each
#'   structural family means
#' @param fill_role A string naming what the builder's `fill` aesthetic
#'   represents (currently only `"density"` is read by `.polish_labels()`,
#'   but any string is accepted), or `NULL` (the default) to leave this tag
#'   unset
#' @param y_role A string naming what the builder's y-axis represents
#'   (currently only `"count"` is read by `.polish_labels()`), or `NULL`
#'   (the default) to leave this tag unset
#' @param layer One of `"model"`, `"summary"`, `"quantile"`, `"data"`, or
#'   `"group"`, naming which `er_plot_add_*()` layer the builder is meant
#'   to be used with, or `NULL` (the default) to leave this tag unset --
#'   see "Details"
#'
#' @returns `style`, with whichever of the `"er_style_layout"`/
#'   `"er_style_fill_role"`/`"er_style_y_role"`/`"er_style_layer"`
#'   attributes were requested attached
#'
#' @seealso [er_plot_add_data()], [er_style()]
#'
#' @examples
#' build_data_density <- er_style_tag(
#'   function(data, config, stratify, exposure, response, strata, theme, ...) {
#'     ggplot2::geom_density_2d(
#'       data = data,
#'       mapping = ggplot2::aes(x = .data[[exposure$name]], y = .data[[response$name]])
#'     )
#'   },
#'   layout = "overlay",
#'   layer = "data"
#' )
#'
#' @export
er_style_tag <- function(style, layout = NULL, fill_role = NULL, y_role = NULL, layer = NULL) {
  if (!is.function(style)) rlang::abort("`style` must be a function")

  if (!is.null(layout)) {
    layout <- match.arg(layout, c("overlay", "panel"))
    attr(style, "er_style_layout") <- layout
  }
  if (!is.null(fill_role)) {
    attr(style, "er_style_fill_role") <- fill_role
  }
  if (!is.null(y_role)) {
    attr(style, "er_style_y_role") <- y_role
  }
  if (!is.null(layer)) {
    layer <- match.arg(layer, c("model", "summary", "quantile", "data", "group"))
    attr(style, "er_style_layer") <- layer
  }

  style
}

#' @noRd
.style_layout <- function(style) {
  layout <- attr(style, "er_style_layout")
  if (is.null(layout)) {
    rlang::abort(c(
      "`style` must declare its structural layout.",
      "i" = "Wrap a custom data-layer builder with `er_style_tag(style, layout = \"overlay\")` or `er_style_tag(style, layout = \"panel\")`.",
      "i" = "The built-in builders (`er_style_data_overlay()`, `er_style_data_boxjitter()`) already do this."
    ))
  }
  layout
}

#' @noRd
.style_fill_role <- function(style) {
  attr(style, "er_style_fill_role")
}

#' @noRd
.style_y_role <- function(style) {
  attr(style, "er_style_y_role")
}

#' @noRd
.style_layer <- function(style) {
  attr(style, "er_style_layer")
}

#' @noRd
.check_style_layer <- function(style, layer, arg = "style") {
  declared <- .style_layer(style)
  if (is.null(declared) || identical(declared, layer)) return(invisible(NULL))

  rlang::abort(c(
    paste0("`", arg, "` is tagged for the \"", declared, "\" layer, but was passed to a \"", layer, "\" layer function."),
    "i" = paste0("Use a builder tagged `er_style_tag(fn, layer = \"", layer, "\")` (or with no `layer` tag at all).")
  ))
}


#' Add a raw-data layer
#'
#' Adds the data layer: individual observations. By default (`style =
#' er_style_data_overlay`), points are drawn at their true `(exposure,
#' response)` coordinates in the *main* model panel -- a plain scatter for
#' continuous/count responses, or a scatter with a small vertical jitter
#' for a binary response (whose y-values are exactly 0/1 and would
#' otherwise overplot into two solid lines). This works uniformly across
#' all three response types, with no response-type dispatch on which
#' builder to use. `er_style_data_boxjitter()` instead uses the older,
#' panel-based design, and is binary-response-only: responders (`response
#' == 1`) get a boxplot + jittered points in an upper panel and
#' non-responders (`response == 0`) get the same in a lower panel, so the
#' panel shows the exposure *distribution* conditional on response, not
#' just raw points. There is no built-in "panel"-layout builder for a
#' continuous/count response -- the older `build_data_color()` (a single
#' panel with points colored continuously by the response value) was
#' removed once `er_style_data_overlay()` turned out to cover its typical
#' use case more simply; `panel` must be `"both"` (the default) for these
#' response types regardless of builder, since there's no upper/lower
#' partition to select from.
#'
#' Every data-layer builder declares which of these two *structural*
#' families it belongs to via [er_style_tag()] -- `"overlay"` (a single call
#' merged into the main panel) or `"panel"` (one-or-more panels stacked
#' below the base plot) -- which `er_plot_add_data()` reads off `style`
#' to decide how to assemble the layer, rather than taking a separate
#' argument for it. This makes the pairing structural rather than
#' incidental: `er_style_data_overlay()` can never be routed into upper/lower
#' panels, and `er_style_data_boxjitter()` can never be merged into the main
#' panel. See [er_style_tag()] and [er_style()] for how to tag a custom
#' builder the same way.
#'
#' This layer is **singleton** -- see [er_plot()]'s "Layers are either
#' singleton or additive" -- calling it again (with any builder) fully
#' replaces the previous data layer. A "panel"-layout builder is also the
#' one case where stratification behaviour is a partial exception to
#' "always color/fill" (see [er_plot()]'s "Stratification" section): for a
#' continuous/count response, the color aesthetic is already spoken for
#' by the response value, so stratification instead produces one panel
#' per stratum level (stacked below the base plot, each colored by the
#' response), rather than a shared strata legend. An "overlay"-layout
#' builder has no such exception -- its color aesthetic (when stratified)
#' is always strata, since the response is already shown via y-position,
#' and it shares the base plot's own strata legend (the same one the
#' model/quantile layers use) rather than needing one of its own.
#'
#' @param object Partially constructed plot (has S3 class `er_plot`)
#' @param keep_strata Logical, indicating whether this layer should be
#'   split by the plot's stratification variable; defaults to `TRUE` if
#'   `stratify_by` was set in [er_plot()], `FALSE` otherwise. For a
#'   "panel"-layout builder on a continuous/count response this produces
#'   one panel per stratum level (see "Stratification" above) rather than
#'   a shared color aesthetic; for an "overlay"-layout builder it always
#'   means a shared color aesthetic, for any response type.
#' @param style Function drawing the data layer -- defaults to
#'   [er_style_data_overlay()]. [er_style_data_boxjitter()] (binary response
#'   only: a boxplot + jittered points per panel) is the other built-in
#'   option; any function matching the standard `(data, config, stratify,
#'   exposure, response, strata, theme, ...)` signature and tagged with
#'   [er_style_tag()] can be supplied instead -- see [er_style()] for the
#'   full contract, e.g. a 2D density in the main panel, a continuous/
#'   count response's color-encoded panel, or per-panel histograms. If
#'   `style` is tagged with a `layer` other than `"data"`, this errors
#'   informatively; an untagged builder is never checked (only `layout`
#'   is a hard requirement).
#' @param panel Character string: `"upper"`, `"lower"`, or `"both"` (the
#'   default). Only meaningful for [er_style_data_boxjitter()] on a binary
#'   response; must be `"both"` for an "overlay"-layout builder (no
#'   upper/lower partition exists) or for a continuous/count response
#'   under a "panel"-layout builder (there's no upper/lower partition to
#'   select from either way).
#' @param ... Additional named arguments forwarded, unchanged, to `style`
#'   when it's called at build time -- see [er_style()]'s "Passing extra
#'   arguments to a builder" section. Must be named.
#'
#' @returns The input `object`, with the data layer added
#'
#' @examples
#' if (requireNamespace("erglm", quietly = TRUE)) {
#' library(erglm)
#' mod2 <- erglm_model(ae2 ~ aucss + sex, erglm_data, family = binomial())
#' erglm_data |>
#'   er_plot(aucss, ae2, stratify_by = sex) |>
#'   er_plot_add_model(mod2) |>
#'   er_plot_add_quantiles() |>
#'   er_plot_add_data() |>
#'   plot()
#'
#' # continuous response: overlay works the same way, with no
#' # response-type-specific styling needed
#' mod3 <- erglm_model(biomarker_change ~ aucss, erglm_data, family = gaussian())
#' erglm_data |>
#'   er_plot(aucss, biomarker_change) |>
#'   er_plot_add_model(mod3) |>
#'   er_plot_add_data() |>
#'   plot()
#'
#' # older panel-based design, binary-response only: a boxplot + jittered
#' # points per panel (responders above, non-responders below), instead
#' # of an overlay in the main panel
#' erglm_data |>
#'   er_plot(aucss, ae2, stratify_by = sex) |>
#'   er_plot_add_model(mod2) |>
#'   er_plot_add_data(style = er_style_data_boxjitter) |>
#'   plot()
#'
#' # plug in a 2D density in the main panel instead of a scatter; tagging
#' # it "overlay" via `er_style_tag()` keeps it in the single main-panel
#' # layout -- see `?er_style`
#' build_data_density <- er_style_tag(
#'   function(data, config, stratify, exposure, response, strata, theme, ...) {
#'     ggplot2::geom_density_2d(
#'       data = data,
#'       mapping = ggplot2::aes(x = .data[[exposure$name]], y = .data[[response$name]])
#'     )
#'   },
#'   layout = "overlay"
#' )
#' erglm_data |>
#'   er_plot(aucss, biomarker_change) |>
#'   er_plot_add_model(mod3) |>
#'   er_plot_add_data(style = build_data_density) |>
#'   plot()
#' }
#'
#' @seealso [er_plot()], [er_plot_add_model()], [er_plot_add_summary()],
#'   [er_plot_add_quantiles()], [er_plot_add_groups()], [er_style()]
#'
#' @export
er_plot_add_data <- function(object, keep_strata = NULL, style = NULL, panel = "both", ...) {

  dots <- rlang::list2(...)
  .check_dots_named(dots)
  if (!inherits(object, "er_plot")) rlang::abort("`object` must be an er_plot object")
  if (!is.null(style) && !is.function(style)) rlang::abort("`style` must be a function or NULL")

  style <- style %||% er_style_data_overlay
  .check_style_layer(style, "data")
  layout <- .style_layout(style)

  if (layout == "overlay" && panel != "both") {
    rlang::abort(c(
      "`panel` must be \"both\" for an \"overlay\"-layout `style`.",
      "i" = "The \"upper\"/\"lower\" partition is specific to a \"panel\"-layout builder on a binary response."
    ))
  }

  if (layout == "panel" && object$response$type %in% c("continuous", "count") && panel != "both") {
    rlang::abort(c(
      paste0("`panel` must be \"both\" for a ", object$response$type, " response."),
      "i" = "The \"upper\"/\"lower\" two-panel design is specific to binary responses.",
      "i" = "A continuous/count response uses a single color-encoded panel instead."
    ))
  }

  if (is.null(keep_strata)) keep_strata <- !is.null(object$strata$name)

  # use `[` (not `$`) to clear the other slot -- `object$layer$x <- NULL`
  # would remove "x" from the list entirely rather than setting it to
  # NULL, dropping it from `layer_set`/`plot_set` in `print.er_plot()`
  if (layout == "overlay") {
    object$layer$overlay <- .layer_overlay(object = object, stratify = keep_strata, style = style, dots = dots)
    object$layer["data"] <- list(NULL)
  } else {
    object$layer$data <- .layer_data(
      object = object,
      stratify = keep_strata, 
      panel = panel,
      style = style,
      dots = dots
    )
    object$layer["overlay"] <- list(NULL)
  }

  return(object)  
}


# groups plot -----------------------------------------------------------------

#' Add a grouped exposure-distribution panel
#'
#' Adds a group layer: a boxplot/violin panel showing the *exposure*
#' distribution, split by one or more grouping variables (continuous
#' grouping variables are binned into quantiles first, via
#' [cut_quantile()]). This layer only looks at the exposure variable, not
#' the response, so it needs no `response_type` dispatch.
#'
#' Unlike the other four layers, this one is **additive** -- see
#' [er_plot()]'s "Layers are either singleton or additive" -- each call
#' adds another panel alongside any already added by a previous call,
#' rather than replacing it.
#'
#' @param object Partially constructed plot (has S3 class `er_plot`)
#' @param group_by Grouping variables to define groups for distribution
#'   plots (a tidyselection of variables)
#' @param style Function drawing each group panel -- defaults to
#'   [er_style_group_boxplot()]. [er_style_group_violin()] is the other
#'   built-in option; any function matching the standard `(data, config,
#'   stratify, exposure, response, strata, theme, ...)` signature can be
#'   supplied instead -- see [er_style()]. Applied to every grouping
#'   variable added by this call. If `style` is tagged with a `layer`
#'   (via [er_style_tag()]) other than `"group"`, this errors
#'   informatively; an untagged builder is never checked.
#' @param bins Number of quantile bins used for continuous grouping
#'   variables (`NULL`, the default, uses [cut_quantile()]'s own default)
#' @param keep_strata Logical, indicating whether this layer should be
#'   split by the plot's stratification variable; defaults to `TRUE` if
#'   `stratify_by` was set in [er_plot()], `FALSE` otherwise. Errors if
#'   `TRUE` and `group_by` is itself the plot's stratification
#'   variable, since that would mean grouping and stratifying by the
#'   same column at once; pass `keep_strata = FALSE` for that grouping
#'   variable instead
#' @param ... Additional named arguments forwarded, unchanged, to `style`
#'   when it's called at build time (identically for every grouping
#'   variable added by this call) -- see [er_style()]'s "Passing extra
#'   arguments to a builder" section. Must be named.
#'
#' @returns The input `object`, with a group panel added
#'
#' @examples
#' if (requireNamespace("erglm", quietly = TRUE)) {
#' library(erglm)
#' mod <- erglm_model(ae1 ~ aucss, erglm_data, family = binomial())
#' erglm_data |>
#'   er_plot(aucss, ae1) |>
#'   er_plot_add_model(mod) |>
#'   er_plot_add_groups(aucss) |>
#'   plot()
#'
#' # additive: a second call adds a second panel rather than replacing the first
#' erglm_data |>
#'   er_plot(aucss, ae1) |>
#'   er_plot_add_model(mod) |>
#'   er_plot_add_groups(aucss) |>
#'   er_plot_add_groups(treatment) |>
#'   plot()
#' }
#'
#' @seealso [er_plot()], [er_plot_add_model()], [er_plot_add_summary()],
#'   [er_plot_add_quantiles()], [er_plot_add_data()], [er_style()]
#'
#' @export
er_plot_add_groups <- function(object, group_by, style = NULL, bins = NULL, keep_strata = NULL, ...) {

  dots <- rlang::list2(...)
  .check_dots_named(dots)
  if (!inherits(object, "er_plot")) rlang::abort("`object` must be an er_plot object")
  if (!is.null(style) && !is.function(style)) rlang::abort("`style` must be a function or NULL")
  if (is.null(keep_strata)) keep_strata <- !is.null(object$strata$name)
  group_cols <- tidyselect::eval_select(rlang::enquo(group_by), object$data) 
  group_cols <- names(group_cols)

  style <- style %||% er_style_group_boxplot
  .check_style_layer(style, "group")

  new_group <- .layer_group(
    object = object,
    group_cols = group_cols, 
    stratify = keep_strata, 
    bins = bins,
    style = style,
    dots = dots
  )

  # additive: merge into any existing group panels rather than replacing
  # them (`modifyList()` so re-adding the same grouping variable still
  # replaces just that one panel, in insertion order for new names)
  if (is.null(object$layer$group)) {
    object$layer$group <- new_group
  } else {
    object$layer$group$config <- utils::modifyList(
      object$layer$group$config, 
      new_group$config
    )
  }
  # kept only for `.polish_legends()`'s layer-level strata-legend dedup:
  # TRUE if *any* group panel (across all `er_plot_add_groups()` calls)
  # is stratified, since per-panel stratification is now read from each
  # group's own `config[[g]]$stratify` (see `.build_group_plot()`)
  object$layer$group$stratify <- any(
    purrr::map_lgl(object$layer$group$config, \(cfg) cfg$stratify)
  )

  return(object)  
}


# plot/print ------------------------------------------------------------------

#' @exportS3Method base::print
print.er_plot <- function(x, ...) {

  layer_set <- !purrr::map_lgl(x$layer, is.null)
  plot_set <- !purrr::map_lgl(x$plot, is.null)

  cat("<er_plot>\n")
  cat("  plot variables:\n")
  cat("    - exposure:        ", x$exposure$name  %||% "<none>", "\n", sep = "")
  cat("    - response:        ", x$response$name  %||% "<none>", "\n", sep = "")
  cat("    - stratification:  ", x$strata$name    %||% "<none>", "\n", sep = "")
  
  if (any(layer_set)) {
    cat("  plot layers:\n")
    if (layer_set["model"])    cat("    - model:           ", paste(class(x$layer$model$config$model), collapse = "/"), "\n", sep = "")
    if (layer_set["summary"])  cat("    - summary:         ", if (is.null(x$layer$summary$config$model)) "descriptive" else "model-derived", "\n", sep = "")
    if (layer_set["quantile"]) cat("    - quantile:        ", x$layer$quantile$config$n_quantiles, " bins\n", sep = "")
    if (layer_set["data"])     cat("    - data:            ", x$layer$data$config$layout, " ", x$layer$data$config$panel, "\n", sep = "")
    if (layer_set["overlay"])  cat("    - overlay:         ", if (x$layer$overlay$stratify) "stratified" else "unstratified", "\n", sep = "")
    if (layer_set["group"])    cat("    - group:           ", paste(names(x$layer$group$config), collapse = ", "), "\n", sep = "")
  } else {
    cat("  plot layers: <none>\n")
  }

  if (any(plot_set)) {
    cat("  plots built:\n")
    if (plot_set["base"])   cat("    - model\n", sep = "")
    if (plot_set["data"])   cat("    - data\n", sep = "")
    if (plot_set["group"])  cat("    - group\n", sep = "")
  } else {
    cat("  plots built: <none>\n")
  }

  if (is.null(x$output))  cat("  output built: no")
  if (!is.null(x$output)) cat("  output built: yes")
  
  return(invisible(x))
}

#' @exportS3Method graphics::plot
plot.er_plot <- function(x, y = NULL, ...) {
  object <- er_plot_build(x)
  plot(object$output)
}


# top level build function ----------------------------------------------------

#' Build and render an `er_plot` object
#'
#' Assembles whichever layers have been added (via the `er_plot_add_*()`
#' functions) into ggplot2 objects, applies shared theming and legend
#' deduplication across layers, and composes the final output with
#' patchwork. Usually invoked indirectly, via `plot()`/`print()` on an
#' `er_plot` object, rather than called directly.
#'
#' @param object Partially constructed plot (has S3 class `er_plot`)
#'
#' @returns The input `object`, with `object$plot` (per-layer ggplot2
#'   objects) and `object$output` (the final composed plot) populated
#'
#' @seealso [er_plot()]
#'
#' @export
er_plot_build <- function(object) {
  if (!inherits(object, "er_plot")) rlang::abort("`object` must be an er_plot object")
  
  # build
  has_base_layer <- !is.null(object$layer$model) || !is.null(object$layer$summary) ||
    !is.null(object$layer$quantile) || !is.null(object$layer$overlay)
  has_any_layer <- has_base_layer || !is.null(object$layer$data) || !is.null(object$layer$group)

  # an er_plot with no layers at all still renders as an empty canvas
  # (axes only, no geoms) rather than erroring inside patchwork when handed
  # an empty plot list -- see `?er_plot`'s "empty plot" example
  if (has_base_layer || !has_any_layer) {
    object$plot$base <- .build_base_plot(object)
  }
  if (!is.null(object$layer$data)) object$plot$data <- .build_data_plot(object)
  if (!is.null(object$layer$group)) object$plot$group <- .build_group_plot(object)
  if (!is.null(object$layer$overlay)) {
    object$plot$base <- object$plot$base + .build_overlay_geoms(object)
  }

  # polish
  object$plot <- .polish_margins(object)
  object$plot <- .polish_labels(object)
  object$plot <- .polish_scales(object)
  composition <- .polish_arrangement(object)
  composition <- .polish_legends(object, composition)
  composition <- .polish_theme(object, composition)

  # output
  object$output <- patchwork::wrap_plots(
    composition$plots, 
    ncol = 1, 
    heights = composition$info$size,
    guides = "collect",
    axes = "collect"
  ) + patchwork::plot_annotation(
    title = object$theme$title,
    subtitle = object$theme$subtitle,
    caption = object$theme$caption,
    theme = object$theme$theme_extra
  )

  return(object)
}
