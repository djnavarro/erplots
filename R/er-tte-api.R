
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
#' `upper`) on `object$km`. Layers added afterwards -- the curve
#' ([er_tte_add_curve()]) and log-rank annotation ([er_tte_add_pvalue()])
#' so far; censoring marks, a number-at-risk table, and a model overlay
#' are not yet implemented -- read from this shared fit rather than
#' recomputing it.
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
#' Optional `stratify_by` splits the Kaplan-Meier estimate into one curve
#' per level, via `survival::survfit()`'s `~ strata` formula side --
#' mirroring [er_vpc()]'s `stratify_by`: a categorical variable is used
#' as-is; a numeric variable is automatically split into `n_strata`
#' quantile bins (via [cut_exposure_quantile()], so `0`/placebo is kept
#' in its own bin), with a message reporting that this happened. Unlike
#' `time`/`event`, `stratify_by` must be a bare column name (not an
#' arbitrary expression), matching `exposure`/`response`/`stratify_by`
#' elsewhere in the package. `object$km$table` gains a `strata` column
#' when stratified; `object$strata` (`var`/`label`/`type`/`n_strata`)
#' mirrors `er_vpc()`'s own `object$strata`.
#'
#' @param data Data frame or tibble containing the observed data.
#' @param time Event/censoring time (unquoted expression, evaluated in
#'   `data`). Must be non-negative.
#' @param event Event indicator (unquoted expression, evaluated in
#'   `data`): `TRUE`/`1` for an event, `FALSE`/`0` for censoring.
#' @param stratify_by Optional stratification variable (unquoted, bare
#'   column name). A categorical variable is used as-is; a numeric
#'   variable is split into `n_strata` quantile bins. Defaults to `NULL`
#'   (a single, unstratified curve).
#' @param n_strata Number of quantile bins, when `stratify_by` is
#'   numeric. Ignored when `stratify_by` is `NULL` or categorical.
#' @param conf_level Confidence level for the Kaplan-Meier confidence
#'   band. Must be strictly between 0 and 1.
#'
#' @returns An (empty of layers) plot object of class `er_tte`, with the
#'   Kaplan-Meier fit already computed on `object$km`.
#'
#' @examples
#' library(survival)
#' lung |>
#'   er_tte(time, status == 2)
#'
#' # `lung$sex` is coded numerically (1/2); convert to a factor first, or
#' # a numeric `stratify_by` is quantile-binned instead of used as-is
#' lung |>
#'   transform(sex = factor(sex, labels = c("Male", "Female"))) |>
#'   er_tte(time, status == 2, stratify_by = sex)
#'
#' @seealso [er_model_interface]
#'
#' @name er_tte
NULL

# setup -----------------------------------------------------------------------

#' @rdname er_tte
#' @export
er_tte <- function(data, time, event, stratify_by = NULL, n_strata = 4, conf_level = 0.95) {

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

  # unlike `time`/`event`, `stratify_by` must be a bare column name --
  # matches `exposure`/`response`/`stratify_by` elsewhere in the package,
  # since it's used for quantile-binning/faceting decisions rather than
  # evaluated as an arbitrary expression
  strata_quo <- rlang::enquo(stratify_by)
  strata_var <- if (rlang::quo_is_null(strata_quo)) NULL else rlang::as_name(strata_quo)

  if (!is.null(strata_var)) {
    if (!(strata_var %in% names(data))) {
      rlang::abort(sprintf("Column `%s` not found in `data`.", strata_var))
    }
    if (!is.numeric(n_strata) || length(n_strata) != 1L || !is.finite(n_strata) || n_strata < 1 || n_strata != round(n_strata)) {
      rlang::abort("`n_strata` must be a single positive whole number.")
    }
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

  strata_info <- NULL
  if (!is.null(strata_var)) {
    strata_info <- list()
    strata_info$var <- strata_var
    strata_info$label <- .get_label(data[[strata_var]]) %||% strata_var
    strata_info$type <- if (is.numeric(data[[strata_var]])) "continuous" else "discrete"
    strata_info$n_strata <- n_strata

    if (strata_info$type == "continuous") {
      # unlike `er_vpc()`'s `stratify_by` (which special-cases placebo,
      # i.e. `0`, only when `stratify_by` happens to be the exposure
      # variable itself), `er_tte()` has no dedicated exposure argument
      # to compare against -- so `stratify_by` never gets a separate
      # placebo bin here, regardless of its values
      data[[".er_tte_strata"]] <- cut_exposure_quantile(
        data[[strata_var]], n = n_strata, is_placebo = rep(FALSE, nrow(data))
      )
      rlang::inform(paste0(
        "`stratify_by` (`", strata_var, "`) is numeric; splitting into ", n_strata,
        " quantile bins. Pass a categorical variable to `stratify_by`, ",
        "or set `n_strata` to change the bin count."
      ))
    } else {
      data[[".er_tte_strata"]] <- factor(data[[strata_var]])
    }
  }

  # Kaplan-Meier fit -- computed once, here, and shared by every layer
  # that reads `object$km` (none implemented yet). `reformulate()` builds
  # `Surv(...) ~ 1` (single-arm) or `Surv(...) ~ .er_tte_strata`
  # (stratified) so both cases share one `survfit()` call.
  km_formula <- stats::reformulate(
    termlabels = if (is.null(strata_info)) "1" else ".er_tte_strata",
    response = "survival::Surv(.er_tte_time, .er_tte_event)"
  )
  km_fit <- survival::survfit(km_formula, data = data, conf.int = conf_level)

  object <- structure(
    list(
      data  = NULL,
      time  = .plot_variable(name = ".er_tte_time",  label = time_label,  role = "time"),
      event = .plot_variable(name = ".er_tte_event", label = event_label, role = "event"),
      strata = strata_info,
      km = list(
        fit        = km_fit,
        table      = .tidy_survfit(km_fit),
        summary    = .km_summary(km_fit),
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
  object$theme$draw_key <- ggplot2::draw_key_rect
  object$theme$height <- list(curve = 6, risktable = 2)

  return(object)
}

# plot/print ------------------------------------------------------------------

#' @exportS3Method base::print
print.er_tte <- function(x, ...) {

  layer_set <- !purrr::map_lgl(x$layer, is.null)
  km_summary <- x$km$summary

  cat("<er_tte>\n")
  cat("  tte variables:\n")
  cat("    - time:   ", x$time$label  %||% "<none>", "\n", sep = "")
  cat("    - event:  ", x$event$label %||% "<none>", "\n", sep = "")
  if (!is.null(x$strata)) {
    cat("    - stratify_by: ", x$strata$var, " (", x$strata$type, ")",
      if (x$strata$type == "continuous") paste0(", ", x$strata$n_strata, " bins") else "",
      "\n", sep = "")
  }

  if (is.null(x$strata)) {
    row <- km_summary[1, ]
    cat("  kaplan-meier fit (single-arm):\n")
    cat("    - n subjects:       ", row$n, "\n", sep = "")
    cat("    - n events:         ", row$n_event, "\n", sep = "")
    cat("    - median survival:  ", if (is.na(row$median)) "not reached" else format(row$median), "\n", sep = "")
  } else {
    cat("  kaplan-meier fit:\n")
    for (ii in seq_len(nrow(km_summary))) {
      row <- km_summary[ii, ]
      median_txt <- if (is.na(row$median)) "not reached" else format(row$median)
      cat("    - ", row$stratum, ": n=", row$n, ", events=", row$n_event, ", median=", median_txt, "\n", sep = "")
    }
  }

  if (any(layer_set)) {
    cat("  plot layers:\n")
    if (layer_set["curve"])     cat("    - curve:      layer built\n", sep = "")
    if (layer_set["censor"])    cat("    - censor:     layer built\n", sep = "")
    if (layer_set["risktable"]) cat("    - risktable:  layer built\n", sep = "")
    if (layer_set["pvalue"])    cat("    - pvalue:     log-rank ", x$theme$format_p(x$layer$pvalue$config$p_value), "\n", sep = "")
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
#' Assembles the layers into a single ggplot2 object: a blank axes-only
#' survival panel (time x-axis, survival probability y-axis), plus the
#' curve and pvalue layers' geoms, when present ([er_tte_add_curve()],
#' [er_tte_add_pvalue()]). Censoring marks, a number-at-risk table, and
#' a model overlay will be added the same way in future changes.
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
#' @seealso [er_tte()], [er_tte_add_curve()], [er_tte_add_pvalue()]
#'
#' @export
er_tte_build <- function(object) {
  if (!inherits(object, "er_tte")) rlang::abort("`object` must be an er_tte object")

  object$output <- .build_blank_tte_plot(object)

  if (!is.null(object$layer$curve)) {
    layer <- object$layer$curve
    geoms <- rlang::exec(
      layer$style,
      data = object$data,
      config = layer$config,
      stratify = !is.null(object$strata),
      time = object$time,
      strata = object$strata,
      theme = object$theme,
      !!!layer$dots
    )
    object$output <- object$output + geoms
  }

  if (!is.null(object$layer$pvalue)) {
    layer <- object$layer$pvalue
    geoms <- rlang::exec(
      layer$style,
      data = object$data,
      config = layer$config,
      stratify = !is.null(object$strata),
      time = object$time,
      strata = object$strata,
      theme = object$theme,
      !!!layer$dots
    )
    object$output <- object$output + geoms
  }

  object$output <- .polish_tte_labels(object, object$output)

  return(object)
}


# internal helpers --------------------------------------------------------

# Tidies a `survival::survfit()` object (single-arm or `~ strata`) into a
# per-event-time data frame. `fit$lower`/`fit$upper` are already the
# confidence band the caller requested via `survfit(..., conf.int =)`, so
# no separate CI computation is needed here (unlike, say, `ci_t()`). When
# stratified, `fit$strata` is a named integer vector (row counts per
# stratum, in the same order the flattened `fit$time`/etc. vectors are
# concatenated) -- `rep()`-ed out to one label per row and stripped of
# `survfit()`'s own `"variable=level"` prefix to match
# `object$strata`'s already-clean level labels (e.g. `cut_exposure_quantile()`'s
# `"Q1"`/`"Q2"`/... or a categorical column's own levels).
#' @noRd
.tidy_survfit <- function(fit) {
  tbl <- tibble::tibble(
    time     = fit$time,
    n_risk   = fit$n.risk,
    n_event  = fit$n.event,
    n_censor = fit$n.censor,
    surv     = fit$surv,
    lower    = fit$lower,
    upper    = fit$upper
  )
  if (!is.null(fit$strata)) {
    tbl$strata <- sub("^[^=]+=", "", rep(names(fit$strata), times = fit$strata))
  }
  tbl
}

# Per-stratum (or, unstratified, single-row) summary of a
# `survival::survfit()` fit: subject count, event count, and median
# survival time. Reused by `print.er_tte()` and (once implemented) the
# log-rank annotation layer, so it's computed once here rather than
# re-derived from `summary(fit)$table` at every call site.
#' @noRd
.km_summary <- function(fit) {
  tbl <- summary(fit)$table
  if (is.null(dim(tbl))) {
    tibble::tibble(
      stratum = NA_character_,
      n       = unname(fit$n),
      n_event = unname(tbl["events"]),
      median  = unname(tbl["median"])
    )
  } else {
    tibble::tibble(
      stratum = sub("^[^=]+=", "", rownames(tbl)),
      n       = unname(fit$n),
      n_event = unname(tbl[, "events"]),
      median  = unname(tbl[, "median"])
    )
  }
}

# Retitles a stratified layer's colour/fill legend with
# `object$strata$label` (e.g. `"sex"`) instead of the literal `"strata"`
# a builder like `er_style_tte_curve_km()` maps colour/fill to --
# `config$table`'s own `strata` column holds the already-cleaned
# stratum *level* labels (e.g. `"Male"`/`"Q1"`), not the original
# `stratify_by` variable's name, so a builder has no way to supply the
# right legend title itself. The TTE-grammar analogue of `er_plot()`'s
# `.polish_labels()` -- much narrower in scope, since `er_tte_build()`
# only ever produces one panel (no data/group panels to reconcile) and
# there's no `fill_role`-tagged builder (e.g. a hex-density overlay)
# whose `fill` means something other than strata to guard against here.
# Called unconditionally at the end of every `er_tte_build()` so it
# keeps working as more layers (censor/model) gain their own
# colour/fill-by-strata mappings; a no-op when unstratified.
#' @noRd
.polish_tte_labels <- function(object, plot) {
  if (is.null(object$strata)) return(plot)

  ll <- names(ggplot2::get_labs(plot))
  if ("colour" %in% ll) plot <- plot + ggplot2::labs(color = object$strata$label)
  if ("fill" %in% ll)   plot <- plot + ggplot2::labs(fill = object$strata$label)
  return(plot)
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
