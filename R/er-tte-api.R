
#' The time-to-event plotting mini-language
#'
#' Create an `er_tte` specification for a Kaplan-Meier/survival-over-time
#' figure. This is a separate mini-grammar from [er_plot()]/[er_vpc()]:
#' those two share an exposure-response-vs-exposure coordinate system
#' (`er_predict()`'s contract is "response value at a given exposure"),
#' whereas `er_tte()` uses a time x-axis/survival-probability y-axis --
#' the natural coordinate system for a Kaplan-Meier curve, not something
#' `er_plot()`'s layers can express.
#'
#' @details
#' `er_tte()` computes the (single-arm) Kaplan-Meier estimate once, via
#' `survival::survfit()`, and stores the fit plus a tidy per-event-time
#' table (`time`, `n_risk`, `n_event`, `n_censor`, `surv`, `lower`,
#' `upper`) on `object$km`. Layers added afterwards (curve, censoring
#' marks, number-at-risk table, log-rank annotation, model overlay --
#' none of which exist yet at this stage of development) will read from
#' this shared fit rather than recomputing it.
#'
#' Unlike [er_plot()]/[er_vpc()], `time`/`event` accept arbitrary
#' tidy-eval expressions, not just bare column names -- time-to-event
#' data very commonly needs an inline transform to get an event
#' indicator (e.g. `status == 2` for a coded status variable, or
#' `!is.na(progression_date)`), and requiring the caller to first
#' `dplyr::mutate()` that column into existence would just be
#' boilerplate. The evaluated `time`/`event` vectors are stored as
#' `.er_tte_time`/`.er_tte_event` columns on `object$data`; their
#' `rlang::as_label()`-derived text is kept as `object$time$label`/
#' `object$event$label` for display purposes.
#'
#' `event` must evaluate to a logical vector (`TRUE` = event occurred)
#' or a numeric vector taking only the values `0` (censored) and `1`
#' (event) -- exactly the same binary encoding [er_plot()] requires of a
#' `response_type = "binary"` response.
#'
#' Stratification (splitting the Kaplan-Meier estimate by exposure
#' quantile or another grouping variable) is not yet implemented -- this
#' is a single-arm-only scaffold. It will be added as a `stratify_by`
#' argument in a later change, mirroring [er_vpc()]'s.
#'
#' @param data Data frame or tibble containing the observed data.
#' @param time Event/censoring time (unquoted expression, evaluated in
#'   `data`). Must be non-negative.
#' @param event Event indicator (unquoted expression, evaluated in
#'   `data`): `TRUE`/`1` for an event, `FALSE`/`0` for censoring.
#' @param conf_level Confidence level for the Kaplan-Meier confidence
#'   band. Must be strictly between 0 and 1.
#'
#' @returns An (empty of layers) plot object of class `er_tte`, with the
#'   single-arm Kaplan-Meier fit already computed on `object$km`.
#'
#' @examples
#' library(survival)
#' lung |>
#'   er_tte(time, status == 2)
#'
#' @seealso [er_model_interface]
#'
#' @name er_tte
NULL

# setup -----------------------------------------------------------------------

#' @rdname er_tte
#' @export
er_tte <- function(data, time, event, conf_level = 0.95) {

  # see `er_plot()`'s identical `dplyr::ungroup()` call for the rationale
  data <- dplyr::ungroup(data)

  # unlike `er_plot()`/`er_vpc()`'s `exposure`/`response`, `time`/`event`
  # accept arbitrary tidy-eval expressions (not just bare column names) --
  # see `?er_tte`'s details for why
  time_quo  <- rlang::enquo(time)
  event_quo <- rlang::enquo(event)
  time_label  <- rlang::as_label(time_quo)
  event_label <- rlang::as_label(event_quo)
  time_vals  <- rlang::eval_tidy(time_quo, data)
  event_vals <- rlang::eval_tidy(event_quo, data)

  if (length(time_vals) != nrow(data)) {
    rlang::abort(sprintf(
      "`time` (`%s`) must evaluate to a vector of length `nrow(data)` (%d), not %d.",
      time_label, nrow(data), length(time_vals)
    ))
  }
  if (length(event_vals) != nrow(data)) {
    rlang::abort(sprintf(
      "`event` (`%s`) must evaluate to a vector of length `nrow(data)` (%d), not %d.",
      event_label, nrow(data), length(event_vals)
    ))
  }

  # validate that time is numeric and non-negative -- without this, a
  # non-numeric/negative `time` fails deep inside `survival::Surv()` with
  # an opaque low-level error rather than a clear message naming the
  # actual problem
  if (!is.numeric(time_vals)) {
    rlang::abort(c(
      sprintf("`time` (`%s`) must be numeric, not %s.", time_label, paste(class(time_vals), collapse = "/")),
      "i" = "erplots' Kaplan-Meier estimation assumes a numeric time axis."
    ))
  }
  n_negative_time <- sum(!is.na(time_vals) & time_vals < 0)
  if (n_negative_time > 0) {
    rlang::abort(c(
      sprintf("`time` (`%s`) has %d negative value%s.", time_label, n_negative_time, if (n_negative_time == 1) "" else "s"),
      "i" = "A survival/censoring time cannot be negative."
    ))
  }

  # validate that event is a binary encoding -- mirrors `er_plot()`'s
  # `.validate_response_values()` check for `response_type = "binary"`,
  # but errors rather than warns: `survival::Surv()` has no sensible
  # fallback for an out-of-range event code the way the quantile layer's
  # rate calculation does for an out-of-range binary response
  if (!is.logical(event_vals)) {
    n_out_of_range <- sum(!is.na(event_vals) & !(event_vals %in% c(0, 1)))
    if (n_out_of_range > 0) {
      rlang::abort(c(
        sprintf(
          "`event` (`%s`) must be logical, or numeric with only values in {0, 1}, but %d value%s outside that range.",
          event_label, n_out_of_range, if (n_out_of_range == 1) " is" else "s are"
        ),
        "i" = "Pass an expression that evaluates to TRUE/FALSE or 0/1, e.g. `status == 2` for a coded status variable."
      ))
    }
  }
  event_vals <- as.logical(event_vals)

  if (!is.numeric(conf_level) || length(conf_level) != 1L || !is.finite(conf_level) || conf_level <= 0 || conf_level >= 1) {
    rlang::abort("`conf_level` must be a single number strictly between 0 and 1.")
  }

  n_missing <- sum(is.na(time_vals) | is.na(event_vals))
  if (n_missing > 0) {
    rlang::warn(sprintf(
      "%d row%s dropped from the Kaplan-Meier fit due to missing `time`/`event` value%s.",
      n_missing, if (n_missing == 1) "" else "s", if (n_missing == 1) "" else "s"
    ))
  }

  data[[".er_tte_time"]]  <- time_vals
  data[[".er_tte_event"]] <- event_vals

  n_distinct_time <- length(unique(time_vals[!is.na(time_vals) & !is.na(event_vals)]))
  if (n_distinct_time < 1) {
    rlang::abort("Cannot compute a Kaplan-Meier estimate: no non-missing `time`/`event` pairs remain.")
  }

  # single-arm Kaplan-Meier fit -- computed once, here, and shared by
  # every layer that reads `object$km` (none implemented yet)
  km_fit <- survival::survfit(
    survival::Surv(data[[".er_tte_time"]], data[[".er_tte_event"]]) ~ 1,
    conf.int = conf_level
  )

  object <- structure(
    list(
      data  = NULL,
      time  = .plot_variable(name = ".er_tte_time",  label = time_label,  role = "time"),
      event = .plot_variable(name = ".er_tte_event", label = event_label, role = "event"),
      strata = NULL, # reserved for a future `stratify_by` argument
      km = list(
        fit        = km_fit,
        table      = .tidy_survfit(km_fit),
        conf_level = conf_level
      ),
      layer = list(
        curve     = NULL,
        censor    = NULL,
        risktable = NULL,
        pvalue    = NULL,
        model     = NULL
      ),
      theme = list(),
      output = NULL
    ),
    class = "er_tte"
  )

  object$data <- data
  object$time$limits <- c(0, max(object$km$table$time, 0))

  object$theme$xlab <- object$time$label
  object$theme$ylab <- "Survival probability"
  object$theme$title <- NULL
  object$theme$subtitle <- NULL
  object$theme$caption <- NULL
  object$theme$format_percent <- scales::label_percent(accuracy = 1)
  object$theme$format_p <- scales::label_pvalue(accuracy = .001, add_p = TRUE)
  object$theme$theme_base <- ggplot2::theme_bw()
  object$theme$theme_extra <- ggplot2::theme(
    panel.border = ggplot2::element_rect(
      fill = NA,
      color = "grey80",
      linewidth = .5
    ),
    legend.position = "bottom"
  )
  object$theme$height <- list(curve = 6, risktable = 2)

  return(object)
}

# plot/print ------------------------------------------------------------------

#' @exportS3Method base::print
print.er_tte <- function(x, ...) {

  layer_set <- !purrr::map_lgl(x$layer, is.null)
  km_table <- x$km$table
  median_surv <- unname(summary(x$km$fit)$table["median"])

  cat("<er_tte>\n")
  cat("  tte variables:\n")
  cat("    - time:   ", x$time$label  %||% "<none>", "\n", sep = "")
  cat("    - event:  ", x$event$label %||% "<none>", "\n", sep = "")
  cat("  kaplan-meier fit (single-arm):\n")
  cat("    - n subjects:       ", x$km$fit$n, "\n", sep = "")
  cat("    - n events:         ", sum(km_table$n_event), "\n", sep = "")
  cat("    - median survival:  ", if (is.na(median_surv)) "not reached" else format(median_surv), "\n", sep = "")

  if (any(layer_set)) {
    cat("  plot layers:\n")
    if (layer_set["curve"])     cat("    - curve:      layer built\n", sep = "")
    if (layer_set["censor"])    cat("    - censor:     layer built\n", sep = "")
    if (layer_set["risktable"]) cat("    - risktable:  layer built\n", sep = "")
    if (layer_set["pvalue"])    cat("    - pvalue:     layer built\n", sep = "")
    if (layer_set["model"])     cat("    - model:      layer built\n", sep = "")
  } else {
    cat("  plot layers: <none>\n")
  }

  if (is.null(x$output))  cat("  output built: no")
  if (!is.null(x$output)) cat("  output built: yes")

  return(invisible(x))
}

#' @exportS3Method graphics::plot
plot.er_tte <- function(x, y = NULL, ...) {
  object <- er_tte_build(x)
  plot(object$output)
}


# top level build function ----------------------------------------------------

#' Build and render an `er_tte` object
#'
#' Assembles the layers into a single ggplot2 object. At this stage of
#' development no `er_tte_add_*()` layer verbs exist yet, so this always
#' renders a blank axes-only survival panel (time x-axis, survival
#' probability y-axis) -- the same "no layers yet" fallback
#' [er_plot_build()] uses.
#'
#' @param object Partially constructed plot (has S3 class `er_tte`).
#'
#' @returns The input `object`, with `object$output` (the composed
#'   ggplot2 plot) populated.
#'
#' @details
#' The user does not typically invoke this function directly. Instead, it
#' is called automatically when `plot()` is called.
#'
#' @seealso [er_tte()]
#'
#' @export
er_tte_build <- function(object) {
  if (!inherits(object, "er_tte")) rlang::abort("`object` must be an er_tte object")

  # no `er_tte_add_*()` verbs exist yet -- every build is currently the
  # "blank canvas" fallback; this will grow layer-by-layer the same way
  # `er_plot_build()`/`er_vpc_build()` do
  object$output <- .build_blank_tte_plot(object)

  return(object)
}


# internal helpers --------------------------------------------------------

# Tidies a single-arm (no `~ strata`) `survival::survfit()` object into a
# per-event-time data frame. `fit$lower`/`fit$upper` are already the
# confidence band the caller requested via `survfit(..., conf.int =)`, so
# no separate CI computation is needed here (unlike, say, `ci_t()`).
#' @noRd
.tidy_survfit <- function(fit) {
  tibble::tibble(
    time     = fit$time,
    n_risk   = fit$n.risk,
    n_event  = fit$n.event,
    n_censor = fit$n.censor,
    surv     = fit$surv,
    lower    = fit$lower,
    upper    = fit$upper
  )
}

# Blank axes-only survival panel: time on x (from `object$time$limits`,
# always starting at 0), survival probability on y (fixed to [0, 1] --
# unlike the response axis in `er_plot()`, a survival probability is
# always on this scale). Placeholder until `er_tte_add_curve()`/
# `er_style_tte_curve_km()` exist.
#' @noRd
.build_blank_tte_plot <- function(object) {
  ggplot2::ggplot() +
    ggplot2::xlim(object$time$limits) +
    ggplot2::ylim(0, 1) +
    ggplot2::labs(x = object$theme$xlab, y = object$theme$ylab) +
    object$theme$theme_base +
    object$theme$theme_extra
}
