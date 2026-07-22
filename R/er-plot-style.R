
#' Builder functions for exposure-response plots
#'
#' @param data The original data frame
#' @param config Configuration for the specific plot
#' @param stratify Logical indicating whether to stratify
#' @param exposure Exposure variable
#' @param response Response variable
#' @param strata Stratification variable
#' @param theme Theme components
#' @param ... Additional named arguments forwarded from the corresponding
#'   `er_plot_add_*()` call's own `...`; see "Passing extra arguments to a
#'   builder" below.
#'
#' @details This page documents the shared interface all `er_style_*()`
#' builders implement. The builders themselves are documented on
#' their own family-specific pages, one per layer:
#'
#' - [er_style_model()] -- the `model` layer ([er_plot_add_model()])
#' - [er_style_summary()] -- the `summary` layer ([er_plot_add_summary()])
#' - [er_style_quantile()] -- the `quantile` layer ([er_plot_add_quantiles()])
#' - [er_style_data()] -- the `data` layer ([er_plot_add_data()])
#' - [er_style_group()] -- the `group` layer ([er_plot_add_groups()])
#'
#' Arguments are standardised to allow users to write their own 
#' as needed
#' 
#' @returns A geom, or a list of geoms. More precisely, a list of
#' objects that can be added to a ggplot2 plot. The expectation is
#' that these objects will be added to a partially constructed plot
#' which, at a minimum, already has the base theme applied. For 
#' "model", "summary", "quantile", and "overlay", the pieces will be
#' added to a plot that already has a coord that sets the axis limits
#' (the base plot; see `.build_overlay_geoms()`). For the "data"
#' (panel-based, e.g. `er_style_data_boxjitter()`) and "group" plots, the
#' plot object does not yet have a coord. The expectation, however, is that the builder will
#' supply an x-axis limit that is consistent with the base plot. That
#' is, since all layer plots use the exposure variable for the
#' x-axis, they should use the values stored in `exposure$limits` tp
#' set the x-axis limits.   
#'
#' @section Writing your own builder:
#'
#' Every `er_style_*()` function above shares the signature documented in
#' `@param`s, and that signature is a public part of the API, not an
#' implementation detail: any function `function(data, config, stratify,
#' exposure, response, strata, theme, ...)` that returns a geom or list of
#' geoms can stand in for a built-in builder. This is the officially
#' supported way to draw a layer differently from any of the built-in
#' `style` options -- e.g. a 2D density instead of a scatter for the
#' data overlay, per-panel histograms instead of jittered points for the
#' panel-based data layer, or a `geom_crossbar()` instead of a
#' `geom_errorbar()`/`geom_pointrange()` for the quantile summary.
#' (`er_style_quantile_pointrange()` started life as exactly this kind of
#' custom builder -- it was promoted to a built-in option once it proved
#' to be a natural, low-risk alternative to `er_style_quantile_errorbar()`,
#' with no new config requirements.)
#'
#' Each `er_plot_add_*()` function takes a `style` argument that
#' defaults to one built-in `er_style_*()` function and can be set to any
#' other -- built-in or custom -- matching the standard signature: a
#' custom builder can be plugged in without forking the package or
#' reaching into `object$layer` internals. For the data layer specifically,
#' `style` also has to declare which *structural* family it belongs to --
#' a single call merged into the main panel, or one or more panels
#' stacked below the base plot -- via [er_style_tag()], since
#' [er_plot_add_data()] reads that tag off `style` to decide how to
#' assemble the layer; the other three layers have only one structural
#' call site, so no such tagging is needed there. See the `@examples` on
#' [er_plot_add_model()], [er_plot_add_quantiles()], and
#' [er_plot_add_data()] for worked custom builders (a dashed model curve,
#' a quantile crossbar, and a data-overlay density, respectively).
#'
#' A custom builder receives the same pre-computed `config` a built-in
#' builder would have received for that layer (e.g. `config$predictions`
#' for `model`, `config$summary` for `quantile`) -- it does not need to
#' recompute anything the corresponding `.layer_*()` function already
#' derived from `data`/`exposure`/`response`/`strata`; it only needs to
#' turn that `config` into ggplot2 layers.
#'
#' A custom builder can optionally self-declare which layer it's meant
#' for via `er_style_tag(builder, layer = ...)` (one of `"model"`,
#' `"summary"`, `"quantile"`, `"data"`, `"group"`). Every
#' `er_plot_add_*()` function checks a builder's `layer` tag, if it has
#' one, against the layer it was actually passed to, erroring
#' immediately if they disagree -- e.g. passing a builder tagged
#' `layer = "quantile"` to [er_plot_add_data()] errors rather than
#' calling the builder with a `config` shape it wasn't written for.
#' This tag is entirely optional (unlike `layout`, which is mandatory
#' for a data-layer builder specifically) -- an untagged custom builder
#' is simply never checked, so existing custom builders keep working
#' unchanged. All built-in builders carry this tag.
#'
#' All of the builders above feed a **singleton** layer: `model`,
#' `summary`, `quantile`, `data`, and `overlay` each occupy a single named
#' slot (`object$layer$model`, `object$layer$data`, etc.), so calling the
#' corresponding `er_plot_add_*()` function again overwrites the slot
#' rather than combining builders. `group` (`er_style_group_boxplot()`/
#' `er_style_group_violin()`) is the one **additive** exception -- each call
#' to `er_plot_add_groups()` adds another named entry rather than
#' replacing the previous one. See [er_plot()]'s "Layers are either
#' singleton or additive" section for the full discussion, including the
#' one flagged future exception (an additive `model` layer, for
#' overlaying two fitted curves).
#'
#' The `data` slot's default, `er_style_data_overlay()`, needs no
#' `color_role` tag: its color aesthetic (when stratified) is always
#' strata, since the response is already shown via y-position, so it
#' shares the base plot's own strata legend directly. `config$color_role`
#' (set by `.layer_data()`, consulted by `.polish_labels()`/
#' `.polish_legends()` in `R/er-plot-compose.R`) matters for the
#' "panel"-layout family instead, where it's `"strata"` for a binary
#' response (as used by the built-in `er_style_data_boxjitter()`, whose
#' color aesthetic still means strata) or `"response"` for a
#' continuous/count response, where the color channel is already spoken
#' for by the response value itself -- there's no built-in
#' "panel"-layout builder for that case (the older `build_data_color()`
#' was removed once `er_style_data_overlay()` covered its typical use case
#' more simply), but a custom builder tagged `er_style_tag(builder,
#' layout = "panel")` can still opt into it; see [er_plot_add_data()] for
#' the user-facing version of this rule.
#'
#' @section Passing extra arguments to a builder:
#'
#' Every `er_plot_add_*()` function (`er_plot_add_model()`,
#' `er_plot_add_summary()`, `er_plot_add_quantiles()`, `er_plot_add_data()`,
#' `er_plot_add_groups()`) takes its own `...`, which is forwarded
#' unchanged to `style` when it's actually called at build time. Extra
#' arguments must be named, since they're appended positionally
#' after the seven standard arguments; an unnamed one errors immediately
#' rather than silently binding to the wrong parameter. This is how a
#' builder that needs a piece of information beyond what `config` already
#' carries -- something genuinely per-call rather than a fixed part of the
#' layer's configuration -- can accept it without a bespoke argument on
#' every `er_plot_add_*()` function. The motivating built-in example is
#' [er_style_model_spaghetti()], which calls [er_simulate()] and, for
#' models (like erglm's) that auto-select and report a seed when none is
#' supplied, would otherwise always trigger that message:
#'
#' ```r
#' erglm_data |>
#'   er_plot(aucss, ae1) |>
#'   er_plot_add_model(mod, style = er_style_model_spaghetti, seed = 9626) |>
#'   plot()
#' ```
#'
#' A builder that doesn't need any extra arguments simply declares `...`
#' and ignores it -- every built-in builder does exactly this except
#' `er_style_model_spaghetti()`. A custom builder can read whichever named
#' arguments it recognizes out of its own `...` (e.g. via
#' `rlang::list2(...)`) and ignore the rest; unrecognized extra arguments
#' are never an error at the builder itself, only at the `er_plot_add_*()`
#' call site if they weren't named.
#'
#' @name er_style
#' @seealso [er_style_model()], [er_style_summary()], [er_style_quantile()],
#' [er_style_data()], [er_style_group()], [er_style_tag()]
#' 
NULL
