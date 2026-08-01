
#' Builder functions for exposure-response plots
#'
#' Documents the shared `function(data, config, stratify, exposure, response,
#' strata, theme, ...)` signature every `er_style_*()` builder implements,
#' including how to write a custom one.
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
#' (the base plot). For the "data"
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
#' reaching into the plot object's internal state. For the data layer specifically,
#' `style` also has to declare which *structural* family it belongs to --
#' a single call merged into the main panel, or one or more panels
#' stacked below the base plot -- via [er_style_tag()], since
#' [er_plot_add_data()] reads that tag off `style` to decide how to
#' assemble the layer; the other four layers have only one structural
#' call site, so no such tagging is needed there. See the `@examples` on
#' [er_plot_add_model()], [er_plot_add_quantiles()], and
#' [er_plot_add_data()] for worked custom builders (a dashed model curve,
#' a quantile crossbar, and a data-overlay density, respectively). An
#' overlay-layout data builder can additionally declare, via the same
#' [er_style_tag()] call's `zorder` argument, whether its geoms are drawn
#' before or after the model/summary/quantile layers when they share the
#' main panel -- relevant for a builder whose geoms cover the whole panel
#' (e.g. `er_style_data_hex()`), which would otherwise bury those layers
#' by drawing on top of them; see [er_style_data()] for the full
#' explanation.
#'
#' A custom builder receives the same pre-computed `config` a built-in
#' builder would have received for that layer (e.g. `config$predictions`
#' for `model`, `config$summary` for `quantile`) -- it does not need to
#' recompute anything erplots already derived from `data`/`exposure`/
#' `response`/`strata`; it only needs to turn that `config` into ggplot2
#' layers.
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
#' `summary`, `quantile`, `data`, and `overlay` each occupy a single slot
#' in the plot's internal state, so calling the corresponding
#' `er_plot_add_*()` function again overwrites that slot rather than
#' combining builders. `group` (`er_style_group_boxplot()`/
#' `er_style_group_violin()`) is the one **additive** exception -- each call
#' to `er_plot_add_groups()` adds another named entry rather than
#' replacing the previous one. See [er_plot()]'s "Layers are either
#' singleton or additive" section for the full discussion.
#'
#' The `data` slot's default, `er_style_data_overlay()`, needs no
#' `color_role` tag: its color aesthetic (when stratified) is always
#' strata, since the response is already shown via y-position, so it
#' shares the base plot's own strata legend directly. `config$color_role`
#' matters for the "panel"-layout family instead, where it's `"strata"`
#' for a binary response (as used by the built-in
#' `er_style_data_boxjitter()`, whose color aesthetic still means strata)
#' or `"response"` for a continuous/count response, where the color
#' channel is already spoken for by the response value itself -- there's
#' no built-in "panel"-layout builder for that case today, but a custom
#' builder tagged `er_style_tag(builder, layout = "panel")` can still opt
#' into it; see [er_plot_add_data()] for the user-facing version of this
#' rule.
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


#' Tag a builder with structural/aesthetic metadata
#'
#' Attaches the self-declared metadata a custom `er_style_*()`-style
#' function can carry.
#' 
#' @param style A function matching the standard `er_style_*()` signature
#'   (see [er_style()]).
#' @param layout One of `"overlay"` or `"panel"`, or `NULL` (the default) to
#'   leave this tag unset. See [er_plot_add_data()] for what each
#'   structural family means.
#' @param fill_role A string naming what the builder's `fill` aesthetic
#'   represents, or `NULL` (the default) to leave this tag unset.
#' @param y_role A string naming what the builder's y-axis represents, 
#'   or `NULL` (the default) to leave this tag unset.
#' @param layer One of `"model"`, `"summary"`, `"quantile"`, `"data"`,
#'   `"group"`, `"observed"`, or `"simulated"`, naming which
#'   `er_plot_add_*()`/`er_vpc_add_*()` layer the builder is meant to be
#'   used with, or `NULL` (the default) to leave this tag unset. See
#'   "Details".
#' @param zorder One of `"foreground"` or `"background"`, or `NULL` (the
#'   default, equivalent to `"foreground"`) to leave this tag unset. Only
#'   meaningful for an overlay-layout data builder; see "Details".
#'
#' @returns `style`, with whichever of the `"er_style_layout"`/
#'   `"er_style_fill_role"`/`"er_style_y_role"`/`"er_style_layer"`/
#'   `"er_style_zorder"` attributes were requested attached.
#'

#' @details
#' The metadata to be supplied indicate which *structural* family a
#' data-layer builder belongs to (`layout`), what a builder's `fill`
#' aesthetic means when it isn't strata (`fill_role`), what a group-layer
#' builder's y-axis means when it isn't the group variable itself
#' (`y_role`), which layer a builder is meant to be plugged into
#' (`layer`), and where an overlay-layout data builder's geoms sit
#' relative to the model/summary/quantile layers when they share the main
#' panel (`zorder`). All five arguments are optional and independent --
#' pass only the ones a given builder needs, in one call, rather than
#' chaining separate setters.
#'
#' `layout` is a required tag for a data-layer builder:
#' [er_plot_add_data()] reads it off `style` to decide whether to place 
#' the output geoms into the main panel (`layout = "overlay"`) or to put them into
#' separate strip-like panels above and below the main panel (`layout = "panel"`)
#'
#' `fill_role` and `y_role` are both optional, and can be used
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
#' for labelling. It's read by every `er_plot_add_*()` function
#' (`er_plot_add_model()` checks `style` against `"model"`;
#' `er_plot_add_summary()` checks `style` against `"summary"`;
#' `er_plot_add_quantiles()`
#' against `"quantile"`; `er_plot_add_data()` against `"data"`;
#' `er_plot_add_groups()` against `"group"`) to catch a builder plugged
#' into the wrong layer -- e.g. passing a quantile builder to
#' `er_plot_add_data()` -- with an informative error instead of whatever
#' failure results from that layer's `config` shape not matching what the
#' builder expects. All built-in builders carry this tag. A custom
#' builder that omits it is never checked: `layer` is opt-in, not a
#' requirement like `layout` is for a data-layer builder.
#'
#' `zorder` only applies to an overlay-layout data builder (`layout =
#' "overlay"`), and controls whether its geoms are drawn before or after
#' the model/summary/quantile layers when they share the main panel.
#' `"foreground"`, the default for a builder that omits this tag (e.g.
#' `er_style_data_overlay()`), draws the data geoms last, on top of
#' everything else -- appropriate for a sparse layer like individual
#' points, which should never be hidden behind a model ribbon.
#' `"background"` (used by `er_style_data_hex()`) draws the data geoms
#' first, so a builder whose geoms cover the whole panel (leaving no gaps
#' for what's underneath to show through) doesn't bury the model curve or
#' summary annotation. `zorder` has no effect on a panel-layout data
#' builder (e.g. `er_style_data_boxjitter()`), since those geoms are
#' drawn in their own separate panels, never sharing space with the model/
#' summary/quantile layers.
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
er_style_tag <- function(style, layout = NULL, fill_role = NULL, y_role = NULL, layer = NULL, zorder = NULL) {
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
    layer <- match.arg(layer, c("model", "summary", "quantile", "data", "group", "observed", "simulated"))
    attr(style, "er_style_layer") <- layer
  }
  if (!is.null(zorder)) {
    zorder <- match.arg(zorder, c("foreground", "background"))
    attr(style, "er_style_zorder") <- zorder
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
.style_zorder <- function(style) {
  zorder <- attr(style, "er_style_zorder")
  if (is.null(zorder)) "foreground" else zorder
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
