
#' Adjust theme/labels for an `er_vpc` object
#'
#' Set axis/legend labels, plot titles/captions, axis limits, theme
#' objects, and formatters for a VPC. This does not change which variable
#' is mapped to which aesthetic -- that's the builder's job via `style`
#' (see [er_style()]).
#'
#' @details
#' Every argument defaults to `NULL`, meaning "leave whatever was set
#' before unchanged". This allows repeated calls to `er_vpc_theme()` to
#' update only the supplied fields, like [ggplot2::theme()]. There is no
#' implicit way to reset a field to the [er_vpc()] default.
#'
#' `xlab` labels `plot_by` (stored on `object$group$label`), not
#' `exposure` -- `plot_by` drives the VPC's actual x-axis, and the two
#' only coincide when the caller didn't override `plot_by` in [er_vpc()].
#'
#' `theme_extra` defaults to a panel border plus `legend.position =
#' "bottom"`. Supplying a new value fully replaces this default rather
#' than merging with it, so re-include the border/legend-position
#' settings too if you want to keep them alongside your own additions.
#'
#' Unlike [er_plot_theme()], there is no `color_discrete`/`fill_discrete`
#' argument here: the observed-vs-simulated colour/fill distinction uses
#' a fixed, shared scale (see the "Gotchas" section of `AGENTS.md`) to
#' keep the two aligned across builders that mix colour and fill for the
#' same idea, and swapping it out is not yet supported. Adding `+
#' ggplot2::scale_colour_manual(...)`/`+ ggplot2::scale_fill_manual(...)`
#' to the built/returned ggplot2 object remains the escape hatch for
#' this, and for any other tweak not covered by this function's
#' arguments (e.g. `draw_key`, which isn't wired up for any built-in VPC
#' builder).
#'
#' @param object Partially constructed VPC (has S3 class `er_vpc`).
#' @param xlab Label for the VPC's x-axis (single string) -- see
#'   "Details" for why this labels `plot_by`, not `exposure`.
#' @param ylab Response axis label (single string).
#' @param strata_lab Facet strip label prefix (single string), e.g. the
#'   `"Sex"` in a `"Sex: Female"` strip. Errors if `stratify_by` wasn't
#'   set in [er_vpc()] -- there's no facet strip to relabel.
#' @param title,subtitle,caption Plot-level annotation text (single
#'   strings).
#' @param xlim,ylim Axis limits (length-2, increasing numeric vectors),
#'   applied via `ggplot2::coord_cartesian(clip = "off")`.
#' @param theme_base A ggplot2 theme object (e.g. [ggplot2::theme_minimal()])
#'   -- the swappable overall visual theme, defaulting to
#'   [ggplot2::theme_bw()].
#' @param theme_extra A ggplot2 theme object (e.g. from [ggplot2::theme()])
#'   with additional theme tweaks layered on top of `theme_base`. See
#'   "Details" for its default and replacement semantics.
#' @param format_percent,format_number Formatter functions (typically
#'   from `scales::label_*()`), used to format the rate/mean displayed
#'   in the observed/simulated summaries for a binary response
#'   (`format_percent`) or a continuous/count response (`format_number`).
#'
#' @returns The input `object`, with the requested theme fields updated.
#'
#' @examples
#' if (requireNamespace("erglm", quietly = TRUE)) {
#'   library(erglm)
#'   mod <- erglm_model(ae1 ~ aucss, erglm_data, family = binomial())
#'
#'   erglm_data |>
#'     er_vpc(aucss, ae1) |>
#'     er_vpc_add_observed() |>
#'     er_vpc_add_simulated(model = mod, seed = 1234) |>
#'     er_vpc_theme(
#'       xlab = "AUC at steady state",
#'       ylab = "Probability of event",
#'       title = "Visual predictive check"
#'     ) |>
#'     plot()
#' }
#'
#' @seealso [er_vpc()], [er_style()]
#'
#' @export
er_vpc_theme <- function(object,
                          xlab = NULL, ylab = NULL, strata_lab = NULL,
                          title = NULL, subtitle = NULL, caption = NULL,
                          xlim = NULL, ylim = NULL,
                          theme_base = NULL, theme_extra = NULL,
                          format_percent = NULL, format_number = NULL) {

  if (!inherits(object, "er_vpc")) rlang::abort("`object` must be an er_vpc object.")

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
  .check_theme_function(format_percent, "format_percent")
  .check_theme_function(format_number, "format_number")

  if (!is.null(strata_lab) && is.null(object$strata$var)) {
    rlang::abort(c(
      "`strata_lab` was supplied, but no `stratify_by` was set in `er_vpc()`.",
      "i" = "There is no facet strip to relabel."
    ))
  }

  # `plot_by` (`object$group$label`), not `exposure`, drives the VPC's
  # x-axis -- see the "never reach for exposure$label" gotcha in
  # AGENTS.md.
  if (!is.null(xlab)) object$group$label <- xlab
  if (!is.null(ylab)) object$response$label <- ylab
  if (!is.null(strata_lab)) object$strata$label <- strata_lab

  if (!is.null(title)) object$theme$title <- title
  if (!is.null(subtitle)) object$theme$subtitle <- subtitle
  if (!is.null(caption)) object$theme$caption <- caption

  if (!is.null(xlim)) object$theme$xlim <- xlim
  if (!is.null(ylim)) object$theme$ylim <- ylim

  if (!is.null(theme_base)) object$theme$theme_base <- theme_base
  if (!is.null(theme_extra)) object$theme$theme_extra <- theme_extra

  if (!is.null(format_percent)) object$theme$format_percent <- format_percent
  if (!is.null(format_number)) object$theme$format_number <- format_number

  return(object)
}
