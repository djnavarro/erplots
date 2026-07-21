
#' The exposure-response plotting mini-language
#'
#' `er_plot()` creates an (empty) plot object of S3 class `er_plot`. Build
#' up a plot by piping it through one or more layer functions --
#' [er_plot_add_model()] (fitted-model curve/ribbon and summary),
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
#' [er_plot_add_model()], [er_plot_add_quantiles()], and
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
#' @param exposure Exposure variable (one variable, unquoted)
#' @param response Response variable (one variable, unquoted)
#' @param stratify_by Stratification variable used for color and fill (one
#'   variable, unquoted); see "Stratification" above
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
#'   `PLAN.md`'s design decision (4) for the rationale.
#'
#' @returns An (empty) plot object of class `er_plot`
#'
#' @examples
#' \dontrun{
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
#' @seealso [er_plot_add_model()], [er_plot_add_quantiles()],
#'   [er_plot_add_data()], [er_plot_add_groups()],
#'   [er_plot_build()], [er_plot_style()], [er_model_interface]
#'
#' @name er_plot
NULL


# setup -----------------------------------------------------------------------

#' @rdname er_plot
#' @export
er_plot <- function(data, exposure, response, stratify_by = NULL, response_type = "auto") {

  response_type <- match.arg(response_type, c("auto", "binary", "continuous", "count"))

  # empty plot object
  object <- structure(
    list(
      data  = NULL,
      exposure = .plot_variable(role = "exposure"),
      response = .plot_variable(role = "response"),
      strata = .plot_variable(role = "strata"),
      part = list(
        model    = NULL, 
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
      style = list(),
      output = NULL 
    ),
    class = "er_plot"
  )

  # store observed data
  object$data <- data

  # store variable names
  object$exposure$name <- rlang::as_name(rlang::enquo(exposure))
  object$response$name <- rlang::as_name(rlang::enquo(response)) 
  strata_name <- rlang::enquo(stratify_by)
  if (!rlang::quo_is_null(strata_name)) object$strata$name <- rlang::as_name(strata_name)
  
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

  # stylistic information
  object$style$format_p <- scales::label_pvalue(accuracy = .001, add_p = TRUE)
  object$style$format_percent <- scales::label_percent(accuracy = 1)
  object$style$format_number <- scales::label_number(accuracy = 0.01)
  object$style$height <- list(base = 6, data = 2, group = 3) 
  object$style$theme_base <- function() ggplot2::theme_bw()
  object$style$theme_args <- function() {
    ggplot2::theme(
      panel.border = ggplot2::element_rect(
        fill = NA, 
        color = "grey80", 
        linewidth = .5
      ),
      legend.position = "bottom"
    ) 
  }
  object$style$draw_key <- ggplot2::draw_key_rect
 
  return(object)
}

#' Adjust style/labels for an `er_plot` object
#'
#' Not yet implemented -- currently a no-op placeholder for future styling
#' customisation (labels, theme, formatters). See `object$style` (set by
#' [er_plot()]) for what's already there to be made adjustable.
#'
#' @param object Partially constructed plot (has S3 class `er_plot`)
#' @param labels Named list of labels
#'
#' @returns The input `object`, unchanged
#'
#' @seealso [er_plot()]
#'
#' @export
er_plot_style <- function(object, labels) {

  # TODO: flesh this out so that users can modify style, labels, etc

  return(object)
}


# model -----------------------------------------------------------------------

#' Add a fitted-model curve/ribbon layer
#'
#' Adds the model layer: a fitted exposure-response curve with an
#' uncertainty ribbon (the default, via [er_predict()]), or a spaghetti
#' plot of simulated draws (`builder = er_builder_model_spaghetti`, via
#' [er_simulate()]), plus an optional summary annotation (e.g. a p-value)
#' via [er_summary()] when the layer isn't stratified. This layer needs no
#' `response_type` dispatch -- it only ever consumes [er_predict()]'s
#' output on the response's own scale.
#'
#' This layer is **singleton** -- see [er_plot()]'s "Layers are either
#' singleton or additive" -- so calling it twice replaces the previous
#' model layer rather than overlaying two model curves.
#'
#' @param object Partially constructed plot (has S3 class `er_plot`)
#' @param model A fitted exposure-response model. Must implement
#'   [er_predict()]; implementing [er_simulate()] and [er_summary()]
#'   enables additional visualisations (see [er_model_interface])
#' @param keep_strata Logical, indicating whether this layer should be
#'   split by the plot's stratification variable; defaults to `TRUE` if
#'   `stratify_by` was set in [er_plot()], `FALSE` otherwise
#' @param builder Function drawing the model curve/ribbon -- defaults to
#'   [er_builder_model_ribbonline()] (mean prediction + confidence ribbon).
#'   [er_builder_model_spaghetti()] (simulated draws, via [er_simulate()]) is
#'   the other built-in option; any function matching the standard
#'   `(data, config, stratify, exposure, response, strata, style)`
#'   signature can be supplied instead -- see [er_partial()].
#' @param summary_builder Function drawing the summary annotation --
#'   defaults to [er_builder_summary_pvalue()]. Any function matching the same
#'   standard signature as `builder` can be supplied instead. See
#'   [er_partial()].
#' @param conf_level Confidence level for the prediction ribbon
#'
#' @returns The input `object`, with the model layer added
#'
#' @examples
#' \dontrun{
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
#'   er_plot_add_model(mod, builder = er_builder_model_spaghetti) |>
#'   plot()
#'
#' # plug in a fully custom model-curve builder; see `?er_partial` for the
#' # full contract
#' build_model_dashed <- function(data, config, stratify, exposure, response, strata, style) {
#'   ggplot2::geom_line(
#'     data = config$predictions,
#'     mapping = ggplot2::aes(x = .data[[exposure$name]], y = fit_resp),
#'     linetype = "dashed"
#'   )
#' }
#' erglm_data |>
#'   er_plot(aucss, ae1) |>
#'   er_plot_add_model(mod, builder = build_model_dashed) |>
#'   plot()
#' }
#'
#' @seealso [er_plot()], [er_plot_add_quantiles()],
#'   [er_plot_add_data()], [er_plot_add_groups()], [er_partial()]
#'
#' @export
er_plot_add_model <- function(object, model, keep_strata = NULL,
                                builder = NULL, summary_builder = NULL, conf_level = 0.95) {

  if (!inherits(object, "er_plot")) rlang::abort("`object` must be an er_plot object")
  if (!is.null(builder) && !is.function(builder)) rlang::abort("`builder` must be a function or NULL")
  if (!is.null(summary_builder) && !is.function(summary_builder)) rlang::abort("`summary_builder` must be a function or NULL")
  if (is.null(keep_strata)) keep_strata <- !is.null(object$strata$name)

  object$part$model <- .part_model(
    object = object, 
    model = model,
    stratify = keep_strata, 
    conf_level = conf_level,
    builder = builder %||% er_builder_model_ribbonline,
    summary_builder = summary_builder %||% er_builder_summary_pvalue
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
#' @param builder Function drawing the quantile summary -- defaults to
#'   [er_builder_quantile_errorbar()] (point + error bar).
#'   [er_builder_quantile_pointrange()] (a single [ggplot2::geom_pointrange()])
#'   is the other built-in option; any function matching the standard
#'   `(data, config, stratify, exposure, response, strata, style)`
#'   signature can be supplied instead -- see [er_partial()].
#'   `config$summary` is the pre-computed per-bin data frame (point
#'   estimate + CI) to draw.
#' @param bins Number of exposure bins (not counting placebo)
#' @param conf_level Confidence level for the interval
#'
#' @returns The input `object`, with the quantile layer added
#'
#' @examples
#' \dontrun{
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
#'   er_plot_add_quantiles(builder = er_builder_quantile_pointrange) |>
#'   plot()
#'
#' # plug in a fully custom builder; see `?er_partial` for the full contract
#' build_quantile_crossbar <- function(data, config, stratify, exposure, response, strata, style) {
#'   ggplot2::geom_crossbar(
#'     data = config$summary,
#'     mapping = ggplot2::aes(x = x_mid, y = y_mid, ymin = ci_lower, ymax = ci_upper),
#'     inherit.aes = FALSE
#'   )
#' }
#' erglm_data |>
#'   er_plot(aucss, ae1) |>
#'   er_plot_add_model(mod) |>
#'   er_plot_add_quantiles(builder = build_quantile_crossbar) |>
#'   plot()
#' }
#'
#' @seealso [er_plot()], [er_plot_add_model()],
#'   [er_plot_add_data()], [er_plot_add_groups()], [er_vpc_plot()],
#'   [er_partial()]
#'
#' @export
er_plot_add_quantiles <- function(object, keep_strata = NULL, builder = NULL,
                                    bins = 4, conf_level = 0.95) {

  if (!inherits(object, "er_plot")) rlang::abort("`object` must be an er_plot object")
  if (!is.null(builder) && !is.function(builder)) rlang::abort("`builder` must be a function or NULL")
  if (is.null(keep_strata)) keep_strata <- !is.null(object$strata$name)
  
  object$part$quantile <- .part_quantile(
    object = object,
    stratify = keep_strata,
    bins = bins,
    conf_level = conf_level,
    builder = builder %||% er_builder_quantile_errorbar
  )
  
  return(object)
}


# data --------------------------------------------------------------------

#' Tag a builder with structural/aesthetic metadata
#'
#' Attaches the self-declared metadata a custom `er_builder_*()`-style
#' function can carry, in a single call: which *structural* family a
#' data-layer builder belongs to (`layout`), what a builder's `fill`
#' aesthetic means when it isn't strata (`fill_role`), and what a
#' group-layer builder's y-axis means when it isn't the group variable
#' itself (`y_role`). All three arguments are optional and independent --
#' pass only the ones a given builder needs, in one call, rather than
#' chaining separate setters. See [er_partial()]'s "Writing your own
#' builder" section for the full contract.
#'
#' `layout` is the one required tag for a data-layer builder:
#' [er_plot_add_data()] reads it off `builder` to decide whether to route
#' through `.part_overlay()` (`"overlay"`: a single call merged into the
#' main panel, at the observations' true `(exposure, response)`
#' coordinates) or `.part_data()` (`"panel"`: one-or-more panels stacked
#' below the base plot), *before* it can call the builder -- so the choice
#' can't be inferred from the builder's return value. Both built-in data
#' builders ([er_builder_data_overlay()], [er_builder_data_boxjitter()])
#' already carry this tag.
#'
#' `fill_role` and `y_role` are both optional, read by `.polish_labels()`
#' to title a legend/axis correctly: `fill_role = "density"` (used by
#' [er_builder_data_hex()]) says a builder's `fill` aesthetic encodes bin
#' density rather than strata; `y_role = "count"` (used by
#' [er_builder_group_histogram()]) says a group-layer builder's y-axis
#' means counts rather than the group variable itself. A builder that
#' omits either tag keeps the default behaviour (`fill` means strata;
#' the y-axis is titled with the group variable's label), which is
#' correct for most builders.
#'
#' @param builder A function matching the standard `er_builder_*()` signature
#'   (see [er_partial()])
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
#'
#' @returns `builder`, with whichever of the `"er_builder_layout"`/
#'   `"er_builder_fill_role"`/`"er_builder_y_role"` attributes were
#'   requested attached
#'
#' @seealso [er_plot_add_data()], [er_partial()]
#'
#' @examples
#' build_data_density <- er_builder_tag(
#'   function(data, config, stratify, exposure, response, strata, style) {
#'     ggplot2::geom_density_2d(
#'       data = data,
#'       mapping = ggplot2::aes(x = .data[[exposure$name]], y = .data[[response$name]])
#'     )
#'   },
#'   layout = "overlay"
#' )
#'
#' @export
er_builder_tag <- function(builder, layout = NULL, fill_role = NULL, y_role = NULL) {
  if (!is.function(builder)) rlang::abort("`builder` must be a function")

  if (!is.null(layout)) {
    layout <- match.arg(layout, c("overlay", "panel"))
    attr(builder, "er_builder_layout") <- layout
  }
  if (!is.null(fill_role)) {
    attr(builder, "er_builder_fill_role") <- fill_role
  }
  if (!is.null(y_role)) {
    attr(builder, "er_builder_y_role") <- y_role
  }

  builder
}

#' @noRd
.builder_layout <- function(builder) {
  layout <- attr(builder, "er_builder_layout")
  if (is.null(layout)) {
    rlang::abort(c(
      "`builder` must declare its structural layout.",
      "i" = "Wrap a custom data-layer builder with `er_builder_tag(builder, layout = \"overlay\")` or `er_builder_tag(builder, layout = \"panel\")`.",
      "i" = "The built-in builders (`er_builder_data_overlay()`, `er_builder_data_boxjitter()`) already do this."
    ))
  }
  layout
}

#' @noRd
.builder_fill_role <- function(builder) {
  attr(builder, "er_builder_fill_role")
}

#' @noRd
.builder_y_role <- function(builder) {
  attr(builder, "er_builder_y_role")
}


#' Add a raw-data layer
#'
#' Adds the data layer: individual observations. By default (`builder =
#' er_builder_data_overlay`), points are drawn at their true `(exposure,
#' response)` coordinates in the *main* model panel -- a plain scatter for
#' continuous/count responses, or a scatter with a small vertical jitter
#' for a binary response (whose y-values are exactly 0/1 and would
#' otherwise overplot into two solid lines). This works uniformly across
#' all three response types, with no response-type dispatch on which
#' builder to use. `er_builder_data_boxjitter()` instead uses the older,
#' panel-based design, and is binary-response-only: responders (`response
#' == 1`) get a boxplot + jittered points in an upper panel and
#' non-responders (`response == 0`) get the same in a lower panel, so the
#' panel shows the exposure *distribution* conditional on response, not
#' just raw points. There is no built-in "panel"-layout builder for a
#' continuous/count response -- the older `build_data_color()` (a single
#' panel with points colored continuously by the response value) was
#' removed once `er_builder_data_overlay()` turned out to cover its typical
#' use case more simply; `panel` must be `"both"` (the default) for these
#' response types regardless of builder, since there's no upper/lower
#' partition to select from.
#'
#' Every data-layer builder declares which of these two *structural*
#' families it belongs to via [er_builder_tag()] -- `"overlay"` (a single call
#' merged into the main panel) or `"panel"` (one-or-more panels stacked
#' below the base plot) -- which `er_plot_add_data()` reads off `builder`
#' to decide how to assemble the layer, rather than taking a separate
#' argument for it. This makes the pairing structural rather than
#' incidental: `er_builder_data_overlay()` can never be routed into upper/lower
#' panels, and `er_builder_data_boxjitter()` can never be merged into the main
#' panel. See [er_builder_tag()] and [er_partial()] for how to tag a custom
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
#' @param builder Function drawing the data layer -- defaults to
#'   [er_builder_data_overlay()]. [er_builder_data_boxjitter()] (binary response
#'   only: a boxplot + jittered points per panel) is the other built-in
#'   option; any function matching the standard `(data, config, stratify,
#'   exposure, response, strata, style)` signature and tagged with
#'   [er_builder_tag()] can be supplied instead -- see [er_partial()] for the
#'   full contract, e.g. a 2D density in the main panel, a continuous/
#'   count response's color-encoded panel, or per-panel histograms.
#' @param panel Character string: `"upper"`, `"lower"`, or `"both"` (the
#'   default). Only meaningful for [er_builder_data_boxjitter()] on a binary
#'   response; must be `"both"` for an "overlay"-layout builder (no
#'   upper/lower partition exists) or for a continuous/count response
#'   under a "panel"-layout builder (there's no upper/lower partition to
#'   select from either way).
#'
#' @returns The input `object`, with the data layer added
#'
#' @examples
#' \dontrun{
#' library(erglm)
#' mod2 <- erglm_model(ae2 ~ aucss + sex, erglm_data, family = binomial())
#' erglm_data |>
#'   er_plot(aucss, ae2, stratify_by = sex) |>
#'   er_plot_add_model(mod2, keep_strata = FALSE) |>
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
#'   er_plot(aucss, ae2) |>
#'   er_plot_add_model(mod2) |>
#'   er_plot_add_data(builder = er_builder_data_boxjitter) |>
#'   plot()
#'
#' # plug in a 2D density in the main panel instead of a scatter; tagging
#' # it "overlay" via `er_builder_tag()` keeps it in the single main-panel
#' # layout -- see `?er_partial`
#' build_data_density <- er_builder_tag(
#'   function(data, config, stratify, exposure, response, strata, style) {
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
#'   er_plot_add_data(builder = build_data_density) |>
#'   plot()
#' }
#'
#' @seealso [er_plot()], [er_plot_add_model()],
#'   [er_plot_add_quantiles()], [er_plot_add_groups()], [er_partial()]
#'
#' @export
er_plot_add_data <- function(object, keep_strata = NULL, builder = NULL, panel = "both") {

  if (!inherits(object, "er_plot")) rlang::abort("`object` must be an er_plot object")
  if (!is.null(builder) && !is.function(builder)) rlang::abort("`builder` must be a function or NULL")

  builder <- builder %||% er_builder_data_overlay
  layout <- .builder_layout(builder)

  if (layout == "overlay" && panel != "both") {
    rlang::abort(c(
      "`panel` must be \"both\" for an \"overlay\"-layout `builder`.",
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

  # use `[` (not `$`) to clear the other slot -- `object$part$x <- NULL`
  # would remove "x" from the list entirely rather than setting it to
  # NULL, dropping it from `part_set`/`plot_set` in `print.er_plot()`
  if (layout == "overlay") {
    object$part$overlay <- .part_overlay(object = object, stratify = keep_strata, builder = builder)
    object$part["data"] <- list(NULL)
  } else {
    object$part$data <- .part_data(
      object = object,
      stratify = keep_strata, 
      panel = panel,
      builder = builder
    )
    object$part["overlay"] <- list(NULL)
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
#' Unlike the other three layers, this one is **additive** -- see
#' [er_plot()]'s "Layers are either singleton or additive" -- each call
#' adds another panel alongside any already added by a previous call,
#' rather than replacing it.
#'
#' @param object Partially constructed plot (has S3 class `er_plot`)
#' @param group_by Grouping variables to define groups for distribution
#'   plots (a tidyselection of variables)
#' @param builder Function drawing each group panel -- defaults to
#'   [er_builder_group_boxplot()]. [er_builder_group_violin()] is the other
#'   built-in option; any function matching the standard `(data, config,
#'   stratify, exposure, response, strata, style)` signature can be
#'   supplied instead -- see [er_partial()]. Applied to every grouping
#'   variable added by this call.
#' @param bins Number of quantile bins used for continuous grouping
#'   variables (`NULL`, the default, uses [cut_quantile()]'s own default)
#' @param keep_strata Logical, indicating whether this layer should be
#'   split by the plot's stratification variable; defaults to `TRUE` if
#'   `stratify_by` was set in [er_plot()], `FALSE` otherwise
#'
#' @returns The input `object`, with a group panel added
#'
#' @examples
#' \dontrun{
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
#' @seealso [er_plot()], [er_plot_add_model()],
#'   [er_plot_add_quantiles()], [er_plot_add_data()], [er_partial()]
#'
#' @export
er_plot_add_groups <- function(object, group_by, builder = NULL, bins = NULL, keep_strata = NULL) {

  if (!inherits(object, "er_plot")) rlang::abort("`object` must be an er_plot object")
  if (!is.null(builder) && !is.function(builder)) rlang::abort("`builder` must be a function or NULL")
  if (is.null(keep_strata)) keep_strata <- !is.null(object$strata$name)
  group_cols <- tidyselect::eval_select(rlang::enquo(group_by), object$data) 
  group_cols <- names(group_cols)

  object$part$group <- .part_group(
    object = object,
    group_cols = group_cols, 
    stratify = keep_strata, 
    bins = bins,
    builder = builder %||% er_builder_group_boxplot
  )

  return(object)  
}


# plot/print ------------------------------------------------------------------

#' @exportS3Method base::print
print.er_plot <- function(x, ...) {

  part_set <- !purrr::map_lgl(x$part, is.null)
  plot_set <- !purrr::map_lgl(x$plot, is.null)

  cat("<er_plot>\n")
  cat("  plot variables:\n")
  cat("    - exposure:        ", x$exposure$name  %||% "<none>", "\n", sep = "")
  cat("    - response:        ", x$response$name  %||% "<none>", "\n", sep = "")
  cat("    - stratification:  ", x$strata$name    %||% "<none>", "\n", sep = "")
  
  if (any(part_set)) {
    cat("  plot components:\n")
    if (part_set["model"])    cat("    - model:           ", paste(class(x$part$model$config$model), collapse = "/"), "\n", sep = "")
    if (part_set["quantile"]) cat("    - quantile:        ", x$part$quantile$config$n_quantiles, " bins\n", sep = "")
    if (part_set["data"])     cat("    - data:            ", x$part$data$config$layout, " ", x$part$data$config$panel, "\n", sep = "")
    if (part_set["overlay"])  cat("    - overlay:         ", if (x$part$overlay$stratify) "stratified" else "unstratified", "\n", sep = "")
    if (part_set["group"])    cat("    - group:           ", paste(names(x$part$group$config), collapse = ", "), "\n", sep = "")
  } else {
    cat("  plot components: <none>\n")
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
#' Assembles whichever layers have been added (via the `er_plot_show_*()`
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
  if (!is.null(object$part$model) | !is.null(object$part$quantile) | !is.null(object$part$overlay)) {
    object$plot$base <- .build_base_plot(object)
  }
  if (!is.null(object$part$data)) object$plot$data <- .build_data_plot(object)
  if (!is.null(object$part$group)) object$plot$group <- .build_group_plot(object)
  if (!is.null(object$part$overlay)) {
    object$plot$base <- object$plot$base + .build_overlay_geoms(object)
  }

  # polish
  object$plot <- .polish_margins(object)
  object$plot <- .polish_labels(object)
  composition <- .polish_arrangement(object)
  composition <- .polish_legends(object, composition)
  composition <- .polish_theme(object, composition)

  # output
  if (length(composition$heights) == 1) {
    object$output <- object$plot$base
  } else {
    object$output <- patchwork::wrap_plots(
      composition$plots, 
      ncol = 1, 
      heights = composition$info$size,
      guides = "collect",
      axes = "collect"
    ) + patchwork::plot_annotation(
      theme = object$style$theme_args()
    )
  }

  return(object)
}
