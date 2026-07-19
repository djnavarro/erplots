
#' Builds an exposure-response plot for a fitted model
#'
#' @param data Observed data
#' @param exposure Exposure variable (one variable, unquoted)
#' @param response Response variable (one variable, unquoted)
#' @param stratify_by Stratification variable used for color and fill (one variable, unquoted)
#' @param group_by Grouping variables to define groups for distribution plots (a tidyselection of variables)
#' @param keep_strata Logical, indicating whether this component should keep the color stratification
#' @param labels Named list of labels
#' @param bins Number of exposure bins (not counting placebo)
#' @param style Character string used to specify the partial builder for this component
#' @param panel Character string: "upper", "lower", or "both" (the default)
#' @param conf_level Confidence level
#' @param object Partially constructed plot (has S3 class `er_plot`)
#' @param model A fitted exposure-response model. Must implement [er_predict()];
#'   implementing [er_simulate()] and [er_summary()] enables additional
#'   visualisations (see [er_model_interface])
#'
#' @returns Plot object of class `er_plot`
#'
#' @examples
#' \dontrun{
#' library(erlr)
#' mod <- lr_model(ae1 ~ aucss, lr_data)
#'
#' lr_data |>
#'   er_plot(aucss, ae1) |>
#'   er_plot_show_model(mod) |>
#'   er_plot_show_quantiles() |>
#'   er_plot_show_groups(aucss) |>
#'   plot()
#'
#' mod2 <- lr_model(ae2 ~ aucss + sex, lr_data)
#' plt <- lr_data |>
#'   er_plot(aucss, ae2, stratify_by = sex) |>
#'   er_plot_show_model(mod2, keep_strata = FALSE) |>
#'   er_plot_show_quantiles() |>
#'   er_plot_show_datastrip() |>
#'   er_plot_show_groups(group_by = c(aucss, treatment), keep_strata = FALSE)
#'
#' print(plt)
#' plot(plt)
#' }
#'
#' @name er_plot
NULL


# setup -----------------------------------------------------------------------

#' @rdname er_plot
#' @export
er_plot <- function(data, exposure, response, stratify_by = NULL) {

  # empty plot object
  object <- structure(
    list(
      data  = NULL,
      exposure = .plot_variable(role = "exposure"),
      response = .plot_variable(role = "response"),
      strata = .plot_variable(role = "strata"),
      part = list(
        model    = NULL, 
        quantile = NULL, 
        strip    = NULL,
        group    = NULL
      ),
      plot = list(
        base = NULL, 
        strip = NULL, 
        group = NULL
      ),
      style = list(),
      output = NULL 
    ),
    class = "er_plot"
  )

  # store observed data
  object$data <- data

  # store variable names
  object$exposure$name <- rlang::as_name(rlang::enquo(exposure))
  object$response$name <- rlang::as_name(rlang::enquo(response)) 
  strata_name <- rlang::enquo(stratify_by)
  if (!rlang::quo_is_null(strata_name)) object$strata$name <- rlang::as_name(strata_name)
  
  # store (default) variable labels
  object$exposure$label <- .get_label(object$data[[object$exposure$name]]) %||% object$exposure$name
  object$response$label <- .get_label(object$data[[object$response$name]]) %||% object$response$name    
  if (!is.null(object$strata$name)) {
    object$strata$label <- .get_label(object$data[[object$strata$name]]) %||% object$strata$name
  }

  # store limits
  object$exposure$limits <- range(object$data[[object$exposure$name]])
  object$response$limits <- c(0, 1)
  if (!is.null(object$strata$name)) {
    object$strata$limits <- unique(object$data[[object$strata$name]])
  }

  # stylistic information
  object$style$format_p <- scales::label_pvalue(accuracy = .001, add_p = TRUE)
  object$style$format_percent <- scales::label_percent(accuracy = 1)
  object$style$height <- list(base = 6, strip = 2, group = 3) 
  object$style$theme_base <- function() ggplot2::theme_bw()
  object$style$theme_args <- function() {
    ggplot2::theme(
      panel.border = ggplot2::element_rect(
        fill = NA, 
        color = "grey80", 
        linewidth = .5
      ),
      legend.position = "bottom"
    ) 
  }
  object$style$draw_key <- ggplot2::draw_key_rect
 
  return(object)
}

#' @rdname er_plot
#' @export
er_plot_style <- function(object, labels) {

  # TODO: flesh this out so that users can modify style, labels, etc

  return(object)
}


# model -----------------------------------------------------------------------

#' @rdname er_plot
#' @export
er_plot_show_model <- function(object, model, keep_strata = NULL, style = "ribbonline", conf_level = 0.95) {

  if (!inherits(object, "er_plot")) rlang::abort("`object` must be an er_plot object")
  if (is.null(keep_strata)) keep_strata <- !is.null(object$strata$name)

  object$part$model <- .part_model(
    object = object, 
    model = model,
    stratify = keep_strata, 
    style = style, 
    conf_level = conf_level
  )
  
  return(object)
}


# quantiles -------------------------------------------------------------------

#' @rdname er_plot
#' @export
er_plot_show_quantiles <- function(object, keep_strata = NULL, style = "errorbar", bins = 4, conf_level = 0.95) {

  if (!inherits(object, "er_plot")) rlang::abort("`object` must be an er_plot object")
  if (is.null(keep_strata)) keep_strata <- !is.null(object$strata$name)
  
  object$part$quantile <- .part_quantile(
    object = object,
    stratify = keep_strata,
    style = style,
    bins = bins,
    conf_level = conf_level
  )
  
  return(object)
}


# strips ----------------------------------------------------------------------

#' @rdname er_plot
#' @export
er_plot_show_datastrip <- function(object, keep_strata = NULL, style = "jitter", panel = "both") {

  if (!inherits(object, "er_plot")) rlang::abort("`object` must be an er_plot object")
  if (is.null(keep_strata)) keep_strata <- !is.null(object$strata$name)

  object$part$strip <- .part_strip(
    object = object,
    stratify = keep_strata, 
    style = style,
    panel = panel
  )

  return(object)  
}


# groups plot -----------------------------------------------------------------

#' @rdname er_plot
#' @export
er_plot_show_groups <- function(object, group_by, style = "boxplot", bins = NULL, keep_strata = NULL) {

  if (!inherits(object, "er_plot")) rlang::abort("`object` must be an er_plot object")
  if (is.null(keep_strata)) keep_strata <- !is.null(object$strata$name)
  group_cols <- tidyselect::eval_select(rlang::enquo(group_by), object$data) 
  group_cols <- names(group_cols)

  object$part$group <- .part_group(
    object = object,
    group_cols = group_cols, 
    stratify = keep_strata, 
    style = style,
    bins = bins
  )

  return(object)  
}


# plot/print ------------------------------------------------------------------

#' @exportS3Method base::print
print.er_plot <- function(x, ...) {

  part_set <- !purrr::map_lgl(x$part, is.null)
  plot_set <- !purrr::map_lgl(x$plot, is.null)

  cat("<er_plot>\n")
  cat("  plot variables:\n")
  cat("    - exposure:        ", x$exposure$name  %||% "<none>", "\n", sep = "")
  cat("    - response:        ", x$response$name  %||% "<none>", "\n", sep = "")
  cat("    - stratification:  ", x$strata$name    %||% "<none>", "\n", sep = "")
  
  if (any(part_set)) {
    cat("  plot components:\n")
    if (part_set["model"])    cat("    - model:           ", paste(class(x$part$model$config$model), collapse = "/"), "\n", sep = "")
    if (part_set["quantile"]) cat("    - quantile:        ", x$part$quantile$config$n_quantiles, " bins\n", sep = "")
    if (part_set["strip"])    cat("    - strip:           ", x$part$strip$config$style, " ", x$part$strip$config$panel, "\n", sep = "")
    if (part_set["group"])    cat("    - group:           ", paste(names(x$part$group$config), collapse = ", "), "\n", sep = "")
  } else {
    cat("  plot components: <none>\n")
  }

  if (any(plot_set)) {
    cat("  plots built:\n")
    if (plot_set["base"])   cat("    - model\n", sep = "")
    if (plot_set["strip"])  cat("    - strip\n", sep = "")
    if (plot_set["group"])  cat("    - group\n", sep = "")
  } else {
    cat("  plots built: <none>\n")
  }

  if (is.null(x$output))  cat("  output built: no")
  if (!is.null(x$output)) cat("  output built: yes")
  
  return(invisible(x))
}

#' @exportS3Method graphics::plot
plot.er_plot <- function(x, y = NULL, ...) {
  object <- er_plot_build(x)
  plot(object$output)
}


# top level build function ----------------------------------------------------

#' @rdname er_plot
#' @export
er_plot_build <- function(object) {
  if (!inherits(object, "er_plot")) rlang::abort("`object` must be an er_plot object")
  
  # build
  if (!is.null(object$part$model) | !is.null(object$part$quantile)) object$plot$base <- .build_base_plot(object)
  if (!is.null(object$part$strip)) object$plot$strip <- .build_strip_plot(object)
  if (!is.null(object$part$group)) object$plot$group <- .build_group_plot(object)

  # polish
  object$plot <- .polish_margins(object)
  object$plot <- .polish_labels(object)
  composition <- .polish_arrangement(object)
  composition <- .polish_legends(object, composition)
  composition <- .polish_theme(object, composition)

  # output
  if (length(composition$heights) == 1) {
    object$output <- object$plot$base
  } else {
    object$output <- patchwork::wrap_plots(
      composition$plots, 
      ncol = 1, 
      heights = composition$info$size,
      guides = "collect",
      axes = "collect"
    ) + patchwork::plot_annotation(
      theme = object$style$theme_args()
    )
  }

  return(object)
}
