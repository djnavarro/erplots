
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


#' Abort with an informative error for components that don't yet support
#' continuous responses
#'
#' @param fn_name Name of the calling function, used in the error message
#'
#' @details A stopgap guard rail: several plot components (the quantile
#'   summary layer, the data strip, `er_vpc_plot()`) still hardcode a
#'   binary (0/1) response assumption and will silently mis-plot rather
#'   than error if given a continuous response. This helper turns that
#'   silent failure into an explicit one until each component is
#'   generalised (see `PLAN.md`, "Extend beyond binary responses").
#'
#' @noRd
.abort_continuous_unsupported <- function(fn_name) {
  rlang::abort(c(
    paste0("`", fn_name, "()` does not yet support continuous responses."),
    "i" = "Only binary (0/1, or logical) responses are currently supported by this component.",
    "i" = "See PLAN.md for the planned generalisation to continuous/count responses."
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
