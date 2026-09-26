
`%||%` <- function(x, y) {
  if (is.null(x)) return(y)
  x
}

# Errors informatively if any element of a named-list-style argument
# (either an already-captured `rlang::list2(...)`, or a `predict_args`/
# `summary_args`/`simulate_args`-style list) is unnamed. Both kinds are
# spliced (via `!!!`/`rlang::exec()`) into a call by name -- a builder's
# standard positional arguments for the `...` case (see `?er_style`'s
# "Passing extra arguments to a builder" section), or a model-interface
# generic's own arguments for the `*_args` case -- so an unnamed element
# would silently bind to the wrong parameter rather than erroring here.
#' @noRd
.check_dots_named <- function(dots, arg = "...") {
  if (length(dots) == 0) return(invisible(NULL))
  nms <- names(dots)
  if (is.null(nms) || any(!nzchar(nms))) {
    rlang::abort(c(
      paste0("All arguments passed via `", arg, "` must be named."),
      "i" = "These are spliced into a call by name, so an unnamed argument would bind to the wrong parameter."
    ))
  }
  invisible(NULL)
}

.get_label <- function(x) attr(x, "label")
.set_label <- function(x, lbl) {attr(x, "label") <- lbl; x}
.set_names <- function(x, nm) {names(x) <- nm; x}

# Filters `data` to rows whose `exposure_name`/`response_name` columns lie
# within the given limits, warning (`rlang::warn()`, mirroring ggplot2's
# own "Removed N rows containing missing values" convention for
# out-of-bound data) whenever doing so drops at least one row.
# `response_name`/`response_limits` are optional -- pass `NULL` for a
# layer that never maps `response` (e.g. the group layer's exposure-only
# panels).
#
# Existing `NA`s in either column are left alone (kept) rather than
# counted as "outside the limits" -- that's a separate, pre-existing
# missingness concern this helper isn't meant to speak to.
#
# Used by every layer that plots genuine observations in full regardless
# of `exposure$limits`/`response$limits` -- the data layer's
# overlay/panel builders and the group layer's panels. Unlike the model
# layer, whose synthetic prediction grid is instead *regenerated* exactly
# within limits at build time (see issue #14/PR #15), there's no stale
# cache to refresh here: the data genuinely extends beyond whatever
# window `er_plot_theme(xlim = ...)`/`ylim = ...)` chose, so out-of-range
# rows are dropped for display (rather than left to spill inconsistently
# past the panel border, or -- for a large enough overshoot -- vanish off
# the finite output device with no visual cue at all) and their count
# reported instead.
#' @noRd
.clip_to_limits <- function(data, exposure_name, exposure_limits,
                             response_name = NULL, response_limits = NULL,
                             layer_label = "observations") {
  in_range <- function(x, limits) is.na(x) | (x >= limits[1] & x <= limits[2])

  keep <- in_range(data[[exposure_name]], exposure_limits)
  if (!is.null(response_name) && !is.null(response_limits)) {
    keep <- keep & in_range(data[[response_name]], response_limits)
  }

  n_dropped <- sum(!keep)
  if (n_dropped > 0) {
    rlang::warn(sprintf(
      "%d of %d %s (%s) fall outside the plotted axis limits and %s not shown.",
      n_dropped, nrow(data), layer_label,
      scales::percent(n_dropped / nrow(data), accuracy = 1),
      if (n_dropped == 1) "is" else "are"
    ))
  }

  data[keep, , drop = FALSE]
}

# The quantile layer's own variant of `.clip_to_limits()`: unlike raw
# observations, a quantile bin's mean/rate + CI (`config$summary`, built
# once from *all* of `object$data` in `.layer_quantile()`) is deliberately
# left untouched by `exposure$limits`/`response$limits` -- narrowing the
# axis shouldn't silently change which observations feed a bin's
# statistic. What this filters is only the *marker* -- whether a given
# bin's `x_mid`/`y_mid` is drawn at all -- so a whole summary point
# disappearing is called out by name (which bin) rather than folded into
# a generic dropped-observations count.
#' @noRd
.clip_quantile_summary_to_limits <- function(summary, exposure_limits, response_limits,
                                              bin_col = "exposure_bins") {
  in_range <- function(x, limits) is.na(x) | (x >= limits[1] & x <= limits[2])

  keep <- in_range(summary$x_mid, exposure_limits) & in_range(summary$y_mid, response_limits)
  n_dropped <- sum(!keep)
  if (n_dropped > 0) {
    hidden_bins <- as.character(summary[[bin_col]][!keep])
    rlang::warn(c(
      sprintf(
        "%d of %d quantile bin marker%s fall%s outside the plotted axis limits and %s not shown: %s.",
        n_dropped, nrow(summary), if (n_dropped == 1) "" else "s",
        if (n_dropped == 1) "s" else "", if (n_dropped == 1) "is" else "are",
        paste(hidden_bins, collapse = ", ")
      ),
      "i" = "The bin's own mean/rate and CI are still computed from every observation in it -- only its marker's position falls outside the current `xlim`/`ylim`.",
      "i" = "Widen `xlim`/`ylim` (via `er_plot_theme()`) to show it, or reduce `bins` if the quantile boundaries themselves are the problem."
    ))
  }

  summary[keep, , drop = FALSE]
}

# The quantile layer's `_vlines` builders' own variant of
# `.clip_quantile_summary_to_limits()`: `config$breaks` is a fixed set of
# `n + 1` cutpoints from `cut_exposure_quantile()` (both interior and outer
# bin boundaries), independent of `config$summary`, so it needs its own
# filter -- narrowing `xlim` should hide a boundary line/label that falls
# outside it, the same way it hides a summary marker. A dropped break has
# no bin label of its own (unlike a dropped summary row, which is named by
# its `exposure_bins` level), so the warning names the break's own value
# instead.
#' @noRd
.clip_quantile_breaks_to_limits <- function(breaks, exposure_limits) {
  if (is.null(breaks)) return(breaks)

  keep <- breaks >= exposure_limits[1] & breaks <= exposure_limits[2]
  n_dropped <- sum(!keep)
  if (n_dropped > 0) {
    rlang::warn(c(
      sprintf(
        "%d of %d quantile-bin boundary line%s fall%s outside the plotted axis limits and %s not shown: %s.",
        n_dropped, length(breaks), if (n_dropped == 1) "" else "s",
        if (n_dropped == 1) "s" else "", if (n_dropped == 1) "is" else "are",
        paste(scales::label_number(big.mark = ",")(breaks[!keep]), collapse = ", ")
      ),
      "i" = "Widen `xlim` (via `er_plot_theme()`) to show it."
    ))
  }

  breaks[keep]
}

# Shared response-value validation, used by both `er_plot()` and
# `er_vpc()`: a declared `response_type = "binary"` response with values
# outside {0, 1} silently shrinks the rate calculation's denominator
# (warn); a declared `response_type = "count"` response with a negative
# value breaks `ci_poisson()`'s exact interval outright (error).
#' @noRd
.validate_response_values <- function(response_type, response_vals, response_name) {
  if (response_type == "binary" && !is.logical(response_vals)) {
    n_out_of_range <- sum(!is.na(response_vals) & !(response_vals %in% c(0, 1)))
    if (n_out_of_range > 0) {
      rlang::warn(c(
        sprintf(
          "`response_type = \"binary\"` was declared for `%s`, but %d value%s outside {0, 1}.",
          response_name, n_out_of_range, if (n_out_of_range == 1) " is" else "s are"
        ),
        "i" = "Rows with an out-of-range value are silently excluded from the rate calculation (neither a responder nor a non-responder), shrinking the effective denominator.",
        "i" = "Pass `response_type = \"continuous\"` if this isn't actually a binary response."
      ))
    }
  }
  if (response_type == "count") {
    n_negative <- sum(!is.na(response_vals) & response_vals < 0)
    if (n_negative > 0) {
      rlang::abort(c(
        sprintf(
          "`response_type = \"count\"` was declared for `%s`, but %d value%s negative.",
          response_name, n_negative, if (n_negative == 1) " is" else "s are"
        ),
        "i" = "A count response must be non-negative -- the exact Poisson interval (`ci_poisson()`) is undefined for a negative total.",
        "i" = "Pass `response_type = \"continuous\"` if this isn't actually a count response."
      ))
    }
  }
  invisible(NULL)
}

# Shared by `er_plot()`/`er_tte()`/`er_vpc()`: `stratify_by` must name a
# discrete/categorical variable in all three -- erplots deliberately
# doesn't auto-bin a numeric one on the caller's behalf (unlike
# `exposure`/`plot_by`, where binning is intrinsic to what the plot even
# is). Deciding how to carve a continuous covariate into groups is a
# substantive statistical choice, not a plotting one; the fix is one
# `dplyr::mutate(x_grp = cut_quantile(x, ...))` call before plotting,
# which also gives full control over bin count/tie-breaking/labels via
# `cut_quantile()`/`cut_exposure_quantile()`'s own arguments, rather than
# each mini-grammar's own `stratify_by` needing to redundantly expose
# that same control. `strata_name` may be `NULL` (no `stratify_by`
# supplied), in which case this is a no-op.
#' @noRd
.check_stratify_by_discrete <- function(data, strata_name) {
  if (is.null(strata_name)) return(invisible(NULL))
  if (is.numeric(data[[strata_name]])) {
    rlang::abort(c(
      sprintf("`stratify_by` (`%s`) must be discrete, not numeric.", strata_name),
      "i" = "Bin it yourself first (e.g. `dplyr::mutate(data, grp = cut_quantile(x, n = 4))`), then pass the resulting factor to `stratify_by`.",
      "i" = "See `?cut_quantile`/`?cut_exposure_quantile` for control over bin count, tie-breaking, and labels."
    ))
  }
  invisible(NULL)
}

# Validates `nsim` up front for `er_vpc_add_simulated(model = ...)` --
# without this, `nsim = 0`/negative/fractional values ran to completion
# but failed deep inside whatever matrix/vector machinery a model's
# `er_simulate()` method happens to use, with no indication that `nsim`
# itself was the problem.
#' @noRd
.check_nsim <- function(nsim) {
  if (!is.numeric(nsim) || length(nsim) != 1L) {
    rlang::abort("`nsim` must be a single number.")
  }
  if (!is.finite(nsim) || nsim < 1 || nsim != round(nsim)) {
    rlang::abort(c(
      sprintf("`nsim` must be a positive whole number, not %s.", format(nsim)),
      "i" = "`nsim` is the number of simulation replicates drawn via `er_simulate()`."
    ))
  }
  invisible(NULL)
}

# Assigns each element of `x` to a bin using pre-computed `breaks` (rather
# than re-deriving quantiles from `x` itself, as `cut_exposure_quantile()`
# does) -- used by `.layer_vpc_simulated()` to bin simulated exposure
# values against the *same* cutpoints the observed layer already
# computed, so the two sides are guaranteed to share bin boundaries.
# Mirrors `cut_exposure_quantile()`'s own placebo-handling/labelling,
# including its `ties`/label/seed handling (via `.cut_quantile_bin_num()`,
# defined further down this file) -- `ties = "upward"`/`labels = NULL` (the
# defaults) reproduce this function's own prior, hardcoded behaviour
# exactly, so this is a pure superset for any existing caller.
#' @noRd
.apply_exposure_breaks <- function(x, breaks, is_placebo = NULL,
                                    ties = "upward", labels = NULL, seed = NULL) {
  if (is.null(is_placebo)) is_placebo <- rep(FALSE, length(x))
  n <- length(breaks) - 1
  bin_num <- .cut_quantile_bin_num(x, breaks, n, ties, seed = seed)
  exp_bin <- dplyr::case_when(
    is_placebo ~ 0,
    is.na(x) ~ NA_real_,
    TRUE ~ bin_num
  )
  factor(exp_bin, levels = 0:n, labels = c("Placebo", labels %||% paste0("Q", 1:n)))
}

# simple helpers ----------------------------------------------------------

#' Clopper-Pearson confidence interval for binary data
#'
#' Computes an exact binomial confidence interval for a proportion.
#'
#' @param x Number of successes
#' @param n Total number of trials
#' @param conf_level Confidence level
#'
#' @returns Named numeric vector, with confidence level stored as an attribute
#'
#' @details Used by the quantile-binned summary layer (see [er_plot_add_quantiles()])
#' to compute empirical response-rate confidence intervals. This assumes a
#' binary (0/1) response.
#'
#' @export
#' @examples
#' ci_clopper_pearson(1, 10)
#' 
ci_clopper_pearson <- function(x, n, conf_level = 0.95) {
  alpha <- 1 - conf_level
  lower <- if (x > 0) stats::qbeta(alpha/2, x, n - x + 1) else 0
  upper <- if (x < n) stats::qbeta(1 - alpha/2, x + 1, n - x) else 1
  ci <- c(lower = lower, upper = upper)
  attr(ci, "conf_level") <- conf_level
  return(ci)
}


#' t-interval confidence interval for the mean of continuous data
#'
#' Computes a t-distribution confidence interval for a sample mean.
#'
#' @param x Numeric vector of observations
#' @param conf_level Confidence level
#'
#' @returns Named numeric vector (`lower`, `upper`), with confidence level
#'   stored as an attribute. Returns `c(lower = NA, upper = NA)` if fewer
#'   than 2 non-missing values are supplied.
#'
#' @details Used by the quantile-binned summary layer (see
#'   [er_plot_add_quantiles()]) and [er_vpc_add_observed()]/
#'   [er_vpc_add_simulated()] to compute a confidence interval for the mean
#'   response within an exposure bin, for continuous (and, as an
#'   approximation, count) responses. This is the continuous-response
#'   analogue of [ci_clopper_pearson()]. `NA`s in `x` are dropped before
#'   computing the interval.
#'
#' @export
#' @examples
#' ci_t(rnorm(20))
#'
ci_t <- function(x, conf_level = 0.95) {
  x <- x[!is.na(x)]
  n <- length(x)
  if (n < 2) {
    ci <- c(lower = NA_real_, upper = NA_real_)
    attr(ci, "conf_level") <- conf_level
    return(ci)
  }
  alpha <- 1 - conf_level
  m <- mean(x)
  se <- stats::sd(x) / sqrt(n)
  t_crit <- stats::qt(1 - alpha / 2, df = n - 1)
  ci <- c(lower = m - t_crit * se, upper = m + t_crit * se)
  attr(ci, "conf_level") <- conf_level
  return(ci)
}


#' Exact Poisson confidence interval for a count rate
#'
#' Computes an exact Poisson confidence interval for a count rate.
#'
#' @param x Vector (or sum) of observed counts, e.g. all counts falling in
#'   one exposure bin
#' @param n Number of units the counts were accumulated over (e.g. the
#'   number of observations in the bin); the rate being estimated is
#'   `sum(x) / n`
#' @param conf_level Confidence level
#'
#' @returns Named numeric vector (`lower`, `upper`) for the rate `sum(x) / n`, with confidence level stored as an attribute.
#'
#' @details The count-response analogue of [ci_clopper_pearson()], used by
#'   the quantile-binned summary layer (see [er_plot_add_quantiles()])
#'   and [er_vpc_add_observed()]/[er_vpc_add_simulated()] when
#'   `response_type = "count"` is explicitly declared. Unlike [ci_t()]
#'   (the default, opt-in-required
#'   approximation used when a count response auto-detects or is declared
#'   `"continuous"`), this interval is exact and never produces a
#'   negative lower bound. Uses the standard exact ("Garwood") Poisson
#'   interval, derived from the chi-squared/gamma relationship; if the
#'   total count is 0, the lower bound is 0.
#'
#' @export
#' @examples
#' ci_poisson(3, 10)
#'
ci_poisson <- function(x, n, conf_level = 0.95) {
  total <- sum(x, na.rm = TRUE)
  alpha <- 1 - conf_level
  lower <- if (total > 0) stats::qgamma(alpha / 2, shape = total) / n else 0
  upper <- stats::qgamma(1 - alpha / 2, shape = total + 1) / n
  ci <- c(lower = lower, upper = upper)
  attr(ci, "conf_level") <- conf_level
  return(ci)
}


#' Distribution-free confidence interval for a sample quantile
#'
#' Computes a nonparametric confidence interval for a sample quantile using
#' the order-statistic method (Conover, *Practical Nonparametric
#' Statistics*): the interval endpoints are order statistics of `x`, chosen
#' via the binomial distribution of ranks so that no assumption is made
#' about the shape of `x`'s distribution.
#'
#' @param x Numeric vector of observations
#' @param prob Quantile probability (e.g. `0.1` for the tenth percentile)
#' @param conf_level Confidence level
#'
#' @returns Named numeric vector (`lower`, `upper`), with confidence level
#'   stored as an attribute. Returns `c(lower = NA, upper = NA)` if fewer
#'   than 2 non-missing values are supplied.
#'
#' @details Used by [er_vpc_add_observed()] to compute a confidence interval
#'   for each requested percentile of the observed response within an
#'   exposure bin (the observed-side analogue of the across-replicate
#'   percentile interval [er_vpc_add_simulated()] gets from simulated data,
#'   powering [er_style_vpc_observed_quantile_errorbar()]). Like
#'   [ci_clopper_pearson()], this interval is exact for its target coverage
#'   but conservative -- the discreteness of the binomial rank distribution
#'   means the achieved coverage can exceed the nominal `conf_level`,
#'   especially for a small bin or an extreme `prob`. The candidate rank
#'   indices are clipped to `[1, length(x)]`, so a very small or extreme-`prob`
#'   bin returns a (still valid, but wider-than-nominal) interval built from
#'   the most extreme order statistics available rather than `NA`.
#'
#' @export
#' @examples
#' ci_quantile(rnorm(100), prob = 0.1)
#'
ci_quantile <- function(x, prob = 0.5, conf_level = 0.95) {
  x <- sort(x[!is.na(x)])
  n <- length(x)
  if (n < 2) {
    ci <- c(lower = NA_real_, upper = NA_real_)
    attr(ci, "conf_level") <- conf_level
    return(ci)
  }
  alpha <- 1 - conf_level
  lo_idx <- max(1, stats::qbinom(alpha / 2, size = n, prob = prob))
  hi_idx <- min(n, stats::qbinom(1 - alpha / 2, size = n, prob = prob) + 1)
  ci <- c(lower = x[lo_idx], upper = x[hi_idx])
  attr(ci, "conf_level") <- conf_level
  return(ci)
}


#' Detect whether a response variable is binary or continuous
#'
#' @param x A vector (the response column)
#'
#' @returns `"binary"` if `x` is logical or takes only values in `{0, 1}`
#'   (ignoring `NA`s); `"continuous"` otherwise. A response with no
#'   non-missing values is treated as `"continuous"` (there's no evidence
#'   either way, and `"continuous"` is the more permissive default -- it
#'   doesn't restrict which plot layers can be used).
#'
#' @details Used by [er_plot()] to resolve `response_type = "auto"`.
#'
#' @noRd
.detect_response_type <- function(x) {
  if (is.logical(x)) return("binary")
  ux <- unique(x[!is.na(x)])
  if (length(ux) > 0 && all(ux %in% c(0, 1))) return("binary")
  return("continuous")
}


#' Cut a continuous variable into quantiles
#'
#' `cut_quantile()` bins a numeric vector into `n` quantile groups.
#' `cut_exposure_quantile()` does the same for an exposure variable,
#' additionally keeping placebo (`0`) observations in their own bin.
#'
#' @param x Numeric vector
#' @param n Number of bins
#' @param is_placebo Logical vector indicating placebo samples
#' @param ties Rule for assigning a value that sits exactly on an interior
#'   break point, where the bin membership would otherwise be ambiguous.
#'   `"upward"` (the default, matching prior behaviour) is equivalent to
#'   [cut()] with `right = TRUE`; `"downward"` is equivalent to `right =
#'   FALSE`; `"split-even"` randomly divides each tied group between its
#'   two candidate bins so that final bin sizes are as equal as possible,
#'   rather than sending every tied value the same direction.
#' @param seed Optional single number used to seed the random tie-break
#'   used by `ties = "split-even"` (ignored for `"upward"`/`"downward"`,
#'   which involve no randomness). `NULL` (the default) draws from the
#'   ambient RNG stream and so is not reproducible across calls; pass a
#'   seed for reproducible bin assignment.
#' @param quantile_type Integer between 1 and 9, passed straight through
#'   as [stats::quantile()]'s own `type` argument to compute the
#'   quantile break points. Defaults to `7`, matching
#'   [stats::quantile()]'s own default.
#' @param labeller Controls the labels used for the `n` quantile bins
#'   (`cut_exposure_quantile()`'s separate `"Placebo"` level is always
#'   used as-is, regardless of `labeller`). `NULL` (the default) labels
#'   bins `"Q1"`, `"Q2"`, etc. A function is called as `labeller(n,
#'   breaks)` (the actual bin count and the `n + 1` quantile cutpoints,
#'   after any resolution-driven fallback -- see `@details` below) and
#'   must return a character vector of length `n`; this is the hook for,
#'   e.g., range-style labels built from `breaks`. A character vector is
#'   used directly as the `n` labels.
#'
#' @returns A factor with `"ties"` and `"quantile_type"` attributes
#'   recording those two arguments. `cut_exposure_quantile()`'s result
#'   additionally carries a `"breaks"` attribute holding the `n + 1`
#'   quantile cutpoints used to form the bins.
#'
#' @details Both functions error if `x` has fewer than 2 distinct
#'   non-missing values, since quantile bins aren't well-defined in that
#'   case. If `x` doesn't have enough resolution to distinguish all `n`
#'   requested bins (e.g. many repeated values clustered at one end),
#'   both functions warn and fall back to using as many bins as the data
#'   supports, rather than erroring or silently showing fewer bins with
#'   no explanation. `cut_exposure_quantile()`'s `"breaks"` attribute is
#'   read back out by quantile-layer builders that draw bin-boundary
#'   separators (e.g. [er_style_quantile_errorbar_vlines()]) via
#'   `attr(exposure_bins, "breaks")`. Because that fallback can lower `n`
#'   below what was originally requested, a character-vector `labeller`
#'   is length-checked against the *actual* bin count, not the requested
#'   one, and errors informatively on a mismatch.
#'
#' @name cut_quantile
#' @examples
#' x <- rnorm(100)
#' cut_quantile(x)
#' cut_exposure_quantile(abs(x))
#' cut_quantile(x, ties = "split-even", seed = 8213)
#' cut_quantile(x, quantile_type = 1)
#' cut_quantile(x, labeller = function(n, breaks) paste0("Group ", 1:n))
#' cut_quantile(x, labeller = c("Low", "Mid-low", "Mid-high", "High"))
#' 
NULL

# Shared by both `cut_quantile()`/`cut_exposure_quantile()`: assigns each
# element of `x` to an integer bin (`1:n`, `NA` where `x` is missing or
# outside `range(breaks)`) according to the `ties` rule. `"upward"`/
# `"downward"` are direct `cut()` calls; `"split-even"` is handled by
# `.resolve_quantile_ties()` below.
#' @noRd
.cut_quantile_bin_num <- function(x, breaks, n, ties, seed = NULL) {
  switch(
    ties,
    upward = as.numeric(cut(x, breaks, labels = 1:n, include.lowest = TRUE)),
    downward = as.numeric(cut(x, breaks, labels = 1:n, right = FALSE, include.lowest = TRUE)),
    `split-even` = .resolve_quantile_ties(x, breaks, n, seed = seed)
  )
}

# `ties = "split-even"`'s implementation. Starts from the `"upward"`
# baseline (every tied value assigned to the lower of its two candidate
# bins), then, for each interior break in turn, randomly moves just
# enough of that break's tied group up into the higher bin to bring the
# cumulative count assigned so far as close as possible to an even split
# (`target_cum`, a largest-remainder-style allocation of `n_obs` into `n`
# roughly equal pieces) -- mirroring the equal-group-size goal of
# `dplyr::ntile()`, but breaking ties randomly rather than by row order.
# Only ties at a break point are ever moved; non-tied values keep the
# bin `cut()` already gave them. See AGENTS.md's "no automatic seed
# management" convention for why `seed` is opt-in only.
#' @noRd
.resolve_quantile_ties <- function(x, breaks, n, seed = NULL) {
  baseline <- as.numeric(cut(x, breaks, labels = 1:n, include.lowest = TRUE))
  if (n < 2) return(baseline)

  valid <- which(!is.na(baseline))
  n_obs <- length(valid)
  target_cum <- round((1:n) * n_obs / n)

  resolve <- function() {
    bin_num <- baseline
    for (j in 2:n) {
      brk <- breaks[j]
      tied <- valid[x[valid] == brk]
      if (length(tied) == 0) next
      count_below <- sum(x[valid] < brk)
      k_lower <- max(0, min(length(tied), target_cum[j - 1] - count_below))
      if (k_lower < length(tied)) {
        move_up <- sample(tied, size = length(tied) - k_lower)
        bin_num[move_up] <- j
      }
    }
    bin_num
  }

  if (!is.null(seed)) withr::with_seed(seed, resolve()) else resolve()
}

# Resolves `labeller` (`NULL`/function/character vector) into the
# character vector of `n` quantile-bin labels used by both
# `cut_quantile()`/`cut_exposure_quantile()`. `n`/`breaks` here are
# already post-fallback (i.e. the actual bin count/cutpoints used, not
# necessarily what the caller originally requested) -- see `?cut_quantile`'s
# `@details` for why a character-vector `labeller` is checked against
# this `n`, not the requested one.
#' @noRd
.resolve_quantile_labels <- function(labeller, n, breaks) {
  if (is.null(labeller)) return(paste0("Q", 1:n))

  labels <- if (is.function(labeller)) labeller(n, breaks) else labeller

  if (!is.character(labels) || length(labels) != n) {
    rlang::abort(c(
      sprintf(
        "`labeller` must produce %d label%s (the number of quantile bins actually used), not %d.",
        n, if (n == 1) "" else "s", length(labels)
      ),
      "i" = "If `x` doesn't have enough resolution for the originally requested number of bins, the actual bin count used can be lower than requested."
    ))
  }
  labels
}

#' @export
#' @rdname cut_quantile
cut_exposure_quantile <- function(x, n = 4, is_placebo = NULL,
                                   ties = c("upward", "downward", "split-even"),
                                   seed = NULL, quantile_type = 7, labeller = NULL) {
  ties <- match.arg(ties)
  if (is.null(is_placebo)) is_placebo <- x == 0
  non_placebo_x <- x[!is_placebo]
  n_distinct <- length(unique(non_placebo_x[!is.na(non_placebo_x)]))
  if (n_distinct < 2) {
    rlang::abort(c(
      sprintf(
        "Cannot compute exposure quantiles: found only %d distinct non-missing, non-placebo exposure value%s.",
        n_distinct, if (n_distinct == 1) "" else "s"
      ),
      "i" = "At least 2 distinct values are required to form quantile bins -- check for a constant, all-`NA`, or too-small exposure column."
    ))
  }
  breaks <- non_placebo_x |>
    stats::quantile(probs = (0:n)/n, na.rm = TRUE, type = quantile_type)

  # if the exposure column doesn't have enough resolution to distinguish
  # all `n` requested quantile bins (e.g. many repeated values clustered
  # at one end), `stats::quantile()` produces duplicate breaks -- passed
  # straight to `cut()`, this used to either crash with the opaque
  # `'breaks' are not unique` error, or (when only a few of the `n` bins
  # ended up genuinely occupied) silently show fewer bins than requested
  # once empty bins were dropped downstream, with no indication `n` was
  # too high for the data. Deduplicating breaks and reducing `n` to match
  # fixes the crash and lets this warn instead of failing.
  unique_breaks <- unique(breaks)
  n_actual <- length(unique_breaks) - 1
  if (n_actual < n) {
    rlang::warn(c(
      sprintf(
        "Requested %d exposure quantile bins, but only %d are distinguishable -- using %d instead.",
        n, n_actual, n_actual
      ),
      "i" = "The exposure column doesn't have enough distinct values (or resolution) to support this many quantile bins."
    ))
    breaks <- unique_breaks
    n <- n_actual
  }

  bin_num <- .cut_quantile_bin_num(x, breaks, n, ties, seed = seed)
  exp_bin <- dplyr::case_when(
    is_placebo ~ 0,
    is.na(x) ~ NA_real_,
    TRUE ~ bin_num
  )
  labels <- .resolve_quantile_labels(labeller, n, breaks)
  exp_quantile <- exp_bin |>
    factor(levels = 0:n, labels = c("Placebo", labels))
  attr(exp_quantile, "breaks") <- breaks
  attr(exp_quantile, "ties") <- ties
  attr(exp_quantile, "quantile_type") <- quantile_type
  return(exp_quantile)
}

#' @export
#' @rdname cut_quantile
cut_quantile <- function(x, n = 4,
                          ties = c("upward", "downward", "split-even"),
                          seed = NULL, quantile_type = 7, labeller = NULL) {
  ties <- match.arg(ties)
  n_distinct <- length(unique(x[!is.na(x)]))
  if (n_distinct < 2) {
    rlang::abort(c(
      sprintf(
        "Cannot compute quantiles: found only %d distinct non-missing value%s.",
        n_distinct, if (n_distinct == 1) "" else "s"
      ),
      "i" = "At least 2 distinct values are required to form quantile bins -- check for a constant, all-`NA`, or too-small variable."
    ))
  }
  breaks <- stats::quantile(x, probs = (0:n)/n, na.rm = TRUE, type = quantile_type)

  # see `cut_exposure_quantile()`'s equivalent step for the rationale --
  # a variable without enough resolution to distinguish all `n` requested
  # bins produces duplicate `quantile()` breaks, which used to either
  # crash `cut()` or silently show fewer bins than requested
  unique_breaks <- unique(breaks)
  n_actual <- length(unique_breaks) - 1
  if (n_actual < n) {
    rlang::warn(c(
      sprintf(
        "Requested %d quantile bins, but only %d are distinguishable -- using %d instead.",
        n, n_actual, n_actual
      ),
      "i" = "The variable doesn't have enough distinct values (or resolution) to support this many quantile bins."
    ))
    breaks <- unique_breaks
    n <- n_actual
  }

  bin_num <- .cut_quantile_bin_num(x, breaks, n, ties, seed = seed)
  labels <- .resolve_quantile_labels(labeller, n, breaks)
  bin_fct <- factor(bin_num, levels = 1:n, labels = labels)
  attr(bin_fct, "ties") <- ties
  attr(bin_fct, "quantile_type") <- quantile_type
  return(bin_fct)
}

#' Horizontally dodge stratified quantile-bin summaries
#'
#' Different strata share (near-)identical `x_mid` values within an
#' exposure bin (bins are quantile cutpoints of the shared exposure
#' variable), so plotting points/error bars/labels at `x_mid` unmodified
#' makes labels for different strata collide. This adds an
#' `x_dodge` column: `x_mid` plus a small, symmetric-around-`x_mid`,
#' per-stratum offset, sized relative to `exposure_limits` so it scales
#' sensibly across data sets and numbers of strata.
#'
#' @param summary A quantile summary data frame (`config$summary` from
#'   `.layer_quantile()`), with `x_mid` and `strata` columns.
#' @param exposure_limits Numeric vector of length 2, the exposure
#'   variable's `c(min, max)`.
#' @param dodge_width Spacing between adjacent strata's offsets, as a
#'   fraction of `exposure_limits`'s range. Default `0.05` -- see
#'   [er_plot_theme()]'s `dodge_width` argument, which is how a caller
#'   actually reaches this (this is a cross-layer, stratification-wide
#'   setting, not a per-builder argument -- see `?er_style_quantile`).
#' @return `summary` with an added `x_dodge` column.
#' @noRd
.dodge_quantile_strata <- function(summary, exposure_limits, dodge_width = 0.05) {

  strata_levels <- if (is.factor(summary$strata)) {
    levels(summary$strata)
  } else {
    sort(unique(summary$strata))
  }
  n_strata <- length(strata_levels)

  # spacing between adjacent strata's offsets, and the width of each
  # dodged error bar, both as a fixed fraction of the exposure range --
  # `dodge_width`'s default of 0.05 was chosen so a two-strata plot keeps
  # the errorbar width unchanged from the unstratified default
  # (0.025 * range) while still separating the two strata's centres by
  # twice that
  step <- dodge_width * (exposure_limits[2] - exposure_limits[1])
  offsets <- (seq_len(n_strata) - (n_strata + 1) / 2) * step
  names(offsets) <- strata_levels

  summary$x_dodge <- summary$x_mid + offsets[as.character(summary$strata)]
  return(summary)
}


#' Visual distance from a plot's raw data points to each of its 4 corners
#'
#' @details Rescales `data`'s exposure/response columns onto `[0, 1]`
#' using `exposure`/`response`'s own `limits`, then computes each point's
#' Euclidean distance to each of the 4 corners of the unit square,
#' returning the minimum (i.e. the closest a point comes to each corner --
#' a large value means that corner is uncrowded). Shared by
#' `.layer_summary()` (used to place the summary annotation in the
#' least-crowded corner) and `.layer_quantile()` (used by
#' `er_style_quantile_errorbar_vlines()`/`er_style_quantile_pointrange_vlines()`
#' to place boundary-vline labels in the *opposite* vertical half from
#' wherever a summary annotation would render, avoiding a collision
#' without either layer needing to know whether the other is present).
#'
#' @param data A data frame with the exposure/response columns.
#' @param exposure,response `er_plot` exposure/response variable lists
#'   (`name`, `limits`).
#' @returns A named numeric vector of length 4: `top_left`, `top_right`,
#'   `bottom_left`, `bottom_right`.
#' @noRd
.compute_corner_distance <- function(data, exposure, response) {

  exposure_lo <- exposure$limits[1]
  exposure_hi <- exposure$limits[2]
  response_lo <- response$limits[1]
  response_hi <- response$limits[2]

  data |>
    dplyr::select(dplyr::all_of(c(exposure$name, response$name))) |>
    dplyr::rename(y = dplyr::all_of(response$name), x = dplyr::all_of(exposure$name)) |>
    dplyr::mutate(
      x = (x - exposure_lo) / (exposure_hi - exposure_lo),
      y = (y - response_lo) / (response_hi - response_lo),
      tl_dist = sqrt(x^2 + (1 - y)^2),
      tr_dist = sqrt((1 - x)^2 + (1 - y)^2),
      bl_dist = sqrt(x^2 + y^2),
      br_dist = sqrt((1 - x)^2 + y^2)
    ) |>
    dplyr::summarise(
      top_left     = min(tl_dist, na.rm = TRUE),
      top_right    = min(tr_dist, na.rm = TRUE),
      bottom_left  = min(bl_dist, na.rm = TRUE),
      bottom_right = min(br_dist, na.rm = TRUE)
    ) |>
    unlist()
}


# globalVariables declarations -------------------------------------------

utils::globalVariables(c(
  ".er_tte_event",
  ".er_tte_strata",
  "n_event",
  "ci_lower",
  "ci_upper",
  "fit_resp",
  "fit_survival",
  "n1",
  "n0",
  "n_units",
  "x_mid",
  "x_median",
  "x_dodge",
  "y_mid",
  ".data",
  "Source",
  "y",
  "x",
  "lbl",
  "lvl",
  "tl_dist",
  "tr_dist",
  "bl_dist",
  "br_dist",
  "n",
  "id",
  "y_lwr_lbl",
  "y_upr_lbl",
  "y_lbl",
  "y_mid_lbl",
  "response",
  "strata_value",
  "med",
  "inner_lo",
  "inner_hi",
  "outer_lo",
  "outer_hi",
  "y_jitter",
  ".vpc_bin",
  ".vpc_stratum",
  "prob",
  "time",
  "surv",
  "lower",
  "upper",
  "xmax",
  "strata",
  "n_censor",
  "n_risk",
  ":="
))
