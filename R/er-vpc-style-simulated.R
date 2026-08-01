#' Simulated-layer builders for VPC plots
#'
#' Builder functions for the `simulated` layer ([er_vpc_add_simulated()]),
#' drawing the simulated side of a visual predictive check as a
#' mean + percentile interval per bin (the default, adaptive to
#' `plot_by`'s type), a dodged point/interval per categorical bin, or as
#' continuous-x percentile bands.
#'
#' @include er-plot-style.R
#' @param data The original data frame.
#' @param config Configuration for the simulated layer.
#' @param exposure Exposure variable.
#' @param response Response variable.
#' @param theme Theme components.
#' @param point_size Point size for all three point/interval builders.
#' @param errorbar_width Width of `er_style_vpc_simulated_errorbar()`'s
#'   error bars, and of `er_style_vpc_simulated_mean_errorbar()`'s when
#'   `plot_by` is categorical.
#' @param errorbar_width_continuous Width (as a fraction of the exposure
#'   range) of `er_style_vpc_simulated_mean_errorbar()`'s error bars when
#'   `plot_by` is numeric.
#' @param ribbon_alpha Fill transparency for `er_style_vpc_simulated_ribbon()`'s bands.
#' @param ... Additional named arguments forwarded from
#'   [er_vpc_add_simulated()]'s own `...`.
#'
#' @details `er_style_vpc_simulated_mean_errorbar()` (the default) plots
#' `config$summary`'s mean + percentile interval (of the mean, across
#' replicates), adapting its x-position to `plot_by`'s type
#' (`config$is_numeric_group`): equally spaced at each bin's categorical
#' (or quantile-bin) label when `plot_by` is categorical (like
#' `er_style_vpc_simulated_errorbar()`), or at each bin's numeric median
#' (`x_median`, from `config$summary`) on the exposure scale when
#' `plot_by` is numeric (like `er_style_vpc_simulated_errorbar_continuous()`,
#' which uses the mean instead). Because it adapts its x-position family
#' at build time rather than declaring one statically, it carries no
#' `layout` tag -- pair it with [er_style_vpc_observed_mean_errorbar()],
#' which mirrors the same adaptive logic.
#'
#' `er_style_vpc_simulated_errorbar()` plots `config$summary`'s
#' mean + percentile interval (of the mean, across replicates) at each
#' bin's categorical (or quantile-bin) label, dodged alongside the
#' observed layer's own point + interval.
#' `er_style_vpc_simulated_ribbon()` instead plots `config$percentiles`
#' -- one shaded band (median line + interval) per requested percentile
#' -- at each bin's numeric midpoint on the exposure scale, for pairing
#' with [er_style_vpc_observed_line()]. `config$percentiles` is only
#' computed for a continuous/count response binned on a numeric
#' `plot_by` (see [er_vpc()]'s `probs` argument); calling
#' `er_style_vpc_simulated_ribbon()` without it errors.
#' `er_style_vpc_simulated_errorbar_continuous()` plots the same mean +
#' percentile interval as `er_style_vpc_simulated_errorbar()`, at the
#' bin's numeric midpoint like `er_style_vpc_simulated_ribbon()` does --
#' for pairing with
#' [er_style_vpc_observed_pointrange_continuous()] or any other
#' `"continuous"`-layout observed builder without a layout mismatch. It
#' always plots the mean (from `config$summary`, so it works for a
#' binary response too); when `config$percentiles` is also available
#' (continuous/count response, numeric `plot_by`), it additionally
#' plots a dashed pointrange/errorbar for each requested percentile --
#' the same across-replicate interval `er_style_vpc_simulated_ribbon()`
#' shows as a band.
#'
#' `er_style_vpc_simulated_errorbar()`/`er_style_vpc_simulated_errorbar_continuous()`/
#' `er_style_vpc_simulated_mean_errorbar()` map a constant
#' `color = "Simulated"`; `er_style_vpc_simulated_ribbon()`
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
er_style_vpc_simulated_errorbar <- er_style_tag(
  er_style_vpc_simulated_errorbar,
  layer = "simulated", layout = "categorical",
  response_types = c("binary", "continuous", "count"),
  plot_by_types = c("continuous", "discrete")
)


#' @rdname er_style_vpc_simulated
#' @export
er_style_vpc_simulated_errorbar_continuous <- function(data, config, exposure, response, theme,
                                                         point_size = 2, errorbar_width = 0.025, ...) {
  if (!isTRUE(config$is_numeric_group)) {
    rlang::abort(c(
      "`er_style_vpc_simulated_errorbar_continuous()` requires a numeric `plot_by`, so that each bin has a numeric midpoint to plot at.",
      "i" = "Use `er_style_vpc_simulated_errorbar()` instead for a categorical `plot_by`."
    ))
  }
  width <- errorbar_width * (exposure$limits[2] - exposure$limits[1])
  geoms <- list(
    ggplot2::geom_errorbar(
      data = config$summary,
      mapping = ggplot2::aes(x = x_mid, ymin = ci_lower, ymax = ci_upper, color = "Simulated"),
      width = width,
      inherit.aes = FALSE
    ),
    ggplot2::geom_point(
      data = config$summary,
      mapping = ggplot2::aes(x = x_mid, y = y_mid, color = "Simulated"),
      size = point_size,
      inherit.aes = FALSE
    )
  )
  if (!is.null(config$percentiles)) {
    geoms <- c(geoms, list(
      ggplot2::geom_errorbar(
        data = config$percentiles,
        mapping = ggplot2::aes(x = x_mid, ymin = ci_lower, ymax = ci_upper, color = "Simulated"),
        linetype = "dashed",
        width = width,
        inherit.aes = FALSE
      ),
      ggplot2::geom_point(
        data = config$percentiles,
        mapping = ggplot2::aes(x = x_mid, y = y_mid, color = "Simulated"),
        size = point_size * 0.75,
        inherit.aes = FALSE
      )
    ))
  }
  geoms
}
er_style_vpc_simulated_errorbar_continuous <- er_style_tag(
  er_style_vpc_simulated_errorbar_continuous,
  layer = "simulated", layout = "continuous",
  response_types = c("binary", "continuous", "count"),
  plot_by_types = "continuous"
)


#' @rdname er_style_vpc_simulated
#' @export
er_style_vpc_simulated_ribbon <- function(data, config, exposure, response, theme,
                                           ribbon_alpha = 0.3, ...) {
  if (is.null(config$percentiles)) {
    rlang::abort(c(
      "`er_style_vpc_simulated_ribbon()` requires `config$percentiles`, which is not available here.",
      "i" = "Percentiles are only computed for a continuous/count response binned on a numeric `plot_by` -- see `er_vpc_add_observed()`/`er_vpc_add_simulated()`.",
      "i" = "Use `er_style_vpc_simulated_errorbar()` instead for a binary response or a categorical `plot_by`."
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
er_style_vpc_simulated_ribbon <- er_style_tag(
  er_style_vpc_simulated_ribbon,
  layer = "simulated", layout = "continuous",
  response_types = c("continuous", "count"),
  plot_by_types = "continuous"
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
}
er_style_vpc_simulated_mean_errorbar <- er_style_tag(
  er_style_vpc_simulated_mean_errorbar,
  layer = "simulated",
  response_types = c("binary", "continuous", "count"),
  plot_by_types = c("continuous", "discrete")
)
