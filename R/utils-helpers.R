
`%||%` <- function(x, y) {
  if (is.null(x)) return(y)
  x
}

.get_label <- function(x) attr(x, "label")
.set_label <- function(x, lbl) {attr(x, "label") <- lbl; x}
.set_names <- function(x, nm) {names(x) <- nm; x}

# simple helpers ----------------------------------------------------------

#' Clopper-Pearson confidence interval for binary data
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
#' @param x Numeric vector of observations
#' @param conf_level Confidence level
#'
#' @returns Named numeric vector (`lower`, `upper`), with confidence level
#'   stored as an attribute. If fewer than 2 non-missing values are
#'   supplied, returns `c(lower = NA, upper = NA)` (a standard deviation --
#'   and hence a t-interval -- isn't defined for a single observation).
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
#' @param x Vector (or sum) of observed counts, e.g. all counts falling in
#'   one exposure bin
#' @param n Number of units the counts were accumulated over (e.g. the
#'   number of observations in the bin); the rate being estimated is
#'   `sum(x) / n`
#' @param conf_level Confidence level
#'
#' @returns Named numeric vector (`lower`, `upper`) for the rate `sum(x) /
#'   n`, with confidence level stored as an attribute. Uses the standard
#'   exact ("Garwood") Poisson interval, derived from the chi-squared/gamma
#'   relationship, rather than a normal approximation. If the total count
#'   is 0, the lower bound is 0 (there's no gamma quantile at `shape =
#'   0`).
#'
#' @details The count-response analogue of [ci_clopper_pearson()], used by
#'   the quantile-binned summary layer (see [er_plot_add_quantiles()])
#'   and [er_vpc_plot()] when `response_type = "count"` is explicitly
#'   declared. Unlike [ci_t()] (the default, opt-in-required
#'   approximation used when a count response auto-detects or is declared
#'   `"continuous"`), this interval is exact and never produces a
#'   negative lower bound -- see `PLAN.md` design decision (4) for the
#'   rationale and history.
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
#'   doesn't restrict which plot components can be used).
#'
#' @details Used by [er_plot()] to resolve `response_type = "auto"`. See
#'   `PLAN.md` for the broader plan to generalise response-type-specific
#'   plot components (quantile summaries, data strips, VPCs) beyond the
#'   binary case.
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
#' @param x Numeric vector
#' @param n Number of bins
#' @param is_placebo Logical vector indicating placebo samples
#'
#' @returns A factor. `cut_exposure_quantile()`'s result additionally
#'   carries a `"breaks"` attribute -- the `n + 1` quantile cutpoints
#'   (excluding placebo) used to form the bins, as computed by
#'   [stats::quantile()] -- which quantile-layer builders that draw
#'   bin-boundary separators (e.g. [er_style_quantile_errorbar_vlines()])
#'   read back out via `attr(exposure_bins, "breaks")`.
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
  breaks <- tibble::tibble(x, is_placebo) |>
    dplyr::filter(!is_placebo) |>
    dplyr::pull(x) |>
    stats::quantile(probs = (0:n)/n, na.rm = TRUE)
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
  breaks <- stats::quantile(x, probs = (0:n)/n, na.rm = TRUE)
  bin_num <- as.numeric(cut(x, breaks, labels = 1:n, include.lowest = TRUE))
  bin_fct <- factor(bin_num, levels = 1:n, labels = paste0("Q", 1:n)) 
  return(bin_fct)
}

#' Horizontally dodge stratified quantile-bin summaries
#'
#' Different strata share (near-)identical `x_mid` values within an
#' exposure bin (bins are quantile cutpoints of the shared exposure
#' variable), so plotting points/error bars/labels at `x_mid` unmodified
#' makes labels for different strata collide -- see `PLAN.md`,
#' "Stratified quantile labels can visually overlap". This adds an
#' `x_dodge` column: `x_mid` plus a small, symmetric-around-`x_mid`,
#' per-stratum offset, sized relative to `exposure_limits` so it scales
#' sensibly across data sets and numbers of strata.
#'
#' @param summary A quantile summary data frame (`config$summary` from
#'   `.part_quantile()`), with `x_mid` and `strata` columns.
#' @param exposure_limits Numeric vector of length 2, the exposure
#'   variable's `c(min, max)`.
#' @return `summary` with an added `x_dodge` column.
#' @noRd
.dodge_quantile_strata <- function(summary, exposure_limits) {

  strata_levels <- if (is.factor(summary$strata)) {
    levels(summary$strata)
  } else {
    sort(unique(summary$strata))
  }
  n_strata <- length(strata_levels)

  # spacing between adjacent strata's offsets, and the width of each
  # dodged error bar, both as a fixed fraction of the exposure range --
  # chosen so a two-strata plot keeps the errorbar width unchanged from
  # the unstratified default (0.025 * range) while still separating the
  # two strata's centres by twice that
  step <- 0.05 * (exposure_limits[2] - exposure_limits[1])
  offsets <- (seq_len(n_strata) - (n_strata + 1) / 2) * step
  names(offsets) <- strata_levels

  summary$x_dodge <- summary$x_mid + offsets[as.character(summary$strata)]
  return(summary)
}
