
`%||%` <- function(x, y) {
  if (is.null(x)) return(y)
  x
}

# Errors informatively if any element of `dots` (an already-captured
# `rlang::list2(...)`) is unnamed. Extra arguments passed through
# `er_plot_add_*()`'s `...` to a builder are spliced in positionally
# after the seven standard builder arguments (see `?er_style`'s
# "Passing extra arguments to a builder" section), so an unnamed one
# would silently bind to the wrong parameter rather than reaching a
# builder's own `...` -- this catches that at the call site instead.
#' @noRd
.check_dots_named <- function(dots) {
  if (length(dots) == 0) return(invisible(NULL))
  nms <- names(dots)
  if (is.null(nms) || any(!nzchar(nms))) {
    rlang::abort(c(
      "All arguments passed via `...` must be named.",
      "i" = "These are forwarded to a builder alongside `data`/`config`/etc, so an unnamed argument would bind to the wrong parameter."
    ))
  }
  invisible(NULL)
}

.get_label <- function(x) attr(x, "label")
.set_label <- function(x, lbl) {attr(x, "label") <- lbl; x}
.set_names <- function(x, nm) {names(x) <- nm; x}

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
#'   [er_plot_add_quantiles()]) and `er_vpc_plot()` to compute a
#'   confidence interval for the mean response within an exposure bin, for
#'   continuous (and, as an approximation, count) responses. This is the
#'   continuous-response analogue of [ci_clopper_pearson()]. `NA`s in `x` are
#'   dropped before computing the interval.
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
#'   and [er_vpc_plot()] when `response_type = "count"` is explicitly
#'   declared. Unlike [ci_t()] (the default, opt-in-required
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
#'
#' @returns A factor. `cut_exposure_quantile()`'s result additionally
#'   carries a `"breaks"` attribute holding the `n + 1` quantile
#'   cutpoints used to form the bins.
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
#'   `attr(exposure_bins, "breaks")`.
#'
#' @name cut_quantile
#' @examples
#' x <- rnorm(100)
#' cut_quantile(x)
#' cut_exposure_quantile(abs(x))
#' 
NULL

#' @export
#' @rdname cut_quantile
cut_exposure_quantile <- function(x, n = 4, is_placebo = NULL) {
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
    stats::quantile(probs = (0:n)/n, na.rm = TRUE)

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

  exp_bin <- as.numeric(dplyr::case_when(
    is_placebo ~ "0",
    is.na(x) ~ NA_character_,
    TRUE ~ cut(x, breaks, labels = 1:n, include.lowest = TRUE)
  ))
  exp_quantile <- exp_bin |>
    factor(levels = 0:n, labels = c("Placebo", paste0("Q", 1:n)))  
  attr(exp_quantile, "breaks") <- breaks
  return(exp_quantile)
}

#' @export
#' @rdname cut_quantile
cut_quantile <- function(x, n = 4) {
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
  breaks <- stats::quantile(x, probs = (0:n)/n, na.rm = TRUE)

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

  bin_num <- as.numeric(cut(x, breaks, labels = 1:n, include.lowest = TRUE))
  bin_fct <- factor(bin_num, levels = 1:n, labels = paste0("Q", 1:n)) 
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


# globalVariables declarations -------------------------------------------

utils::globalVariables(c(
  "ci_lower",
  "ci_upper",
  "fit_resp",
  "n1",
  "n0",
  "n_units",
  "x_mid",
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
  ":="
))
