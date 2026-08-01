#' Observed-layer builders for VPC plots
#'
#' Builder functions for the `observed` layer ([er_vpc_add_observed()]),
#' drawing the observed side of a visual predictive check as a dodged
#' point/interval per bin (the default) or as a continuous-x line of
#' empirical percentiles.
#'
#' @include er-plot-style.R
#' @param data The original data frame.
#' @param config Configuration for the observed layer.
#' @param exposure Exposure variable.
#' @param response Response variable.
#' @param theme Theme components.
#' @param point_size Point size for both builders.
#' @param errorbar_width Width of `er_style_vpc_observed_pointrange()`'s error bars.
#' @param ... Additional named arguments forwarded from
#'   [er_vpc_add_observed()]'s own `...`.
#'
#' @details `er_style_vpc_observed_pointrange()` plots `config$summary`'s
#' rate/mean + confidence interval at each bin's categorical (or
#' quantile-bin) label, dodged alongside the simulated layer's own point +
#' interval. `er_style_vpc_observed_line()` instead plots
#' `config$percentiles` -- one line per requested percentile -- at each
#' bin's numeric midpoint on the exposure scale, for pairing with
#' [er_style_vpc_simulated_ribbon()]. `config$percentiles` is only
#' computed for a continuous/count response binned on a numeric
#' `group_by` (see [er_vpc_add_observed()]'s `probs` argument); calling
#' `er_style_vpc_observed_line()` without it errors.
#'
#' Both builders map a constant `color = "Observed"`, so ggplot2 merges
#' their legend entry with whatever the paired simulated-layer builder
#' maps for `"Simulated"` into a single combined legend.
#'
#' @returns A list of geoms; see [er_style()].
#'
#' @name er_style_vpc_observed
#' @seealso [er_style()], [er_style_vpc_simulated()]
NULL

#' @rdname er_style_vpc_observed
#' @export
er_style_vpc_observed_pointrange <- function(data, config, exposure, response, theme,
                                              point_size = 2, errorbar_width = 0.2, ...) {
  list(
    ggplot2::geom_errorbar(
      data = config$summary,
      mapping = ggplot2::aes(x = .vpc_bin, ymin = ci_lower, ymax = ci_upper, color = "Observed"),
      position = ggplot2::position_dodge2(width = .2),
      width = errorbar_width,
      inherit.aes = FALSE
    ),
    ggplot2::geom_point(
      data = config$summary,
      mapping = ggplot2::aes(x = .vpc_bin, y = y_mid, color = "Observed"),
      position = ggplot2::position_dodge2(width = .2),
      size = point_size,
      inherit.aes = FALSE
    )
  )
}
er_style_vpc_observed_pointrange <- er_style_tag(er_style_vpc_observed_pointrange, layer = "observed")


#' @rdname er_style_vpc_observed
#' @export
er_style_vpc_observed_line <- function(data, config, exposure, response, theme,
                                        point_size = 1.5, ...) {
  if (is.null(config$percentiles)) {
    rlang::abort(c(
      "`er_style_vpc_observed_line()` requires `config$percentiles`, which is not available here.",
      "i" = "Percentiles are only computed for a continuous/count response binned on a numeric `group_by` -- see `er_vpc_add_observed()`.",
      "i" = "Use `er_style_vpc_observed_pointrange()` instead for a binary response or a categorical `group_by`."
    ))
  }
  list(
    ggplot2::geom_line(
      data = config$percentiles,
      mapping = ggplot2::aes(x = x_mid, y = y, group = factor(prob), color = "Observed"),
      inherit.aes = FALSE
    ),
    ggplot2::geom_point(
      data = config$percentiles,
      mapping = ggplot2::aes(x = x_mid, y = y, color = "Observed"),
      size = point_size,
      inherit.aes = FALSE
    )
  )
}
er_style_vpc_observed_line <- er_style_tag(er_style_vpc_observed_line, layer = "observed")
