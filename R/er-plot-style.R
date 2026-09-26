
#' Builder functions for exposure-response plots
#'
#' Documents the shared `function(data, config, stratify, exposure, response,
#' strata, theme, ...)` signature every `er_style_*()` builder implements,
#' including how to write a custom one.
#'
#' @section Arguments:
#' Every `er_style_*()` builder receives:
#'
#' - `data` -- The original data frame
#' - `config` -- Configuration for the specific plot
#' - `stratify` -- Logical indicating whether to stratify
#' - `exposure` -- Exposure variable
#' - `response` -- Response variable
#' - `strata` -- Stratification variable
#' - `theme` -- Theme components
#' - `...` -- Additional named arguments forwarded from the corresponding
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
#' `er_vpc()`/`er_tte()` have their own, separate builder interfaces --
#' [er_style_vpc()]/[er_style_tte()] -- since neither shares this
#' signature exactly (`er_vpc_*()` builders have no `stratify`/`strata`
#' pair; `er_tte_*()` builders take `time` instead of `exposure`/
#' `response`).
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
#' x-axis, they should use the values stored in `exposure$limits` to
#' set the x-axis limits.
#'
#' @section Writing your own builder:
#'
#' Every `er_style_*()` function above shares the signature documented in
#' the "Arguments" section above, and that signature is a public part of the API, not an
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
#' [er_style_tag()] call's `draw_order` argument, whether its geoms are
#' drawn before or after the model/summary/quantile layers when they share
#' the main panel -- relevant for a builder whose geoms cover the whole
#' panel (e.g. `er_style_data_hex()`), which would otherwise bury those
#' layers by drawing on top of them; see [er_style_data()] for the full
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
#' for via `er_style_tag(builder, layer = ...)` (one of `"plot_model"`,
#' `"plot_summary"`, `"plot_quantile"`, `"plot_data"`, `"plot_group"`). Every
#' `er_plot_add_*()` function checks a builder's `layer` tag, if it has
#' one, against the layer it was actually passed to, erroring
#' immediately if they disagree -- e.g. passing a builder tagged
#' `layer = "plot_quantile"` to [er_plot_add_data()] errors rather than
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
#' `color_role` tag: its colour aesthetic (when stratified) is always
#' strata, since the response is already shown via y-position, so it
#' shares the base plot's own strata legend directly. `config$color_role`
#' matters for the "panel"-layout family instead, where it's `"strata"`
#' for a binary response (as used by the built-in
#' `er_style_data_boxjitter()`, whose colour aesthetic still means strata)
#' or `"response"` for a continuous/count response, where the colour
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
#' `rlang::list2(...)`) and ignore the rest; unrecognised extra arguments
#' are never an error at the builder itself, only at the `er_plot_add_*()`
#' call site if they weren't named.
#'
#' @name er_style
#' @seealso [er_style_model()], [er_style_summary()], [er_style_quantile()],
#' [er_style_data()], [er_style_group()], [er_style_tag()], [er_style_vpc()],
#' [er_style_tte()]
#' 
NULL


#' Register a builder's structural/aesthetic metadata
#'
#' `er_style_tag()` is the single, shared self-declaration mechanism every
#' `er_style_*()` builder in the package -- across all three grammars,
#' [er_plot()]/[er_vpc()]/[er_tte()] alike -- can opt into. Attaching a tag
#' turns a plain builder function into one the relevant `_add_*()` function
#' can check itself against: which structural family it belongs to, which
#' layer it's meant for, which response/`plot_by` types it supports, and a
#' couple of narrower rendering/labelling hints. In that sense it functions
#' as an informal builder registry -- not a lookup table you register
#' *into*, but a way of stamping a function with metadata another function
#' can later read back off it and act on, entirely by attribute, with no
#' central list anywhere. Every built-in builder carries a tag; nothing
#' requires a custom builder to.
#'
#' @param style A function matching the standard signature for the grammar
#'   it's meant for -- see [er_style()] (`er_plot()`), [er_style_vpc()]
#'   (`er_vpc()`), or [er_style_tte()] (`er_tte()`).
#' @param layout One of `"overlay"` or `"panel"`, or `NULL` (the default) to
#'   leave this tag unset. Data-layer ([er_plot_add_data()]) builders only --
#'   see "Details".
#' @param vpc_layout One of `"categorical"` or `"continuous"`, or `NULL`
#'   (the default) to leave this tag unset. VPC observed/simulated
#'   ([er_vpc_add_observed()]/[er_vpc_add_simulated()]) builders only -- see
#'   "Details".
#' @param fill_role A string naming what the builder's `fill` aesthetic
#'   represents, or `NULL` (the default) to leave this tag unset.
#' @param y_role A string naming what the builder's y-axis represents, 
#'   or `NULL` (the default) to leave this tag unset.
#' @param layer One of `"plot_model"`, `"plot_summary"`, `"plot_quantile"`,
#'   `"plot_data"`, `"plot_group"`, `"vpc_observed"`, `"vpc_simulated"`,
#'   `"tte_curve"`, `"tte_censor"`, `"tte_risktable"`, `"tte_model"`, or
#'   `"tte_summary"`, naming which
#'   `er_plot_add_*()`/`er_vpc_add_*()`/`er_tte_add_*()` layer the
#'   builder is meant to be used with, or `NULL` (the default) to leave
#'   this tag unset. Each value is prefixed with the grammar it belongs to
#'   (`plot_`/`vpc_`/`tte_`) -- see "Details".
#' @param draw_order One of `"foreground"` or `"background"`, or `NULL` (the
#'   default, equivalent to `"foreground"`) to leave this tag unset. Only
#'   meaningful for an overlay-layout data builder; see "Details".
#' @param response_types A character vector with one or more of
#'   `"binary"`, `"continuous"`, `"count"`, or `NULL` (the default) to
#'   leave this tag unset (no restriction declared). For a VPC
#'   observed/simulated builder, declares which of `er_vpc()`'s
#'   `response_type` values the builder supports; see "Details".
#' @param plot_by_types A character vector with one or more of
#'   `"continuous"`, `"discrete"`, or `NULL` (the default) to leave this
#'   tag unset. For a VPC observed/simulated builder, declares which of
#'   `object$group$type` values (see [er_vpc()]'s `plot_by` argument)
#'   the builder supports; see "Details".
#' @param marker_source One of `"summary"` or `"percentiles"`, naming
#'   which of a VPC observed/simulated builder's two config tables
#'   (`config$summary` or `config$percentiles`) it actually draws its
#'   marker(s) from, or `NULL` (the default) to leave this tag unset. See
#'   "Details".
#' @param label A single string, or `NULL` (the default) to leave this tag
#'   unset. Requires `layer` to also be set in the same
#'   call. Registers `style` so it can be selected by this short string
#'   (e.g. `style = "logrank"`) instead of the function itself, wherever
#'   the corresponding `_add_*()` function looks it up. See
#'   [er_style_labels()].
#' @param overwrite Logical, default `FALSE`. Only meaningful together with
#'   `label`; ignored otherwise. Controls what happens when the `(layer,
#'   label)` pair is already registered to a *different* function:
#'   `FALSE` (the default) errors; `TRUE` replaces the existing
#'   registration unconditionally. Re-registering the identical function
#'   is always a silent no-op regardless of `overwrite`. See "Details".
#'
#' @returns `style`, with whichever of the `"er_style_layout"`/
#'   `"er_style_vpc_layout"`/`"er_style_fill_role"`/`"er_style_y_role"`/
#'   `"er_style_layer"`/`"er_style_draw_order"`/`"er_style_response_types"`/
#'   `"er_style_plot_by_types"`/`"er_style_vpc_marker_source"`/
#'   `"er_style_label"` attributes were requested attached. When `label` is
#'   supplied, `style` is also registered as a side effect -- see
#'   [er_style_labels()].
#'

#' @details
#' Nine tags exist today, each optional and independent -- pass only the
#' ones a given builder needs, in one call, rather than chaining separate
#' setters. They fall into three groups: which *structural* family a
#' builder belongs to (`layout` for the data layer, `vpc_layout` for a VPC
#' builder -- deliberately two separate arguments, not one shared value
#' space, since the two pairs mean unrelated things), which layer it's
#' meant to be plugged into (`layer`, a flat namespace shared across all
#' three grammars), and a handful of narrower rendering/labelling/checking
#' hints (`fill_role`, `y_role`, `draw_order`, `response_types`,
#' `plot_by_types`, `marker_source`).
#'
#' `layout` is a required tag for a data-layer builder specifically:
#' [er_plot_add_data()] reads it off `style` to decide whether to place 
#' the output geoms into the main panel (`layout = "overlay"`) or to put them into
#' separate strip-like panels above and below the main panel (`layout = "panel"`).
#' No other layer or grammar uses this tag.
#'
#' `vpc_layout` is the VPC analogue, but optional rather than required, and
#' checked between two builders rather than read for a structural decision:
#' when present on both the observed and simulated builder passed to a
#' given `er_vpc` object, [er_vpc_add_simulated()] errors if they disagree
#' (`"categorical"`, discrete bin locations; or `"continuous"`, numeric
#' bin-midpoint locations, e.g. [er_style_vpc_simulated_quantile_ribbon()]).
#' This catches the case where the two families would otherwise silently
#' plot at different x-positions for the same bin -- e.g. pairing a builder
#' that always plots at discrete bin labels with
#' [er_style_vpc_simulated_quantile_ribbon()]'s numeric midpoints. Use a
#' layout-matched pair instead (built-ins already are), or leave
#' `vpc_layout` untagged -- as [er_style_vpc_observed_mean_errorbar()]/
#' [er_style_vpc_simulated_mean_errorbar()] and
#' [er_style_vpc_observed_quantile_errorbar()]/
#' [er_style_vpc_simulated_quantile_errorbar()] do, since both pairs
#' adapt their x-position to `plot_by`'s type at build time rather than
#' declaring one family statically -- to skip the check entirely, the
#' same opt-in treatment `layer` gets.
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
#' for labelling. It's read by every `er_plot_add_*()`/`er_vpc_add_*()`/
#' `er_tte_add_*()` function to catch a builder plugged into the wrong
#' layer -- e.g. passing a quantile builder to `er_plot_add_data()`, or an
#' `er_plot()` summary builder to `er_tte_add_summary()` -- with an
#' informative error instead of whatever failure results from that layer's
#' `config` shape not matching what the builder expects. All built-in
#' builders carry this tag. It is a flat namespace checked only by string
#' equality, but every value is grammar-prefixed by convention
#' (`plot_`/`vpc_`/`tte_`) -- e.g. `"plot_model"`/`"plot_summary"` for
#' `er_plot()` vs. `"tte_model"`/`"tte_summary"` for `er_tte()` -- so two
#' grammars whose builders share neither a signature nor a `config` shape
#' can never collide by accident, and the prefix also makes a value's
#' owning grammar legible on sight, including in [er_style_labels()]'s own
#' `layer` column. A custom builder that omits `layer` is never checked:
#' it is opt-in, not a requirement like `layout` is for a data-layer
#' builder.
#'
#' `draw_order` only applies to an overlay-layout data builder (`layout =
#' "overlay"`), and controls whether its geoms are drawn before or after
#' the model/summary/quantile layers when they share the main panel.
#' `"foreground"`, the default for a builder that omits this tag (e.g.
#' `er_style_data_overlay()`), draws the data geoms last, on top of
#' everything else -- appropriate for a sparse layer like individual
#' points, which should never be hidden behind a model ribbon.
#' `"background"` (used by `er_style_data_hex()`) draws the data geoms
#' first, so a builder whose geoms cover the whole panel (leaving no gaps
#' for what's underneath to show through) doesn't bury the model curve or
#' summary annotation. `draw_order` has no effect on a panel-layout data
#' builder (e.g. `er_style_data_boxjitter()`), since those geoms are
#' drawn in their own separate panels, never sharing space with the model/
#' summary/quantile layers.
#'
#' `response_types` and `plot_by_types` are both optional, and -- unlike
#' every other tag above -- are checked against the *data*, not another
#' builder: [er_vpc_add_observed()]/[er_vpc_add_simulated()] each check
#' `style`'s declared `response_types` against `object$response$type`
#' and `plot_by_types` against `object$group$type`, erroring immediately
#' if the object's data isn't one the builder declared support for --
#' e.g. [er_style_vpc_observed_quantile_line()] declares
#' `response_types = c("continuous", "count")` (it needs
#' `config$percentiles`, never computed for a binary response) and
#' `plot_by_types = "continuous"` (it draws a `geom_line()` connecting
#' bins along the numeric midpoint, meaningless for an unordered
#' categorical `plot_by`). This catches an incompatible builder/data
#' pairing at the `er_vpc_add_*()` call site, before any binning or
#' summarising happens, rather than only when the builder itself is
#' finally invoked by `plot()`/`er_vpc_build()`. As with `layer`, both
#' tags are opt-in -- an untagged builder is never checked against
#' either, so a custom builder that doesn't declare them keeps working
#' unchanged (though it's then responsible for guarding against its own
#' incompatible inputs, the way every built-in VPC builder still does
#' internally as a fallback).
#'
#' `marker_source` is also optional and VPC-specific, read by
#' `.clip_vpc_config_to_limits()` (see [er_vpc_theme()]'s `xlim`/`ylim`)
#' to decide which of a VPC observed/simulated builder's two config
#' tables to crop-and-warn against when a marker falls outside the
#' plotted axis limits. A builder that plots `config$summary` (e.g.
#' [er_style_vpc_observed_mean_errorbar()]) should tag
#' `marker_source = "summary"`; one that plots `config$percentiles`
#' (e.g. [er_style_vpc_observed_quantile_line()],
#' [er_style_vpc_observed_quantile_errorbar()]) should tag
#' `marker_source = "percentiles"`. An untagged builder has both tables
#' checked, which is always safe but can produce a spurious warning about
#' a table the builder never actually draws from.
#'
#' `label` is unlike every tag above, in that it isn't purely
#' descriptive: supplying it registers `style` as a side effect, so that
#' the corresponding `_add_*()` function can accept the string in place of
#' `style` itself. It requires `layer` in the same call -- the registry is
#' keyed by `(layer, label)`, not `label` alone, which is what lets two
#' different layers reuse the same label string with no ambiguity (each
#' `_add_*()` function only ever looks inside its own layer's partition).
#' Wired up for every `_add_*()` function in the package -- see
#' [er_style_labels()] for the full list of registered `(layer, label)`
#' pairs.
#'
#' Re-registering the same `(layer, label)` pair with the identical
#' function is always a silent no-op (this is what makes reloading the
#' package, which re-tags every built-in builder, safe). Re-registering it
#' with a *different* function errors by default -- e.g. re-running a
#' script that edits a custom labelled builder's body and re-tags it hits
#' this -- unless `overwrite = TRUE` is passed, which replaces the
#' registration unconditionally.
#'
#' @seealso [er_plot_add_data()], [er_style()], [er_style_vpc()],
#'   [er_style_tte()], [er_style_labels()]
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
#'   layer = "plot_data"
#' )
#'
#' @export
er_style_tag <- function(style, layout = NULL, vpc_layout = NULL, fill_role = NULL, y_role = NULL, layer = NULL,
                          draw_order = NULL, response_types = NULL, plot_by_types = NULL, marker_source = NULL,
                          label = NULL, overwrite = FALSE) {
  if (!is.function(style)) rlang::abort("`style` must be a function")
  if (!is.logical(overwrite) || length(overwrite) != 1 || is.na(overwrite)) {
    rlang::abort("`overwrite` must be `TRUE` or `FALSE`.")
  }
  if (!is.null(label) && is.null(layer)) {
    rlang::abort("`label` requires `layer` to also be set in the same call.")
  }
  if (overwrite && is.null(label)) {
    rlang::abort("`overwrite` requires `label` to also be set in the same call.")
  }

  if (!is.null(layout)) {
    layout <- match.arg(layout, c("overlay", "panel"))
    attr(style, "er_style_layout") <- layout
  }
  if (!is.null(vpc_layout)) {
    vpc_layout <- match.arg(vpc_layout, c("categorical", "continuous"))
    attr(style, "er_style_vpc_layout") <- vpc_layout
  }
  if (!is.null(fill_role)) {
    attr(style, "er_style_fill_role") <- fill_role
  }
  if (!is.null(y_role)) {
    attr(style, "er_style_y_role") <- y_role
  }
  if (!is.null(layer)) {
    layer <- match.arg(layer, c(
      "plot_model", "plot_summary", "plot_quantile", "plot_data", "plot_group",
      "vpc_observed", "vpc_simulated",
      "tte_curve", "tte_censor", "tte_risktable", "tte_model", "tte_summary"
    ))
    attr(style, "er_style_layer") <- layer
  }
  if (!is.null(draw_order)) {
    draw_order <- match.arg(draw_order, c("foreground", "background"))
    attr(style, "er_style_draw_order") <- draw_order
  }
  if (!is.null(response_types)) {
    response_types <- match.arg(response_types, c("binary", "continuous", "count"), several.ok = TRUE)
    attr(style, "er_style_response_types") <- response_types
  }
  if (!is.null(plot_by_types)) {
    plot_by_types <- match.arg(plot_by_types, c("continuous", "discrete"), several.ok = TRUE)
    attr(style, "er_style_plot_by_types") <- plot_by_types
  }
  if (!is.null(marker_source)) {
    marker_source <- match.arg(marker_source, c("summary", "percentiles"))
    attr(style, "er_style_vpc_marker_source") <- marker_source
  }
  if (!is.null(label)) {
    attr(style, "er_style_label") <- label
    .register_style_label(layer, label, style, overwrite = overwrite)
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
.style_vpc_layout <- function(style) {
  attr(style, "er_style_vpc_layout")
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
.style_draw_order <- function(style) {
  draw_order <- attr(style, "er_style_draw_order")
  if (is.null(draw_order)) "foreground" else draw_order
}

#' @noRd
.style_response_types <- function(style) {
  attr(style, "er_style_response_types")
}

#' @noRd
.style_plot_by_types <- function(style) {
  attr(style, "er_style_plot_by_types")
}

#' @noRd
.style_vpc_marker_source <- function(style) {
  attr(style, "er_style_vpc_marker_source")
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

#' @noRd
.check_style_response_type <- function(style, response_type, arg = "style") {
  declared <- .style_response_types(style)
  if (is.null(declared) || response_type %in% declared) return(invisible(NULL))

  rlang::abort(c(
    paste0("`", arg, "` does not support a \"", response_type, "\" response."),
    "i" = paste0("It only supports: ", paste(paste0("\"", declared, "\""), collapse = ", "), ".")
  ))
}

#' @noRd
.check_style_plot_by_type <- function(style, group_type, arg = "style") {
  declared <- .style_plot_by_types(style)
  if (is.null(declared) || group_type %in% declared) return(invisible(NULL))

  rlang::abort(c(
    paste0("`", arg, "` does not support a \"", group_type, "\" `plot_by` variable."),
    "i" = paste0("It only supports: ", paste(paste0("\"", declared, "\""), collapse = ", "), ".")
  ))
}

#' @noRd
.check_vpc_layout_match <- function(observed_style, simulated_style) {
  observed_layout <- .style_vpc_layout(observed_style)
  simulated_layout <- .style_vpc_layout(simulated_style)
  if (is.null(observed_layout) || is.null(simulated_layout) || identical(observed_layout, simulated_layout)) {
    return(invisible(NULL))
  }

  rlang::abort(c(
    paste0(
      "The observed layer's builder is tagged vpc_layout = \"", observed_layout,
      "\", but the simulated layer's builder is tagged vpc_layout = \"", simulated_layout, "\"."
    ),
    "i" = "A \"categorical\" builder plots at discrete bin locations; a \"continuous\" builder plots at each bin's numeric midpoint -- pairing them plots the two layers at inconsistent x-positions.",
    "i" = "Use a layout-matched pair (e.g. `er_style_vpc_observed_quantile_line()` + `er_style_vpc_simulated_quantile_ribbon()`).",
    "i" = "Or leave `vpc_layout` untagged, like `er_style_vpc_observed_mean_errorbar()`/`er_style_vpc_simulated_mean_errorbar()` and `er_style_vpc_observed_quantile_errorbar()`/`er_style_vpc_simulated_quantile_errorbar()` do, to skip this check entirely."
  ))
}

