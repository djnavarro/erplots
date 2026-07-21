
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
#' @details This page documents the shared interface all `build_*()`
#' partial builders implement. The builders themselves are documented on
#' their own family-specific pages, one per layer:
#'
#' - [build_model()] -- the `model` layer ([er_plot_show_model()])
#' - [build_summary()] -- the `summary_builder` argument of [er_plot_show_model()]
#' - [build_quantile()] -- the `quantile` layer ([er_plot_show_quantiles()])
#' - [build_data()] -- the `data` layer ([er_plot_show_data()])
#' - [build_group()] -- the `group` layer ([er_plot_show_groups()])
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
#' (the base plot; see `.build_overlay_geoms()`). For the "data"
#' (panel-based, e.g. `build_data_boxjitter()`) and "group" plots, the
#' plot object does not yet have a coord. The expectation, however, is that the builder will
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
#' `builder` options -- e.g. a 2D density instead of a scatter for the
#' data overlay, per-panel histograms instead of jittered points for the
#' panel-based data layer, or a `geom_crossbar()` instead of a
#' `geom_errorbar()`/`geom_pointrange()` for the quantile summary.
#' (`build_quantile_pointrange()` started life as exactly this kind of
#' custom builder -- it was promoted to a built-in option once it proved
#' to be a natural, low-risk alternative to `build_quantile_errorbar()`,
#' with no new config requirements.)
#'
#' Each `er_plot_show_*()` function takes a `builder` argument (and
#' `er_plot_show_model()` additionally takes `summary_builder`) that
#' defaults to one built-in `build_*()` function and can be set to any
#' other -- built-in or custom -- matching the standard signature, with no
#' string-based `style` argument in between: a custom builder can be
#' plugged in without forking the package or reaching into `object$part`
#' internals. For the data layer specifically, `builder` also has to
#' declare which *structural* family it belongs to -- a single call
#' merged into the main panel, or one or more panels stacked below the
#' base plot -- via [er_layout()], since [er_plot_show_data()] reads that
#' tag off `builder` to decide how to assemble the layer; the other three
#' layers have only one structural call site, so no such tagging is
#' needed there. See the `@examples` on [er_plot_show_model()],
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
#' The `data` slot's default, `build_data_overlay()`, needs no
#' `color_role` tag: its color aesthetic (when stratified) is always
#' strata, since the response is already shown via y-position, so it
#' shares the base plot's own strata legend directly. `config$color_role`
#' (set by `.part_data()`, consulted by `.polish_labels()`/
#' `.polish_legends()` in `R/er-plot-compose.R`) matters for the
#' "panel"-layout family instead, where it's `"strata"` for a binary
#' response (as used by the built-in `build_data_boxjitter()`, whose
#' color aesthetic still means strata) or `"response"` for a
#' continuous/count response, where the color channel is already spoken
#' for by the response value itself -- there's no built-in
#' "panel"-layout builder for that case (the older `build_data_color()`
#' was removed once `build_data_overlay()` covered its typical use case
#' more simply), but a custom builder tagged `er_layout(builder,
#' "panel")` can still opt into it; see [er_plot_show_data()] for the
#' user-facing version of this rule.
#' 
#' @name er_partial
#' @seealso [build_model()], [build_summary()], [build_quantile()],
#' [build_data()], [build_group()], [er_layout()]
#' 
NULL
