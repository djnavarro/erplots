#' Observed-layer builders for VPC plots
#'
#' Builder functions for the `observed` layer ([er_vpc_add_observed()]),
#' drawing the observed side of a visual predictive check as a
#' mean/rate + confidence interval per bin (the default, adaptive to
#' `plot_by`'s type), a dodged point/interval per categorical (or
#' quantile-bin) bin label, a continuous-x line of empirical
#' percentiles, or a dodged point/interval per bin *and* per requested
#' percentile.
#'
#' @include er-plot-style.R
#' @param data The original data frame.
#' @param config Configuration for the observed layer.
#' @param exposure Exposure variable.
#' @param response Response variable.
#' @param theme Theme components.
#' @param point_size Point size for all four point/interval builders.
#' @param errorbar_width Width of `er_style_vpc_observed_pointrange()`'s
#'   error bars, of `er_style_vpc_observed_mean_errorbar()`'s when
#'   `plot_by` is categorical, and of
#'   `er_style_vpc_observed_quantile_errorbar()`'s.
#' @param errorbar_width_continuous Width (as a fraction of the exposure
#'   range) of `er_style_vpc_observed_mean_errorbar()`'s error bars when
#'   `plot_by` is numeric.
#' @param dodge_width Dodge width separating each bin's requested
#'   percentiles in `er_style_vpc_observed_quantile_errorbar()`.
#' @param ... Additional named arguments forwarded from
#'   [er_vpc_add_observed()]'s own `...`.
#'
#' @details `er_style_vpc_observed_mean_errorbar()` (the default) plots
#' `config$summary`'s rate/mean + confidence interval, adapting its
#' x-position to `plot_by`'s type (`config$is_numeric_group`): equally
#' spaced at each bin's categorical (or quantile-bin) label when
#' `plot_by` is categorical (like `er_style_vpc_observed_pointrange()`),
#' or at each bin's numeric median (`x_median`, from `config$summary`)
#' on the exposure scale when `plot_by` is numeric (like
#' `er_style_vpc_observed_pointrange_continuous()`, which uses the mean
#' instead). Because it adapts its x-position family at build time
#' rather than declaring one statically, it carries no `layout` tag --
#' pair it with [er_style_vpc_simulated_mean_errorbar()], which mirrors
#' the same adaptive logic.
#'
#' `er_style_vpc_observed_pointrange()` plots `config$summary`'s
#' rate/mean + confidence interval at each bin's categorical (or
#' quantile-bin) label, dodged alongside the simulated layer's own point +
#' interval. `er_style_vpc_observed_quantile_line()` instead plots
#' `config$percentiles` -- one line per requested percentile -- at each
#' bin's numeric midpoint on the exposure scale, for pairing with
#' [er_style_vpc_simulated_quantile_ribbon()]. `config$percentiles` is only
#' computed for a continuous/count response (see [er_vpc()]'s `probs`
#' argument); calling `er_style_vpc_observed_quantile_line()` without it errors.
#' `er_style_vpc_observed_pointrange_continuous()` plots the same
#' rate/mean + confidence interval as `er_style_vpc_observed_pointrange()`,
#' at the bin's numeric midpoint like `er_style_vpc_observed_quantile_line()` does
#' -- for pairing a pointrange/errorbar idiom with a `"continuous"`-layout
#' simulated builder (e.g. [er_style_vpc_simulated_quantile_ribbon()]) without a
#' layout mismatch. It always plots the mean (from `config$summary`, so
#' it works for a binary response too); when `config$percentiles` is
#' also available (continuous/count response), it
#' additionally plots a dashed pointrange/errorbar for each requested
#' percentile (see [er_vpc()]'s `probs` argument), with a
#' confidence interval from [ci_quantile()] -- the observed-side analogue
#' of the across-replicate interval `er_style_vpc_simulated_quantile_ribbon()`
#' shows as a band.
#'
#' `er_style_vpc_observed_quantile_errorbar()` plots `config$percentiles`
#' -- a point + confidence interval (via [ci_quantile()]) for each
#' requested percentile -- dodged at each bin's categorical (or
#' quantile-bin) label, for pairing with
#' [er_style_vpc_simulated_quantile_errorbar()]. Unlike
#' `er_style_vpc_observed_quantile_line()`/`er_style_vpc_simulated_quantile_ribbon()`, it
#' supports both a numeric and a categorical `plot_by` (it always plots
#' at the discrete `.vpc_bin` label rather than a continuous numeric
#' midpoint); like them, it requires a continuous/count response (a
#' binary response's distribution is already fully described by its
#' rate) and errors informatively without `config$percentiles`.
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
er_style_vpc_observed_pointrange <- er_style_tag(
  er_style_vpc_observed_pointrange,
  layer = "observed", layout = "categorical",
  response_types = c("binary", "continuous", "count"),
  plot_by_types = c("continuous", "discrete")
)


#' @rdname er_style_vpc_observed
#' @export
er_style_vpc_observed_pointrange_continuous <- function(data, config, exposure, response, theme,
                                                          point_size = 2, errorbar_width = 0.025, ...) {
  if (!isTRUE(config$is_numeric_group)) {
    rlang::abort(c(
      "`er_style_vpc_observed_pointrange_continuous()` requires a numeric `plot_by`, so that each bin has a numeric midpoint to plot at.",
      "i" = "Use `er_style_vpc_observed_pointrange()` instead for a categorical `plot_by`."
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
  layer = "observed", layout = "continuous",
  response_types = c("binary", "continuous", "count"),
  plot_by_types = "continuous"
)


#' @rdname er_style_vpc_observed
#' @export
er_style_vpc_observed_quantile_line <- function(data, config, exposure, response, theme,
                                        point_size = 1.5, ...) {
  if (is.null(config$percentiles)) {
    rlang::abort(c(
      "`er_style_vpc_observed_quantile_line()` requires `config$percentiles`, which is not available here.",
      "i" = "Percentiles are only computed for a continuous/count response binned on a numeric `plot_by` -- see `er_vpc_add_observed()`.",
      "i" = "Use `er_style_vpc_observed_pointrange()` instead for a binary response or a categorical `plot_by`."
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
er_style_vpc_observed_quantile_line <- er_style_tag(
  er_style_vpc_observed_quantile_line,
  layer = "observed", layout = "continuous",
  response_types = c("continuous", "count"),
  plot_by_types = "continuous"
)


#' @rdname er_style_vpc_observed
#' @export
er_style_vpc_observed_quantile_errorbar <- function(data, config, exposure, response, theme,
                                                     point_size = 1.5, errorbar_width = 0.15,
                                                     dodge_width = 0.5, ...) {
  if (is.null(config$percentiles)) {
    rlang::abort(c(
      "`er_style_vpc_observed_quantile_errorbar()` requires `config$percentiles`, which is not available here.",
      "i" = "Percentiles are only computed for a continuous/count response -- see `er_vpc_add_observed()`.",
      "i" = "Use `er_style_vpc_observed_pointrange()` or `er_style_vpc_observed_mean_errorbar()` instead for a binary response."
    ))
  }
  list(
    ggplot2::geom_errorbar(
      data = config$percentiles,
      mapping = ggplot2::aes(x = .vpc_bin, ymin = ci_lower, ymax = ci_upper, group = factor(prob), color = "Observed"),
      position = ggplot2::position_dodge2(width = dodge_width),
      width = errorbar_width,
      inherit.aes = FALSE
    ),
    ggplot2::geom_point(
      data = config$percentiles,
      mapping = ggplot2::aes(x = .vpc_bin, y = y, group = factor(prob), color = "Observed"),
      position = ggplot2::position_dodge2(width = dodge_width),
      size = point_size,
      inherit.aes = FALSE
    )
  )
}
er_style_vpc_observed_quantile_errorbar <- er_style_tag(
  er_style_vpc_observed_quantile_errorbar,
  layer = "observed", layout = "categorical",
  response_types = c("continuous", "count"),
  plot_by_types = c("continuous", "discrete")
)


#' @rdname er_style_vpc_observed
#' @export
er_style_vpc_observed_mean_errorbar <- function(data, config, exposure, response, theme,
                                                 point_size = 2, errorbar_width = 0.2,
                                                 errorbar_width_continuous = 0.025, ...) {
  if (config$is_numeric_group) {
    width <- errorbar_width_continuous * (exposure$limits[2] - exposure$limits[1])
    list(
      ggplot2::geom_errorbar(
        data = config$summary,
        mapping = ggplot2::aes(x = x_median, ymin = ci_lower, ymax = ci_upper, color = "Observed"),
        width = width,
        inherit.aes = FALSE
      ),
      ggplot2::geom_point(
        data = config$summary,
        mapping = ggplot2::aes(x = x_median, y = y_mid, color = "Observed"),
        size = point_size,
        inherit.aes = FALSE
      )
    )
  } else {
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
}
er_style_vpc_observed_mean_errorbar <- er_style_tag(
  er_style_vpc_observed_mean_errorbar,
  layer = "observed",
  response_types = c("binary", "continuous", "count"),
  plot_by_types = c("continuous", "discrete")
)
