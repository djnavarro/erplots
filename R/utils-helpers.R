
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
#' @details Used by the quantile-binned summary layer (see [er_plot_show_quantiles()])
#' to compute empirical response-rate confidence intervals. This assumes a
#' binary (0/1) response.
#'
#' @export
#' @examples
#' clopper_pearson(1, 10)
#' 
clopper_pearson <- function(x, n, conf_level = 0.95) {
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
#'   [er_plot_show_quantiles()]) and `er_vpc_plot()` to compute a
#'   confidence interval for the mean response within an exposure bin, for
#'   continuous (and, as an approximation, count) responses. This is the
#'   continuous-response analogue of [clopper_pearson()]. `NA`s in `x` are
#'   dropped before computing the interval.
#'
#' @export
#' @examples
#' t_interval(rnorm(20))
#'
t_interval <- function(x, conf_level = 0.95) {
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


#' Abort with an informative error for components that don't support
#' continuous responses
#'
#' @param fn_name Name of the calling function, used in the error message
#' @param planned Logical. If `TRUE` (the default), the message frames
#'   this as a stopgap pending a planned generalisation (see `PLAN.md`,
#'   "Extend beyond binary responses"). If `FALSE`, the message instead
#'   frames this as a settled design decision with no continuous-response
#'   variant currently planned (used by [er_plot_show_datastrip()]; see
#'   `PLAN.md` Stage 3).
#'
#' @details Originally a stopgap guard rail shared by every component that
#'   hardcoded a binary (0/1) response assumption and would otherwise
#'   silently mis-plot a continuous response. The quantile summary layer
#'   and `er_vpc_plot()` have since been generalised to support continuous
#'   responses directly (PLAN.md Stages 1-2) and no longer call this
#'   helper. `er_plot_show_datastrip()` is the remaining caller: its
#'   "responders above the line, non-responders below" design is
#'   inherently binary-response, so (per PLAN.md's Stage 3 design
#'   decision) no continuous-response variant is currently planned, hence
#'   `planned = FALSE` there.
#'
#' @noRd
.abort_continuous_unsupported <- function(fn_name, planned = TRUE) {
  if (planned) {
    detail <- "See PLAN.md for the planned generalisation to continuous/count responses."
  } else {
    detail <- "No continuous-response variant of this component is currently planned; see PLAN.md."
  }
  rlang::abort(c(
    paste0("`", fn_name, "()` does not support continuous responses."),
    "i" = "Only binary (0/1, or logical) responses are currently supported by this component.",
    "i" = detail
  ))
}


#' Cut a continuous variable into quantiles
#'
#' @param x Numeric vector
#' @param n Number of bins
#' @param is_placebo Logical vector indicating placebo samples
#'
#' @returns A factor
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
