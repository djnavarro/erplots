#' Simulated-layer builders for VPC plots
#'
#' Builder functions for the `simulated` layer ([er_vpc_add_simulated()]),
#' drawing the simulated side of a visual predictive check as a
#' mean + percentile interval per bin (the default, adaptive to
#' `plot_by`'s type), continuous-x percentile bands, or a
#' point/interval per bin *and* per requested percentile.
#'
#' @include er-plot-style.R
#' @param data The original data frame.
#' @param config Configuration for the simulated layer.
#' @param exposure Exposure variable.
#' @param response Response variable.
#' @param theme Theme components.
#' @param point_size Point size for both point/interval builders.
#' @param errorbar_width Width of `er_style_vpc_simulated_mean_errorbar()`'s
#'   error bars when `plot_by` is categorical, and of
#'   `er_style_vpc_simulated_quantile_errorbar()`'s.
#' @param errorbar_width_continuous Width (as a fraction of the exposure
#'   range) of `er_style_vpc_simulated_mean_errorbar()`'s error bars when
#'   `plot_by` is numeric.
#' @param ribbon_alpha Fill transparency for `er_style_vpc_simulated_quantile_ribbon()`'s bands.
#' @param ... Additional named arguments forwarded from
#'   [er_vpc_add_simulated()]'s own `...`.
#'
#' @details `er_style_vpc_simulated_mean_errorbar()` (the default) plots
#' `config$summary`'s mean + percentile interval (of the mean, across
#' replicates), adapting its x-position to `plot_by`'s type
#' (`config$is_numeric_group`): equally spaced at each bin's categorical
#' (or quantile-bin) label when `plot_by` is categorical, or at each
#' bin's numeric median (`x_median`, from `config$summary`) on the
#' exposure scale when `plot_by` is numeric. Because it adapts its
#' x-position family at build time rather than declaring one statically,
#' it carries no `layout` tag -- pair it with
#' [er_style_vpc_observed_mean_errorbar()], which mirrors the same
#' adaptive logic.
#'
#' `er_style_vpc_simulated_quantile_ribbon()` plots `config$percentiles`
#' -- one shaded band (median line + interval) per requested percentile
#' -- at each bin's numeric midpoint on the exposure scale, for pairing
#' with [er_style_vpc_observed_quantile_line()]. `config$percentiles` is
#' only computed for a continuous/count response (see [er_vpc()]'s
#' `probs` argument); calling `er_style_vpc_simulated_quantile_ribbon()`
#' without it errors.
#'
#' `er_style_vpc_simulated_quantile_errorbar()` plots `config$percentiles`
#' -- a point + across-replicate percentile interval for each requested
#' percentile -- at each bin's categorical (or quantile-bin) label, for
#' pairing with [er_style_vpc_observed_quantile_errorbar()]. Like that
#' builder, it supports both a numeric and a categorical `plot_by` and
#' requires a continuous/count response, erroring informatively without
#' `config$percentiles`. As with the observed-layer counterpart, when
#' more than one percentile is requested they are currently all plotted
#' at the same `.vpc_bin` x-position rather than dodged apart.
#'
#' `er_style_vpc_simulated_mean_errorbar()`/`er_style_vpc_simulated_quantile_errorbar()`
#' map a constant `color = "Simulated"`; `er_style_vpc_simulated_quantile_ribbon()`
#' maps a constant `fill = "Simulated"`. ggplot2 merges either into the
#' paired observed builder's own `"Observed"` legend entry (same
#' aesthetic) into one combined legend; the ribbon's `fill` legend is
#' separate from the point/errorbar builders' `color` legend.
#'
#' @returns A list of geoms; see [er_style()].
#'
#' @name er_style_vpc_simulated
#' @seealso [er_style()], [er_style_vpc_observed()]
NULL

#' @rdname er_style_vpc_simulated
#' @export
er_style_vpc_simulated_quantile_ribbon <- function(data, config, exposure, response, theme,
                                           ribbon_alpha = 0.3, ...) {
  if (is.null(config$percentiles)) {
    rlang::abort(c(
      "`er_style_vpc_simulated_quantile_ribbon()` requires `config$percentiles`, which is not available here.",
      "i" = "Percentiles are only computed for a continuous/count response binned on a numeric `plot_by` -- see `er_vpc_add_observed()`/`er_vpc_add_simulated()`.",
      "i" = "Use `er_style_vpc_simulated_mean_errorbar()` instead for a binary response or a categorical `plot_by`."
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
er_style_vpc_simulated_quantile_ribbon <- er_style_tag(
  er_style_vpc_simulated_quantile_ribbon,
  layer = "simulated", layout = "continuous",
  response_types = c("continuous", "count"),
  plot_by_types = "continuous"
)


#' @rdname er_style_vpc_simulated
#' @export
er_style_vpc_simulated_quantile_errorbar <- function(data, config, exposure, response, theme,
                                                      point_size = 1.5, errorbar_width = 0.15, ...) {
  if (is.null(config$percentiles)) {
    rlang::abort(c(
      "`er_style_vpc_simulated_quantile_errorbar()` requires `config$percentiles`, which is not available here.",
      "i" = "Percentiles are only computed for a continuous/count response -- see `er_vpc_add_observed()`/`er_vpc_add_simulated()`.",
      "i" = "Use `er_style_vpc_simulated_mean_errorbar()` instead for a binary response."
    ))
  }
  list(
    ggplot2::geom_errorbar(
      data = config$percentiles,
      mapping = ggplot2::aes(x = .vpc_bin, ymin = ci_lower, ymax = ci_upper, group = factor(prob), color = "Simulated"),
      width = errorbar_width,
      inherit.aes = FALSE
    ),
    ggplot2::geom_point(
      data = config$percentiles,
      mapping = ggplot2::aes(x = .vpc_bin, y = y_mid, group = factor(prob), color = "Simulated"),
      size = point_size,
      inherit.aes = FALSE
    )
  )
}
er_style_vpc_simulated_quantile_errorbar <- er_style_tag(
  er_style_vpc_simulated_quantile_errorbar,
  layer = "simulated", layout = "categorical",
  response_types = c("continuous", "count"),
  plot_by_types = c("continuous", "discrete")
)


#' @rdname er_style_vpc_simulated
#' @export
er_style_vpc_simulated_mean_errorbar <- function(data, config, exposure, response, theme,
                                                  point_size = 2, errorbar_width = 0.2,
                                                  errorbar_width_continuous = 0.025, ...) {
  if (config$is_numeric_group) {
    width <- errorbar_width_continuous * (exposure$limits[2] - exposure$limits[1])
    list(
      ggplot2::geom_errorbar(
        data = config$summary,
        mapping = ggplot2::aes(x = x_median, ymin = ci_lower, ymax = ci_upper, color = "Simulated"),
        width = width,
        inherit.aes = FALSE
      ),
      ggplot2::geom_point(
        data = config$summary,
        mapping = ggplot2::aes(x = x_median, y = y_mid, color = "Simulated"),
        size = point_size,
        inherit.aes = FALSE
      )
    )
  } else {
    list(
      ggplot2::geom_errorbar(
        data = config$summary,
        mapping = ggplot2::aes(x = .vpc_bin, ymin = ci_lower, ymax = ci_upper, color = "Simulated"),
        width = errorbar_width,
        inherit.aes = FALSE
      ),
      ggplot2::geom_point(
        data = config$summary,
        mapping = ggplot2::aes(x = .vpc_bin, y = y_mid, color = "Simulated"),
        size = point_size,
        inherit.aes = FALSE
      )
    )
  }
}
er_style_vpc_simulated_mean_errorbar <- er_style_tag(
  er_style_vpc_simulated_mean_errorbar,
  layer = "simulated",
  response_types = c("binary", "continuous", "count"),
  plot_by_types = c("continuous", "discrete")
)
