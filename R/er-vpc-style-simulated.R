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
#'   and `er_style_vpc_simulated_quantile_errorbar()`'s error bars when
#'   `plot_by` is categorical.
#' @param errorbar_width_continuous Width (as a fraction of `plot_by`'s
#'   own range, `config$group_limits`) of
#'   `er_style_vpc_simulated_mean_errorbar()`'s and
#'   `er_style_vpc_simulated_quantile_errorbar()`'s error bars when
#'   `plot_by` is numeric.
#' @param ribbon_alpha Fill transparency for `er_style_vpc_simulated_quantile_ribbon()`'s bands.
#' @param ribbon_edges Whether `er_style_vpc_simulated_quantile_ribbon()`
#'   additionally draws a line along each band's own `ci_lower`/`ci_upper`
#'   bounds, on top of the shaded ribbon fill -- mirrors
#'   [er_style_model_ribbonline()]'s own `ribbon_edges` argument. Default
#'   `FALSE` (ribbon fill only). Useful when several requested percentiles'
#'   bands overlap: the edge lines stay legible even where the fills merge
#'   into an indistinguishable blob.
#' @param edge_linetype,edge_linewidth,edge_colour Styling for
#'   `er_style_vpc_simulated_quantile_ribbon()`'s optional edge lines
#'   (only drawn when `ribbon_edges = TRUE`). Defaults to a thin, light
#'   dotted line (`"dotted"`, `0.5`, `"grey50"`) that stays unobtrusive
#'   even when several bands' edges overlap.
#' @param median_linetype,median_linewidth,median_colour Styling for
#'   `er_style_vpc_simulated_quantile_ribbon()`'s median line, drawn at
#'   each band's `y_mid`. Defaults match the previous fixed styling
#'   (`"dashed"`, `0.5`, `"grey30"`).
#' @param ... Additional named arguments forwarded from
#'   [er_vpc_add_simulated()]'s own `...`.
#'
#' @details `er_style_vpc_simulated_mean_errorbar()` (the default) plots
#' `config$summary`'s mean + percentile interval (of the mean, across
#' replicates), adapting its x-position to `plot_by`'s type
#' (`config$is_numeric_group`): equally spaced at each bin's categorical
#' (or quantile-bin) label when `plot_by` is categorical, or at each
#' bin's numeric median (`x_median`, from `config$summary`) on the
#' `plot_by`'s own numeric scale when `plot_by` is numeric. Because it adapts its
#' x-position family at build time rather than declaring one statically,
#' it carries no `layout` tag -- pair it with
#' [er_style_vpc_observed_mean_errorbar()], which mirrors the same
#' adaptive logic.
#'
#' `er_style_vpc_simulated_quantile_ribbon()` plots `config$percentiles`
#' -- one shaded band (median line + interval) per requested percentile
#' -- at each bin's numeric midpoint on `plot_by`'s own numeric scale, for pairing
#' with [er_style_vpc_observed_quantile_line()]. `config$percentiles` is
#' only computed for a continuous/count response (see [er_vpc()]'s
#' `probs` argument); calling `er_style_vpc_simulated_quantile_ribbon()`
#' without it errors.
#'
#' `er_style_vpc_simulated_quantile_errorbar()` plots `config$percentiles`
#' -- a point + across-replicate percentile interval for each requested
#' percentile -- for pairing with
#' [er_style_vpc_observed_quantile_errorbar()]. Like that builder (and
#' like `er_style_vpc_simulated_mean_errorbar()`), it adapts its
#' x-position to `plot_by`'s type, carries no `layout` tag, supports
#' both a numeric and a categorical `plot_by`, and requires a
#' continuous/count response, erroring informatively without
#' `config$percentiles`. As with the observed-layer counterpart, when
#' more than one percentile is requested they are currently all plotted
#' at the same x-position within a bin rather than dodged apart.
#'
#' `er_style_vpc_simulated_mean_errorbar()`/`er_style_vpc_simulated_quantile_errorbar()`
#' map a constant `color = "Simulated"`; `er_style_vpc_simulated_quantile_ribbon()`
#' maps a constant `fill = "Simulated"`. ggplot2 merges either into the
#' paired observed builder's own `"Observed"` legend entry (same
#' aesthetic) into one combined legend; the ribbon's `fill` legend is
#' separate from the point/errorbar builders' `color` legend.
#'
#' When several requested percentiles' bands sit close together (small
#' per-bin samples, few simulated replicates, or `probs` values close to
#' one another), `er_style_vpc_simulated_quantile_ribbon()`'s bands can
#' overlap enough that the shaded fills merge into a single
#' indistinguishable region, and its median lines -- all styled
#' identically -- become the only way to tell the bands apart, which
#' fails wherever two of them cross. `ribbon_edges = TRUE` mitigates this
#' by drawing each band's own `ci_lower`/`ci_upper` bounds as a line (see
#' `edge_linetype`/`edge_linewidth`/`edge_colour`), which stays legible
#' even where the fills themselves are illegible.
#'
#' @returns A list of geoms; see [er_style()].
#'
#' @name er_style_vpc_simulated
#' @seealso [er_style()], [er_style_vpc_observed()]
NULL

#' @rdname er_style_vpc_simulated
#' @export
er_style_vpc_simulated_quantile_ribbon <- function(data, config, exposure, response, theme,
                                           ribbon_alpha = 0.3,
                                           ribbon_edges = FALSE,
                                           edge_linetype = "dotted",
                                           edge_linewidth = 0.5,
                                           edge_colour = "grey50",
                                           median_linetype = "dashed",
                                           median_linewidth = 0.5,
                                           median_colour = "grey30",
                                           ...) {
  if (is.null(config$percentiles)) {
    rlang::abort(c(
      "`er_style_vpc_simulated_quantile_ribbon()` requires `config$percentiles`, which is not available here.",
      "i" = "Percentiles are only computed for a continuous/count response binned on a numeric `plot_by` -- see `er_vpc_add_observed()`/`er_vpc_add_simulated()`.",
      "i" = "Use `er_style_vpc_simulated_mean_errorbar()` instead for a binary response or a categorical `plot_by`."
    ))
  }

  geoms <- list(
    ggplot2::geom_ribbon(
      data = config$percentiles,
      mapping = ggplot2::aes(x = x_mid, ymin = ci_lower, ymax = ci_upper, group = factor(prob), fill = "Simulated"),
      alpha = ribbon_alpha,
      inherit.aes = FALSE
    )
  )

  # only ever included when requested, rather than as `NULL`
  # placeholders -- mirrors `er_style_model_ribbonline()`'s own
  # `ribbon_edges` handling and its rationale (this builder's return
  # length is asserted on directly in tests)
  if (ribbon_edges) {
    geoms <- c(
      geoms,
      list(
        ggplot2::geom_line(
          data = config$percentiles,
          mapping = ggplot2::aes(x = x_mid, y = ci_lower, group = factor(prob)),
          linetype = edge_linetype,
          linewidth = edge_linewidth,
          colour = edge_colour,
          inherit.aes = FALSE
        ),
        ggplot2::geom_line(
          data = config$percentiles,
          mapping = ggplot2::aes(x = x_mid, y = ci_upper, group = factor(prob)),
          linetype = edge_linetype,
          linewidth = edge_linewidth,
          colour = edge_colour,
          inherit.aes = FALSE
        )
      )
    )
  }

  geoms <- c(
    geoms,
    list(
      ggplot2::geom_line(
        data = config$percentiles,
        mapping = ggplot2::aes(x = x_mid, y = y_mid, group = factor(prob)),
        linetype = median_linetype,
        linewidth = median_linewidth,
        colour = median_colour,
        inherit.aes = FALSE
      ),
      ggplot2::labs(fill = "Source")
    )
  )

  return(geoms)
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
                                                      point_size = 1.5, errorbar_width = 0.15,
                                                      errorbar_width_continuous = 0.025, ...) {
  if (is.null(config$percentiles)) {
    rlang::abort(c(
      "`er_style_vpc_simulated_quantile_errorbar()` requires `config$percentiles`, which is not available here.",
      "i" = "Percentiles are only computed for a continuous/count response -- see `er_vpc_add_observed()`/`er_vpc_add_simulated()`.",
      "i" = "Use `er_style_vpc_simulated_mean_errorbar()` instead for a binary response."
    ))
  }
  if (config$is_numeric_group) {
    width <- errorbar_width_continuous * (config$group_limits[2] - config$group_limits[1])
    list(
      ggplot2::geom_errorbar(
        data = config$percentiles,
        mapping = ggplot2::aes(x = x_median, ymin = ci_lower, ymax = ci_upper, group = factor(prob), color = "Simulated"),
        width = width,
        inherit.aes = FALSE
      ),
      ggplot2::geom_point(
        data = config$percentiles,
        mapping = ggplot2::aes(x = x_median, y = y_mid, group = factor(prob), color = "Simulated"),
        size = point_size,
        inherit.aes = FALSE
      )
    )
  } else {
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
}
er_style_vpc_simulated_quantile_errorbar <- er_style_tag(
  er_style_vpc_simulated_quantile_errorbar,
  layer = "simulated",
  response_types = c("continuous", "count"),
  plot_by_types = c("continuous", "discrete")
)


#' @rdname er_style_vpc_simulated
#' @export
er_style_vpc_simulated_mean_errorbar <- function(data, config, exposure, response, theme,
                                                  point_size = 2, errorbar_width = 0.2,
                                                  errorbar_width_continuous = 0.025, ...) {
  if (config$is_numeric_group) {
    width <- errorbar_width_continuous * (config$group_limits[2] - config$group_limits[1])
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
