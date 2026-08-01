#' Simulated-layer builders for VPC plots
#'
#' Builder functions for the `simulated` layer ([er_vpc_add_simulated()]),
#' drawing the simulated side of a visual predictive check as a dodged
#' point/interval per bin (the default) or as continuous-x percentile
#' bands.
#'
#' @include er-plot-style.R
#' @param data The original data frame.
#' @param config Configuration for the simulated layer.
#' @param exposure Exposure variable.
#' @param response Response variable.
#' @param theme Theme components.
#' @param point_size Point size for `er_style_vpc_simulated_errorbar()`.
#' @param errorbar_width Width of `er_style_vpc_simulated_errorbar()`'s error bars.
#' @param ribbon_alpha Fill transparency for `er_style_vpc_simulated_ribbon()`'s bands.
#' @param ... Additional named arguments forwarded from
#'   [er_vpc_add_simulated()]'s own `...`.
#'
#' @details `er_style_vpc_simulated_errorbar()` plots `config$summary`'s
#' mean + percentile interval (of the mean, across replicates) at each
#' bin's categorical (or quantile-bin) label, dodged alongside the
#' observed layer's own point + interval.
#' `er_style_vpc_simulated_ribbon()` instead plots `config$percentiles`
#' -- one shaded band (median line + interval) per requested percentile
#' -- at each bin's numeric midpoint on the exposure scale, for pairing
#' with [er_style_vpc_observed_line()]. `config$percentiles` is only
#' computed for a continuous/count response binned on a numeric
#' `group_by` (see [er_vpc_add_observed()]'s `probs` argument, which
#' should match what was passed to [er_vpc_add_simulated()]); calling
#' `er_style_vpc_simulated_ribbon()` without it errors.
#'
#' `er_style_vpc_simulated_errorbar()` maps a constant `color =
#' "Simulated"`; `er_style_vpc_simulated_ribbon()` maps a constant `fill
#' = "Simulated"`. ggplot2 merges either into the paired observed
#' builder's own `"Observed"` legend entry (same aesthetic) into one
#' combined legend; the ribbon's `fill` legend is separate from the
#' point/errorbar builders' `color` legend.
#'
#' @returns A list of geoms; see [er_style()].
#'
#' @name er_style_vpc_simulated
#' @seealso [er_style()], [er_style_vpc_observed()]
NULL

#' @rdname er_style_vpc_simulated
#' @export
er_style_vpc_simulated_errorbar <- function(data, config, exposure, response, theme,
                                             point_size = 2, errorbar_width = 0.2, ...) {
  list(
    ggplot2::geom_errorbar(
      data = config$summary,
      mapping = ggplot2::aes(x = .vpc_bin, ymin = ci_lower, ymax = ci_upper, color = "Simulated"),
      position = ggplot2::position_dodge2(width = .2),
      width = errorbar_width,
      inherit.aes = FALSE
    ),
    ggplot2::geom_point(
      data = config$summary,
      mapping = ggplot2::aes(x = .vpc_bin, y = y_mid, color = "Simulated"),
      position = ggplot2::position_dodge2(width = .2),
      size = point_size,
      inherit.aes = FALSE
    )
  )
}
er_style_vpc_simulated_errorbar <- er_style_tag(er_style_vpc_simulated_errorbar, layer = "simulated")


#' @rdname er_style_vpc_simulated
#' @export
er_style_vpc_simulated_ribbon <- function(data, config, exposure, response, theme,
                                           ribbon_alpha = 0.3, ...) {
  if (is.null(config$percentiles)) {
    rlang::abort(c(
      "`er_style_vpc_simulated_ribbon()` requires `config$percentiles`, which is not available here.",
      "i" = "Percentiles are only computed for a continuous/count response binned on a numeric `group_by` -- see `er_vpc_add_observed()`/`er_vpc_add_simulated()`.",
      "i" = "Use `er_style_vpc_simulated_errorbar()` instead for a binary response or a categorical `group_by`."
    ))
  }
  list(
    ggplot2::geom_ribbon(
      data = config$percentiles,
      mapping = ggplot2::aes(x = x_mid, ymin = ci_lower, ymax = ci_upper, group = factor(prob), fill = "Simulated"),
      alpha = ribbon_alpha,
      inherit.aes = FALSE
    ),
    ggplot2::geom_line(
      data = config$percentiles,
      mapping = ggplot2::aes(x = x_mid, y = y_mid, group = factor(prob)),
      linetype = "dashed",
      colour = "grey30",
      inherit.aes = FALSE
    ),
    ggplot2::labs(fill = "Source")
  )
}
er_style_vpc_simulated_ribbon <- er_style_tag(er_style_vpc_simulated_ribbon, layer = "simulated")
