#' Observed-layer builders for VPC plots
#'
#' Builder functions for the `observed` layer ([er_vpc_add_observed()]),
#' drawing the observed side of a visual predictive check as a
#' mean/rate + confidence interval per bin (the default, adaptive to
#' `plot_by`'s type), a continuous-x line of empirical percentiles, or a
#' point/interval per bin *and* per requested percentile.
#'
#' @include er-plot-style.R
#' @param data The original data frame.
#' @param config Configuration for the observed layer.
#' @param exposure Exposure variable.
#' @param response Response variable.
#' @param theme Theme components.
#' @param point_size Point size for all three point/interval builders.
#' @param errorbar_width Width of `er_style_vpc_observed_mean_errorbar()`'s
#'   and `er_style_vpc_observed_quantile_errorbar()`'s error bars.
#'   Interpreted differently depending on `plot_by`'s type: for a
#'   categorical `plot_by`, it's a bar width in the same implied
#'   unit-scaled category-gap units `ggplot2::geom_errorbar()` normally
#'   expects; for a numeric `plot_by`, it's a fraction of `plot_by`'s own
#'   range (`config$group_limits`), so `1` would span the full range.
#'   Defaults to `NULL`, which resolves to `0.15`
#'   (`er_style_vpc_observed_quantile_errorbar()`) or `0.2`
#'   (`er_style_vpc_observed_mean_errorbar()`) for a categorical
#'   `plot_by`, or `0.025` for a numeric one.
#' @param dodge Horizontal offset (as a fraction of `plot_by`'s own
#'   range, like `errorbar_width` for a numeric `plot_by`) applied to all of this
#'   builder's error bars/points, for both `er_style_vpc_observed_mean_errorbar()`
#'   and `er_style_vpc_observed_quantile_errorbar()`. Default `0`
#'   (no offset, the previous behaviour). Useful for manually separating
#'   the observed layer from an overlapping simulated one at the same
#'   bin -- e.g. `dodge = -0.01` on the observed builder paired with
#'   `dodge = 0.01` on the corresponding simulated builder. Only
#'   supported when `plot_by` is numeric; a nonzero value is ignored
#'   with a warning for a categorical `plot_by`, where dodging isn't
#'   implemented yet.
#' @param prob_dodge_width Horizontal spread (as a fraction of `plot_by`'s
#'   own range) applied to `er_style_vpc_observed_quantile_errorbar()`'s
#'   requested `probs` within a single bin, symmetrically centred on
#'   that bin's own position (added on top of `dodge`, if also
#'   supplied). Default `0` (all `probs` plotted at the same position,
#'   the previous behaviour). Useful when several `probs`' error bars
#'   overlap enough to be unreadable. Same numeric-`plot_by`-only
#'   restriction as `dodge`.
#' @param ... Additional named arguments forwarded from
#'   [er_vpc_add_observed()]'s own `...`.
#'
#' @details `er_style_vpc_observed_mean_errorbar()` (the default) plots
#' `config$summary`'s rate/mean + confidence interval, adapting its
#' x-position to `plot_by`'s type (`config$is_numeric_group`): equally
#' spaced at each bin's categorical (or quantile-bin) label when
#' `plot_by` is categorical, or at each bin's numeric median (`x_median`,
#' from `config$summary`) on `plot_by`'s own numeric scale when `plot_by` is
#' numeric. Because it adapts its x-position family at build time rather
#' than declaring one statically, it carries no `layout` tag -- pair it
#' with [er_style_vpc_simulated_mean_errorbar()], which mirrors the same
#' adaptive logic.
#'
#' `er_style_vpc_observed_quantile_line()` plots `config$percentiles` --
#' one line per requested percentile -- at each bin's numeric midpoint on
#' `plot_by`'s own numeric scale, for pairing with
#' [er_style_vpc_simulated_quantile_ribbon()]. `config$percentiles` is
#' only computed for a continuous/count response (see [er_vpc()]'s
#' `probs` argument); calling `er_style_vpc_observed_quantile_line()`
#' without it errors.
#'
#' `er_style_vpc_observed_quantile_errorbar()` plots `config$percentiles`
#' -- a point + confidence interval (via [ci_quantile()]) for each
#' requested percentile -- for pairing with
#' [er_style_vpc_simulated_quantile_errorbar()]. Like
#' `er_style_vpc_observed_mean_errorbar()`, it adapts its x-position to
#' `plot_by`'s type (`config$is_numeric_group`): equally spaced at each
#' bin's categorical (or quantile-bin) label when `plot_by` is
#' categorical, or at each bin's numeric median (`x_median`, from
#' `config$percentiles`) on `plot_by`'s own numeric scale when `plot_by` is
#' numeric. Because it adapts its x-position family at build time rather
#' than declaring one statically, it carries no `layout` tag. Unlike
#' `er_style_vpc_observed_quantile_line()`/
#' `er_style_vpc_simulated_quantile_ribbon()`, it supports a categorical
#' `plot_by` as well as a numeric one; like it, it requires a
#' continuous/count response (a binary response's distribution is
#' already fully described by its rate) and errors informatively without
#' `config$percentiles`. When more than one percentile is requested, all
#' of them are currently plotted at the same x-position within a bin
#' rather than dodged apart, so overlapping error bars/points are only
#' distinguishable by their y-position -- dodging support may be added
#' in a future release.
#'
#' Each builder maps a constant `color = "Observed"`, so ggplot2 merges
#' its legend entry with whatever the paired simulated-layer builder
#' maps for `"Simulated"` into a single combined legend.
#'
#' In the worst case -- `er_style_vpc_observed_quantile_errorbar()`
#' paired with `er_style_vpc_simulated_quantile_errorbar()` for a
#' numeric `plot_by` with several `probs` -- up to `2 * length(probs)`
#' error bars land at the exact same x-position within a bin (every
#' `probs` value, for both the observed and simulated layers), which can
#' be unreadable. `dodge` (separating the observed and simulated layers)
#' and `prob_dodge_width` (spreading a single layer's own `probs` apart)
#' are both opt-in, manual escape hatches for this -- see their own
#' argument docs above. Neither is automatic, because which collision is
#' actually occurring (source-vs-source, `probs`-vs-`probs`, or both)
#' depends on the data at hand.
#'
#' @returns A list of geoms; see [er_style()].
#'
#' @name er_style_vpc_observed
#' @seealso [er_style()], [er_style_vpc_simulated()]
NULL

#' @rdname er_style_vpc_observed
#' @export
er_style_vpc_observed_quantile_line <- function(data, config, exposure, response, theme,
                                        point_size = 1.5, ...) {
  if (is.null(config$percentiles)) {
    rlang::abort(c(
      "`er_style_vpc_observed_quantile_line()` requires `config$percentiles`, which is not available here.",
      "i" = "Percentiles are only computed for a continuous/count response binned on a numeric `plot_by` -- see `er_vpc_add_observed()`.",
      "i" = "Use `er_style_vpc_observed_mean_errorbar()` instead for a binary response or a categorical `plot_by`."
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
                                                     point_size = 1.5, errorbar_width = NULL,
                                                     dodge = 0, prob_dodge_width = 0, ...) {
  if (is.null(config$percentiles)) {
    rlang::abort(c(
      "`er_style_vpc_observed_quantile_errorbar()` requires `config$percentiles`, which is not available here.",
      "i" = "Percentiles are only computed for a continuous/count response -- see `er_vpc_add_observed()`.",
      "i" = "Use `er_style_vpc_observed_mean_errorbar()` instead for a binary response."
    ))
  }
  if (is.null(errorbar_width)) {
    errorbar_width <- if (config$is_numeric_group) 0.025 else 0.15
  }
  if (config$is_numeric_group) {
    width <- errorbar_width * (config$group_limits[2] - config$group_limits[1])
    # a local copy, not a mutation of `config$percentiles` itself -- at
    # the `dodge = 0`/`prob_dodge_width = 0` defaults both offsets are
    # zero, so `x_median` is numerically unchanged and this stays
    # equivalent to plotting `config$percentiles` directly
    percentiles <- config$percentiles
    percentiles$x_median <- percentiles$x_median +
      .vpc_dodge_step(dodge, config$group_limits) +
      .vpc_dodge_probs_offset(percentiles$prob, prob_dodge_width, config$group_limits)
    list(
      ggplot2::geom_errorbar(
        data = percentiles,
        mapping = ggplot2::aes(x = x_median, ymin = ci_lower, ymax = ci_upper, group = factor(prob), color = "Observed"),
        width = width,
        inherit.aes = FALSE
      ),
      ggplot2::geom_point(
        data = percentiles,
        mapping = ggplot2::aes(x = x_median, y = y, group = factor(prob), color = "Observed"),
        size = point_size,
        inherit.aes = FALSE
      )
    )
  } else {
    if (dodge != 0 || prob_dodge_width != 0) {
      rlang::warn(c(
        "`dodge`/`prob_dodge_width` are only supported for a numeric `plot_by`; ignoring them for a categorical one.",
        "i" = "Dodging a categorical `plot_by`'s bin positions isn't implemented yet."
      ))
    }
    list(
      ggplot2::geom_errorbar(
        data = config$percentiles,
        mapping = ggplot2::aes(x = .vpc_bin, ymin = ci_lower, ymax = ci_upper, group = factor(prob), color = "Observed"),
        width = errorbar_width,
        inherit.aes = FALSE
      ),
      ggplot2::geom_point(
        data = config$percentiles,
        mapping = ggplot2::aes(x = .vpc_bin, y = y, group = factor(prob), color = "Observed"),
        size = point_size,
        inherit.aes = FALSE
      )
    )
  }
}
er_style_vpc_observed_quantile_errorbar <- er_style_tag(
  er_style_vpc_observed_quantile_errorbar,
  layer = "observed",
  response_types = c("continuous", "count"),
  plot_by_types = c("continuous", "discrete")
)


#' @rdname er_style_vpc_observed
#' @export
er_style_vpc_observed_mean_errorbar <- function(data, config, exposure, response, theme,
                                                 point_size = 2, errorbar_width = NULL,
                                                 dodge = 0, ...) {
  if (is.null(errorbar_width)) {
    errorbar_width <- if (config$is_numeric_group) 0.025 else 0.2
  }
  if (config$is_numeric_group) {
    width <- errorbar_width * (config$group_limits[2] - config$group_limits[1])
    # a local copy, not a mutation of `config$summary` itself -- at the
    # `dodge = 0` default the offset is zero, so `x_median` is
    # numerically unchanged and this stays equivalent to plotting
    # `config$summary` directly
    summary <- config$summary
    summary$x_median <- summary$x_median + .vpc_dodge_step(dodge, config$group_limits)
    list(
      ggplot2::geom_errorbar(
        data = summary,
        mapping = ggplot2::aes(x = x_median, ymin = ci_lower, ymax = ci_upper, color = "Observed"),
        width = width,
        inherit.aes = FALSE
      ),
      ggplot2::geom_point(
        data = summary,
        mapping = ggplot2::aes(x = x_median, y = y_mid, color = "Observed"),
        size = point_size,
        inherit.aes = FALSE
      )
    )
  } else {
    if (dodge != 0) {
      rlang::warn(c(
        "`dodge` is only supported for a numeric `plot_by`; ignoring it for a categorical one.",
        "i" = "Dodging a categorical `plot_by`'s bin positions isn't implemented yet."
      ))
    }
    list(
      ggplot2::geom_errorbar(
        data = config$summary,
        mapping = ggplot2::aes(x = .vpc_bin, ymin = ci_lower, ymax = ci_upper, color = "Observed"),
        width = errorbar_width,
        inherit.aes = FALSE
      ),
      ggplot2::geom_point(
        data = config$summary,
        mapping = ggplot2::aes(x = .vpc_bin, y = y_mid, color = "Observed"),
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
