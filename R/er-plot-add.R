
# model -----------------------------------------------------------------------

#' Add a fitted-model curve/ribbon layer
#'
#' Adds the model layer: a fitted exposure-response curve with an
#' uncertainty ribbon, or possibly a spaghetti plot of simulated draws.
#'
#' @param object Partially constructed plot (has S3 class `er_plot`).
#' @param model A fitted exposure-response model. Must implement [er_predict()].
#' @param keep_strata Logical; whether this layer should use stratification.
#' @param style Function drawing the model curve/ribbon. Defaults to [er_style_model_ribbonline()].
#' @param conf_level Confidence level for the prediction ribbon.
#' @param predict_args A named list of additional arguments forwarded to
#'   [er_predict()] (e.g. a model-specific argument its `er_predict()`
#'   method requires beyond `model`/`newdata`/`conf_level`). Distinct
#'   from `...`: `predict_args` reaches [er_predict()], `...` reaches
#'   `style` -- see "Details".
#' @param ... Additional named arguments forwarded unchanged to `style` at build time.
#'
#' @details
#' This layer uses [er_predict()] to compute model predictions on the response scale. `model` may reference covariates beyond the exposure and strata variables. erplots fills any additional covariates from the plot data with a reference value (first factor level or numeric mean) when building the prediction grid. erplots does not check that `model` was fit on the same exposure/response as the plot; the caller must ensure compatibility.
#'
#' `predict_args` and `...` serve two different consumers and are kept
#' separate rather than sharing one `...`: `predict_args` is spliced into
#' the [er_predict()] call (e.g. `predict_args = list(landmark_time =
#' 90)` for a model whose `er_predict()` method needs a `landmark_time`
#' argument with no other slot in the fixed `er_predict(model, newdata,
#' conf_level)` contract), while `...` is forwarded to `style` alone
#' (see [er_style()]'s "Passing extra arguments to a builder" section).
#' Reusing a single `...` for both would risk a silent name collision if
#' a style builder and a model's `er_predict()` method happened to share
#' an argument name for unrelated purposes.
#'
#' @returns The input `object`, with the model layer added.
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
#' # plug in a fully custom model-curve builder
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
#' # a model with a covariate beyond the exposure variable still works even when 
#' # this layer isn't stratifying by it: `sex` is set to a reference value 
#' # when building the prediction grid, which may not be what the user wants
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
                                style = NULL, conf_level = 0.95,
                                predict_args = list(), ...) {

  dots <- rlang::list2(...)
  .check_dots_named(dots)
  .check_dots_named(predict_args, arg = "predict_args")
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
    predict_args = predict_args,
    style = style,
    dots = dots
  )
  
  return(object)
}


# summary -----------------------------------------------------------------

#' Add a summary annotation layer
#'
#' Adds the summary layer: a text/label annotation placed in whichever
#' corner of the base panel is furthest from the observed data, computed 
#' from the raw `(exposure, response)` coordinates of the data. 
#' 
#' @param object Partially constructed plot (has S3 class `er_plot`).
#' @param model A fitted exposure-response model, or `NULL` (the default).
#'   Only needed for builder styles (e.g.
#'   [er_style_summary_pvalue()]) that produced model-based summaries; a
#'   purely descriptive builder (e.g. [er_style_summary_n()]) ignores it.
#' @param keep_strata Logical, indicating whether this layer should be
#'   split by the plot's stratification variable; defaults to `TRUE` if
#'   `stratify_by` was set in [er_plot()], `FALSE` otherwise.
#' @param style Function drawing the summary annotation, defaulting to
#'   [er_style_summary_pvalue()].
#' @param conf_level Confidence level forwarded to [er_summary()] (used,
#'   e.g., for the `conf_low`/`conf_high` columns of its `coefficients`
#'   result -- see `?er_model_interface`). Ignored when `model` is `NULL`.
#' @param summary_args A named list of additional arguments forwarded to
#'   [er_summary()], distinct from `...` the same way
#'   [er_plot_add_model()]'s `predict_args` is distinct from its own
#'   `...` -- see "Details" there.
#' @param ... Additional named arguments forwarded, unchanged, to `style`
#'   when it's called at build time; see [er_style()]'s "Passing extra
#'   arguments to a builder" section. Must be named.
#'
#' @returns The input `object`, with the summary layer added.
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
er_plot_add_summary <- function(object, model = NULL, keep_strata = NULL, style = NULL,
                                  conf_level = 0.95, summary_args = list(), ...) {

  dots <- rlang::list2(...)
  .check_dots_named(dots)
  .check_dots_named(summary_args, arg = "summary_args")
  if (!inherits(object, "er_plot")) rlang::abort("`object` must be an er_plot object")
  if (!is.null(style) && !is.function(style)) rlang::abort("`style` must be a function or NULL")
  if (is.null(keep_strata)) keep_strata <- !is.null(object$strata$name)

  style <- style %||% er_style_summary_pvalue
  .check_style_layer(style, "summary")

  object$layer$summary <- .layer_summary(
    object = object,
    model = model,
    stratify = keep_strata,
    conf_level = conf_level,
    summary_args = summary_args,
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
#' summarised with a point estimate and confidence interval. 
#' 
#' @param object Partially constructed plot, an `er_plot` object.
#' @param keep_strata Logical, indicating whether this layer should be
#'   split by the plot's stratification variable; defaults to `TRUE` if
#'   `stratify_by` was set in [er_plot()], `FALSE` otherwise.
#' @param style Function drawing the quantile summary; defaults to
#'   [er_style_quantile_errorbar()] (point + error bar).
#' @param bins Number of exposure bins (not counting placebo).
#' @param conf_level Confidence level for the interval.
#' @param ... Additional named arguments forwarded, unchanged, to `style`
#'   when it's called at build time. Arguments must be named.
#'
#' @returns The input `object`, with the quantile layer added.
#' 
#' @details
#' The type of confidence interval shown depends on the `response_type`
#' set in [er_plot()]:
#' * `"binary"`: Clopper-Pearson interval (see [ci_clopper_pearson()])
#' * `"continuous"`: Student t-interval (see [ci_t()])
#' * `"count"`: exact Poisson interval (see [ci_poisson()])
#'
#' Note that count responses are not automatically detected as such: they
#' default to `"continuous"` and are summarised the same way as any other
#' continuous response unless `response_type = "count"` is declared
#' explicitly in [er_plot()].
#'
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
#' # plug in a fully custom builder; see `?er_style`
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
#'   [er_plot_add_data()], [er_plot_add_groups()], [er_vpc()],
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

#' Add a raw-data layer
#'
#' Adds the data layer: individual observations. By default, points are drawn 
#' as an overlay showing the exposure and response values in the main panel of
#' the plot, but other possibilities are available.  
#'
#' @param object Partially constructed plot (has S3 class `er_plot`).
#' @param keep_strata Logical, indicating whether this layer should be
#'   split by the plot's stratification variable; defaults to `TRUE` if
#'   `stratify_by` was set in [er_plot()], `FALSE` otherwise. See
#'   "Details" for how this interacts with a builder's structural family.
#' @param style Function drawing the data layer -- defaults to
#'   [er_style_data_overlay()]. Any function matching the standard
#'   `(data, config, stratify, exposure, response, strata, theme, ...)`
#'   signature and tagged with [er_style_tag()] can be supplied instead;
#'   see [er_style()] and "Details".
#' @param panel Character string: `"upper"`, `"lower"`, or `"both"` (the
#'   default). Only meaningful for [er_style_data_boxjitter()] on a
#'   binary response; see "Details" for when `"both"` is required.
#' @param ... Additional named arguments forwarded, unchanged, to `style`
#'   when it's called at build time -- see [er_style()]'s "Passing extra
#'   arguments to a builder" section. Must be named.
#'
#' @returns The input `object`, with the data layer added.
#' 
#' @details
#' The default builder for the data layer is `er_style_data_overlay()`, 
#' which creates a plain scatter plot for
#' continuous/count responses, or a scatter with a small vertical jitter
#' for a binary response (whose y-values are exactly 0/1 and would
#' otherwise overplot into two solid lines). This works uniformly across
#' all three response types, with no response-type dispatch on which
#' builder to use. `er_style_data_boxjitter()` instead uses a
#' panel-based design, and is binary-response-only: responders (`response
#' == 1`) get a boxplot + jittered points in an upper panel and
#' non-responders (`response == 0`) get the same in a lower panel, so the
#' panel shows the exposure *distribution* conditional on response, not
#' just raw points. There is no built-in "panel"-layout builder for a
#' continuous/count response; `panel` must be `"both"` (the default) for these
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
#' builder the same way. If `style` is tagged with a `layer` other than
#' `"data"`, [er_plot_add_data()] errors informatively; an untagged
#' builder is never checked (only `layout` is a hard requirement).
#'
#' `keep_strata`'s effect also depends on a builder's structural family:
#' for an "overlay"-layout builder it always means a shared color
#' aesthetic, for any response type; for a "panel"-layout builder on a
#' continuous/count response it instead produces one panel per stratum
#' level rather than a shared color aesthetic. `panel` must be `"both"`
#' for an "overlay"-layout builder (there's no upper/lower partition to
#' select from) and for a continuous/count response under a
#' "panel"-layout builder (same reason).
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
#' # panel-based design, binary-response only: a boxplot + jittered
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
#' grouping variables are binned into quantiles first.
#'
#' @param object Partially constructed plot (has S3 class `er_plot`).
#' @param group_by Grouping variables to define groups for distribution
#'   plots (a tidyselection of variables).
#' @param style Function drawing each group panel -- defaults to
#'   [er_style_group_boxplot()]. Applied to every grouping variable added
#'   by this call; see [er_style()] and "Details".
#' @param bins Number of quantile bins used for continuous grouping
#'   variables (`NULL`, the default, uses [cut_quantile()]'s own default).
#' @param keep_strata Logical, indicating whether this layer should be
#'   split by the plot's stratification variable; defaults to `TRUE` if
#'   `stratify_by` was set in [er_plot()], `FALSE` otherwise. See
#'   "Details" for an error case.
#' @param ... Additional named arguments forwarded, unchanged, to `style`
#'   when it's called at build time (identically for every grouping
#'   variable added by this call) -- see [er_style()]'s "Passing extra
#'   arguments to a builder" section. Must be named.
#'
#' @returns The input `object`, with a group panel added.
#' 
#' @details
#' Unlike the other four layers, the groups layer is **additive**: each call
#' adds another panel alongside any already added by a previous call,
#' rather than replacing it.
#'
#' [er_style_group_violin()] and [er_style_group_histogram()] are the
#' other built-in `style` options; any function matching the standard
#' `(data, config, stratify, exposure, response, strata, theme, ...)`
#' signature can be supplied instead. If `style` is tagged with a
#' `layer` (via [er_style_tag()]) other than `"group"`, this errors
#' informatively; an untagged builder is never checked.
#'
#' `keep_strata = TRUE` errors if `group_by` is itself the plot's
#' stratification variable, since that would mean grouping and
#' stratifying by the same column at once; pass `keep_strata = FALSE`
#' for that grouping variable instead.
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
