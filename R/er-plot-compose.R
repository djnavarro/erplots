# composition/polishing steps -------------------------------------------------

.polish_margins <- function(object) {

  p <- object$plot

  margins <- ggplot2::margin(t = 5.5, r = 5.5, b = 5.5, l = 5.5, unit = "pt")
  zero_pt <- ggplot2::unit(0, "pt")

  base_mar <- margins
  panel_position <- object$part$data$config$panel_position %||% character(0)

  for (panel_name in names(p$data)) {
    panel_mar <- margins
    position <- panel_position[[panel_name]]
    if (identical(position, "above")) {
      base_mar[1] <- zero_pt
      panel_mar[3] <- zero_pt
    }
    if (identical(position, "below")) {
      base_mar[3] <- zero_pt
      panel_mar[1] <- zero_pt
    }
    p$data[[panel_name]] <- p$data[[panel_name]] + ggplot2::theme(margins = panel_mar)
  }

  p$base <- p$base + ggplot2::theme(margins = base_mar)
  if (!is.null(p$group)) {
    for(g in seq_along(p$group)) {
      p$group[[g]] + ggplot2::theme(margins = margins)
    }
  }

  return(p)
}

.polish_labels <- function(object) {
  p <- object$plot

  p$base <- p$base + ggplot2::labs(
    x = object$exposure$label,
    y = object$response$label
  )
  ll <- names(ggplot2::get_labs(p$base))
  if ("fill" %in% ll) p$base <- p$base + ggplot2::labs(fill = object$strata$label)
  if ("colour" %in% ll) p$base <- p$base + ggplot2::labs(color = object$strata$label)

  # the data layer's `colour` aesthetic means strata everywhere except
  # when `config$color_role == "response"` (continuous/count response;
  # see `PLAN.md`'s "Continuous-response data strip") -- there, `colour`
  # is the response value itself, so its label is the response's, not
  # the strata's. When that response-colored layer is also faceted by
  # stratum (more than one panel), each panel is tagged with its stratum
  # level via a plot title -- not the y-axis label, which patchwork's
  # `axes = "collect"` merges across all stacked panels (see
  # `er_plot_build()`), so a per-panel y-axis label would visually
  # overlap with the others rather than sit next to its own panel.
  data_color_role <- object$part$data$config$color_role %||% "strata"
  data_color_label <- if (identical(data_color_role, "response")) {
    object$response$label
  } else {
    object$strata$label
  }
  data_panel_names <- names(p$data)
  data_is_faceted <- identical(data_color_role, "response") && length(data_panel_names) > 1

  for (panel_name in data_panel_names) {
    p$data[[panel_name]] <- p$data[[panel_name]] + ggplot2::labs(
      x = object$exposure$label,
      y = NULL,
      title = if (data_is_faceted) panel_name else NULL
    )
    ll <- names(ggplot2::get_labs(p$data[[panel_name]]))
    if ("fill" %in% ll) p$data[[panel_name]] <- p$data[[panel_name]] + ggplot2::labs(fill = data_color_label)
    if ("colour" %in% ll) p$data[[panel_name]] <- p$data[[panel_name]] + ggplot2::labs(color = data_color_label)
  }

  if (!is.null(p$group)) {
    for(g in names(p$group)) {
      p$group[[g]] <- p$group[[g]] + ggplot2::labs(
        x = object$exposure$label,
        y = object$part$group$config[[g]]$y$label
      )
      ll <- names(ggplot2::get_labs(p$group[[g]]))
      if ("fill" %in% ll) p$group[[g]] <- p$group[[g]] + ggplot2::labs(fill = object$strata$label)
      if ("colour" %in% ll) p$group[[g]] <- p$group[[g]] + ggplot2::labs(color = object$strata$label)
    }
  }

  return(p)
}

.polish_arrangement <- function(object) {
  
  plot_list <- list()
  plot_info <- tibble::tibble(
    id = integer(),
    size = numeric(),
    plot = character(),
    name = character()
  )
  ind <- 0L

  data_panels <- names(object$plot$data)
  panel_position <- object$part$data$config$panel_position %||% character(0)
  above_panels <- data_panels[panel_position[data_panels] == "above"]
  below_panels <- data_panels[panel_position[data_panels] == "below"]

  # divide the data layer's total height budget evenly across however
  # many panels it has -- 2 for the binary upper/lower split (unchanged
  # from before), 1 for an unstratified continuous/count panel, or N for
  # an N-stratum continuous/count facet fallback (see `PLAN.md`'s
  # "Continuous-response data strip")
  data_panel_height <- object$style$height$data / max(length(data_panels), 1)

  for (panel_name in above_panels) {
    ind <- ind + 1L
    plot_list[[ind]] <- object$plot$data[[panel_name]]
    plot_info <- plot_info |> 
      tibble::add_row(
        id = ind,
        size = data_panel_height,
        plot = "data",
        name = paste0("data_", panel_name)
      )
  }

  ind <- ind + 1L
  plot_list[[ind]] <- object$plot$base
  plot_info <- plot_info |> 
    tibble::add_row(
      id = ind,
      size = object$style$height$base,
      plot = "base",
      name = "base"
    )

  for (panel_name in below_panels) {
    ind <- ind + 1L
    plot_list[[ind]] <- object$plot$data[[panel_name]]
    plot_info <- plot_info |> 
      tibble::add_row(
        id = ind,
        size = data_panel_height,
        plot = "data",
        name = paste0("data_", panel_name)
      )
  }
  
  if (!is.null(object$plot$group)) {
    group_n <- purrr::map_dbl(object$part$group$config, \(vv) vv$n_groups)
    group_prop <- group_n / sum(group_n)
    for(g in seq_along(object$plot$group)) {
      ind <- ind + 1L
      plot_list[[ind]] <- object$plot$group[[g]]
      plot_info <- plot_info |> 
        tibble::add_row(
          id = ind,
          size = object$style$height$group * group_prop[g],
          plot = "group",
          name = paste("group", g, sep = "_")
        )
    }
  }

  return(list(plots = plot_list, info = plot_info))
}

.polish_legends <- function(object, composition) {
  if (is.null(object$strata$name)) return(composition)
  has_strata <- purrr::map_lgl(object$part, \(x) x$stratify %||% FALSE)

  # the data layer's `stratify` flag drives per-stratum faceting (not a
  # shared color legend) whenever its color channel is already spoken
  # for by the response value (`color_role == "response"`, continuous/
  # count response) -- see `PLAN.md`'s "Stratification vs. the data
  # layer's color channel". Exclude it from strata-legend deduplication
  # in that case so each stratum panel keeps its own response colorbar.
  if (!is.null(object$part$data) && identical(object$part$data$config$color_role, "response")) {
    has_strata["data"] <- FALSE
  }

  if (!any(has_strata)) return(composition)
  stratified_parts <- names(has_strata[has_strata])
  stratified_plots <- dplyr::case_when(
    stratified_parts == "quantile" ~ "base",
    stratified_parts == "model" ~ "base",
    TRUE ~ stratified_parts
  )
  stratified_plots <- unique(stratified_plots)
  has_legend <- composition$info |>
    dplyr::filter(plot %in% stratified_plots) |> 
    dplyr::pull(id)
  if (length(has_legend) == 1L) return(composition)
  for(ind in 2:length(has_legend)) {
    composition$plots[[ind]] <- composition$plots[[ind]] + 
      ggplot2::guides(
        color = ggplot2::guide_none(),
        fill = ggplot2::guide_none()
      )
  }
  return(composition)
}

.polish_theme <- function(object, composition) {
  theme_fn <- object$style$theme_args
  for (ind in seq_along(composition$plots)) {
    composition$plots[[ind]] <- composition$plots[[ind]] + theme_fn()
  }
  return(composition)
}
