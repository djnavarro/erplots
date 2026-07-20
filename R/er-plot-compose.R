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

  for (panel_name in names(p$data)) {
    p$data[[panel_name]] <- p$data[[panel_name]] + ggplot2::labs(
      x = object$exposure$label,
      y = NULL
    )
    ll <- names(ggplot2::get_labs(p$data[[panel_name]]))
    if ("fill" %in% ll) p$data[[panel_name]] <- p$data[[panel_name]] + ggplot2::labs(fill = object$strata$label)
    if ("colour" %in% ll) p$data[[panel_name]] <- p$data[[panel_name]] + ggplot2::labs(color = object$strata$label)
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

  for (panel_name in above_panels) {
    ind <- ind + 1L
    plot_list[[ind]] <- object$plot$data[[panel_name]]
    plot_info <- plot_info |> 
      tibble::add_row(
        id = ind,
        size = object$style$height$data / 2,
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
        size = object$style$height$data / 2,
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
