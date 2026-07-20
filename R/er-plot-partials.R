
#' Partial builders for exposure-response plots
#'
#' @param data The original data frame
#' @param config Configuration for the specific plot
#' @param stratify Logical indicating whether to stratify
#' @param exposure Exposure variable
#' @param response Response variable
#' @param strata Stratification variable
#' @param style Style components
#'
#' @details Things we can have partials for:
#' 
#' - model
#' - summary
#' - quantile
#' - data
#' - overlay
#' - group
#' 
#' Arguments are standardised to allow users to write their own 
#' as needed
#' 
#' @returns A geom, or a list of geoms. More precisely, a list of
#' objects that can be added to a ggplot2 plot. The expectation is
#' that these objects will be added to a partially-constructed plot
#' which, at a minimum, already has the base theme applied. For 
#' "model", "summary", "quantile", and "overlay", the pieces will be
#' added to a plot that already has a coord that sets the axis limits
#' (the base plot; see `.build_overlay_geoms()`). For the "data" (jitter/
#' color panel) and "group" plots, the plot object does not yet
#' have a coord. The expectation, however, is that the builder will
#' supply an x-axis limit that is consistent with the base plot. That
#' is, since all component plots use the exposure variable for the
#' x-axis, they should use the values stored in `exposure$limits` tp
#' set the x-axis limits.   
#'
#' @section Writing your own builder:
#'
#' Every `build_*()` function above shares the signature documented in
#' `@param`s, and that signature is a public part of the API, not an
#' implementation detail: any function `function(data, config, stratify,
#' exposure, response, strata, style)` that returns a geom or list of
#' geoms can stand in for a built-in builder. This is the officially
#' supported way to draw a layer differently from any of the built-in
#' `style` options -- e.g. a 2D density instead of a scatter for the data
#' overlay, per-panel histograms instead of jittered points for the
#' panel-based data layer, or a `geom_crossbar()` instead of a
#' `geom_errorbar()`/`geom_pointrange()` for the quantile summary.
#' (`build_quantile_pointrange()` started life as exactly this kind of
#' custom builder -- it was promoted to a built-in `style = "pointrange"`
#' option once it proved to be a natural, low-risk alternative to
#' `build_quantile_errorbar()`, with no new config requirements.)
#'
#' Each `er_plot_show_*()` function takes a `builder` argument (and
#' `er_plot_show_model()` additionally takes `summary_builder`) for
#' exactly this purpose: supplying a function there bypasses the built-in
#' `style` string dispatch entirely, so a custom builder can be plugged
#' in without forking the package or reaching into `object$part`
#' internals. For the data layer, `style` still selects the *structural*
#' family your builder is slotted into -- `"overlay"` (a single call
#' merged into the main panel) or `"jitter"` (one or more panels stacked
#' below the base plot, per `object$response$type`) -- while `builder`
#' selects the geoms drawn within that structure. For the other layers
#' there is only one structural call site, so `style` is ignored once
#' `builder` is supplied. See the `@examples` on [er_plot_show_model()],
#' [er_plot_show_quantiles()], and [er_plot_show_data()] for worked
#' custom builders (a dashed model curve, a quantile crossbar, and a
#' data-overlay density, respectively).
#'
#' A custom builder receives the same pre-computed `config` a built-in
#' builder would have received for that layer (e.g. `config$predictions`
#' for `model`, `config$summary` for `quantile`) -- it does not need to
#' recompute anything the corresponding `.part_*()` function already
#' derived from `data`/`exposure`/`response`/`strata`; it only needs to
#' turn that `config` into ggplot2 layers.
#'
#' All of the builders above feed a **singleton** layer: `model`,
#' `summary`, `quantile`, `data`, and `overlay` each occupy a single named
#' slot (`object$part$model`, `object$part$data`, etc.), so calling the
#' corresponding `er_plot_show_*()` function again overwrites the slot
#' rather than combining builders. `group` (`build_group_boxplot()`/
#' `build_group_violin()`) is the one **additive** exception -- each call
#' to `er_plot_show_groups()` adds another named entry rather than
#' replacing the previous one. See [er_plot()]'s "Layers are either
#' singleton or additive" section for the full discussion, including the
#' one flagged future exception (an additive `model` layer, for
#' overlaying two fitted curves).
#'
#' The `data` slot has two mutually exclusive builders, selected by
#' response type rather than by name: `build_data_jitter()` for a binary
#' response (color, when mapped, always means strata) and
#' `build_data_color()` for a continuous/count response (color always
#' means the response value itself). Because `build_data_color()`'s color
#' aesthetic is already spoken for, `config$color_role` (set by
#' `.part_data()`, consulted by `.polish_labels()`/`.polish_legends()` in
#' `R/er-plot-compose.R`) tags which meaning applies -- `"strata"` for
#' `build_data_jitter()`, `"response"` for `build_data_color()` -- so the
#' composition machinery knows whether a builder's legend is the shared
#' strata legend or a standalone response colorbar. `build_data_overlay()`
#' needs no such tag: its color aesthetic (when stratified) is always
#' strata, since the response is already shown via y-position, so it
#' shares the base plot's own strata legend directly. See
#' [er_plot_show_data()] for the user-facing version of this rule.
#' 
#' @name er_partial
#' 
NULL
