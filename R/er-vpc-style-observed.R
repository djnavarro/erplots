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
#' `er_style_vpc_observed_pointrange_continuous()` plots the same
#' rate/mean + confidence interval as `er_style_vpc_observed_pointrange()`,
#' at the bin's numeric midpoint like `er_style_vpc_observed_line()` does
#' -- for pairing a pointrange/errorbar idiom with a `"continuous"`-layout
#' simulated builder (e.g. [er_style_vpc_simulated_ribbon()]) without a
#' layout mismatch. It always plots the mean (from `config$summary`, so
#' it works for a binary response too); when `config$percentiles` is
#' also available (continuous/count response, numeric `group_by`), it
#' additionally plots a dashed pointrange/errorbar for each requested
#' percentile (see [er_vpc_add_observed()]'s `probs` argument), with a
#' confidence interval from [ci_quantile()] -- the observed-side analogue
#' of the across-replicate interval `er_style_vpc_simulated_ribbon()`
#' shows as a band.
#'
#' Each builder maps a constant `color = "Observed"`, so ggplot2 merges
#' its legend entry with whatever the paired simulated-layer builder
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
er_style_vpc_observed_pointrange <- er_style_tag(er_style_vpc_observed_pointrange, layer = "observed", layout = "categorical")


#' @rdname er_style_vpc_observed
#' @export
er_style_vpc_observed_pointrange_continuous <- function(data, config, exposure, response, theme,
                                                          point_size = 2, errorbar_width = 0.025, ...) {
  if (!isTRUE(config$is_numeric_group)) {
    rlang::abort(c(
      "`er_style_vpc_observed_pointrange_continuous()` requires a numeric `group_by`, so that each bin has a numeric midpoint to plot at.",
      "i" = "Use `er_style_vpc_observed_pointrange()` instead for a categorical `group_by`."
    ))
  }
  width <- errorbar_width * (exposure$limits[2] - exposure$limits[1])
  geoms <- list(
    ggplot2::geom_errorbar(
      data = config$summary,
      mapping = ggplot2::aes(x = x_mid, ymin = ci_lower, ymax = ci_upper, color = "Observed"),
      width = width,
      inherit.aes = FALSE
    ),
    ggplot2::geom_point(
      data = config$summary,
      mapping = ggplot2::aes(x = x_mid, y = y_mid, color = "Observed"),
      size = point_size,
      inherit.aes = FALSE
    )
  )
  if (!is.null(config$percentiles)) {
    geoms <- c(geoms, list(
      ggplot2::geom_errorbar(
        data = config$percentiles,
        mapping = ggplot2::aes(x = x_mid, ymin = ci_lower, ymax = ci_upper, color = "Observed"),
        linetype = "dashed",
        width = width,
        inherit.aes = FALSE
      ),
      ggplot2::geom_point(
        data = config$percentiles,
        mapping = ggplot2::aes(x = x_mid, y = y, color = "Observed"),
        size = point_size * 0.75,
        inherit.aes = FALSE
      )
    ))
  }
  geoms
}
er_style_vpc_observed_pointrange_continuous <- er_style_tag(
  er_style_vpc_observed_pointrange_continuous,
  layer = "observed", layout = "continuous"
)


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
er_style_vpc_observed_line <- er_style_tag(er_style_vpc_observed_line, layer = "observed", layout = "continuous")
