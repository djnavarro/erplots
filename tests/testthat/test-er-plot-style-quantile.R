test_that("er_style_quantile_errorbar returns 3 geoms", {
  p1 <- er_plot(er_test_data, aucss, ae1)
  p2 <- er_plot(er_test_data, aucss, ae1, sex)

  expect_no_error(p1 |> er_plot_add_quantiles())
  expect_no_error(p2 |> er_plot_add_quantiles())

  p1 <- p1 |> er_plot_add_quantiles()
  p2 <- p2 |> er_plot_add_quantiles()

  args1 <- list(
    data = p1$data,
    config = p1$layer$quantile$config,
    stratify = p1$layer$quantile$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata = p1$strata,
    theme = p1$theme
  )
  args2 <- list(
    data = p2$data,
    config = p2$layer$quantile$config,
    stratify = p2$layer$quantile$stratify,
    exposure = p2$exposure,
    response = p2$response,
    strata = p2$strata,
    theme = p2$theme
  )

  expect_no_error(do.call(er_style_quantile_errorbar, args1))
  expect_no_error(do.call(er_style_quantile_errorbar, args2))

  p1_out <- do.call(er_style_quantile_errorbar, args1)
  p2_out <- do.call(er_style_quantile_errorbar, args2)

  expect_length(p1_out, 3)
  expect_length(p2_out, 3)

  expect_true(inherits(p1_out[[1]], "LayerInstance"))
  expect_true(inherits(p1_out[[2]], "LayerInstance"))
  expect_true(inherits(p1_out[[3]], "LayerInstance"))

  expect_true(inherits(p2_out[[1]], "LayerInstance"))
  expect_true(inherits(p2_out[[2]], "LayerInstance"))
  expect_true(inherits(p2_out[[3]], "LayerInstance"))
})

test_that("er_style_quantile_errorbar dodges stratified points/bars/labels horizontally", {
  p2 <- er_plot(er_test_data, aucss, ae1, sex) |> er_plot_add_quantiles()

  args2 <- list(
    data = p2$data,
    config = p2$layer$quantile$config,
    stratify = p2$layer$quantile$stratify,
    exposure = p2$exposure,
    response = p2$response,
    strata = p2$strata,
    theme = p2$theme
  )

  p2_out <- do.call(er_style_quantile_errorbar, args2)

  point_data <- p2_out[[1]]$data
  bar_data   <- p2_out[[2]]$data
  label_data <- p2_out[[3]]$data

  # a new x_dodge column is used for the plotted x position; the
  # underlying x_mid (from .layer_quantile()'s config$summary) is untouched
  expect_true("x_dodge" %in% names(point_data))
  expect_true("x_dodge" %in% names(bar_data))
  expect_true("x_dodge" %in% names(label_data))
  expect_true("x_mid" %in% names(point_data))

  # within the same exposure bin, strata sharing (near-)identical x_mid
  # should nonetheless get distinct x_dodge positions
  n_distinct_by_bin <- point_data |>
    dplyr::summarise(n = dplyr::n_distinct(x_dodge), .by = "exposure_bins")
  expect_true(all(n_distinct_by_bin$n > 1))

  # dodging is symmetric around x_mid within each bin (offsets sum to
  # zero across strata) and doesn't touch y at all
  offsets <- point_data$x_dodge - point_data$x_mid
  expect_equal(mean(offsets), 0, tolerance = 1e-8)
  expect_equal(point_data$y_mid, p2$layer$quantile$config$summary$y_mid)
})

test_that("er_style_quantile_errorbar leaves x unmodified (no x_dodge column) when unstratified", {
  p1 <- er_plot(er_test_data, aucss, ae1) |> er_plot_add_quantiles()

  args1 <- list(
    data = p1$data,
    config = p1$layer$quantile$config,
    stratify = p1$layer$quantile$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata = p1$strata,
    theme = p1$theme
  )

  p1_out <- do.call(er_style_quantile_errorbar, args1)
  expect_false("x_dodge" %in% names(p1_out[[1]]$data))
})

test_that("er_style_quantile_errorbar returns 3 geoms for a continuous response", {
  p1 <- er_plot(er_test_data, aucss, biomarker_change)
  p2 <- er_plot(er_test_data, aucss, biomarker_change, sex)

  expect_no_error(p1 |> er_plot_add_quantiles())
  expect_no_error(p2 |> er_plot_add_quantiles())

  p1 <- p1 |> er_plot_add_quantiles()
  p2 <- p2 |> er_plot_add_quantiles()

  args1 <- list(
    data = p1$data,
    config = p1$layer$quantile$config,
    stratify = p1$layer$quantile$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata = p1$strata,
    theme = p1$theme
  )
  args2 <- list(
    data = p2$data,
    config = p2$layer$quantile$config,
    stratify = p2$layer$quantile$stratify,
    exposure = p2$exposure,
    response = p2$response,
    strata = p2$strata,
    theme = p2$theme
  )

  p1_out <- do.call(er_style_quantile_errorbar, args1)
  p2_out <- do.call(er_style_quantile_errorbar, args2)

  expect_length(p1_out, 3)
  expect_length(p2_out, 3)

  expect_true(inherits(p1_out[[1]], "LayerInstance"))
  expect_true(inherits(p1_out[[2]], "LayerInstance"))
  expect_true(inherits(p1_out[[3]], "LayerInstance"))

  expect_true(inherits(p2_out[[1]], "LayerInstance"))
  expect_true(inherits(p2_out[[2]], "LayerInstance"))
  expect_true(inherits(p2_out[[3]], "LayerInstance"))
})


test_that("er_style_quantile_pointrange returns 2 geoms", {
  p1 <- er_plot(er_test_data, aucss, ae1)
  p2 <- er_plot(er_test_data, aucss, ae1, sex)

  expect_no_error(p1 |> er_plot_add_quantiles(style = er_style_quantile_pointrange))
  expect_no_error(p2 |> er_plot_add_quantiles(style = er_style_quantile_pointrange))

  p1 <- p1 |> er_plot_add_quantiles(style = er_style_quantile_pointrange)
  p2 <- p2 |> er_plot_add_quantiles(style = er_style_quantile_pointrange)

  expect_identical(p1$layer$quantile$config$style, er_style_quantile_pointrange)
  expect_identical(p2$layer$quantile$config$style, er_style_quantile_pointrange)

  args1 <- list(
    data = p1$data,
    config = p1$layer$quantile$config,
    stratify = p1$layer$quantile$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata = p1$strata,
    theme = p1$theme
  )
  args2 <- list(
    data = p2$data,
    config = p2$layer$quantile$config,
    stratify = p2$layer$quantile$stratify,
    exposure = p2$exposure,
    response = p2$response,
    strata = p2$strata,
    theme = p2$theme
  )

  expect_no_error(do.call(er_style_quantile_pointrange, args1))
  expect_no_error(do.call(er_style_quantile_pointrange, args2))

  p1_out <- do.call(er_style_quantile_pointrange, args1)
  p2_out <- do.call(er_style_quantile_pointrange, args2)

  expect_length(p1_out, 2)
  expect_length(p2_out, 2)

  expect_true(inherits(p1_out[[1]], "LayerInstance"))
  expect_true(inherits(p1_out[[2]], "LayerInstance"))

  expect_true(inherits(p2_out[[1]], "LayerInstance"))
  expect_true(inherits(p2_out[[2]], "LayerInstance"))
})

test_that("er_plot_add_quantiles() builds and renders with style = er_style_quantile_pointrange", {
  plt <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(er_test_mod1) |>
    er_plot_add_quantiles(style = er_style_quantile_pointrange)

  expect_no_error(er_plot_build(plt))
})


test_that(".layer_quantile() stores interior quantile breaks in config$breaks", {
  p1 <- er_plot(er_test_data, aucss, ae1) |> er_plot_add_quantiles(bins = 4)

  breaks <- p1$layer$quantile$config$breaks
  expect_length(breaks, 5)
  expect_true(all(diff(breaks) >= 0))
})

test_that("er_style_quantile_errorbar_vlines adds a geom_vline at interior breaks", {
  p1 <- er_plot(er_test_data, aucss, ae1) |> er_plot_add_quantiles(bins = 4)

  args1 <- list(
    data = p1$data,
    config = p1$layer$quantile$config,
    stratify = p1$layer$quantile$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata = p1$strata,
    theme = p1$theme
  )

  expect_no_error(do.call(er_style_quantile_errorbar_vlines, args1))
  p1_out <- do.call(er_style_quantile_errorbar_vlines, args1)

  # vline, point, bar, label
  expect_length(p1_out, 4)
  expect_true(inherits(p1_out[[1]], "LayerInstance"))
  expect_s3_class(p1_out[[1]]$geom, "GeomVline")

  breaks <- p1$layer$quantile$config$breaks
  interior_breaks <- breaks[-c(1, length(breaks))]
  expect_equal(p1_out[[1]]$data$x, interior_breaks)
})

test_that("er_style_quantile_pointrange_vlines adds a geom_vline at interior breaks", {
  p1 <- er_plot(er_test_data, aucss, ae1) |> er_plot_add_quantiles(bins = 4)

  args1 <- list(
    data = p1$data,
    config = p1$layer$quantile$config,
    stratify = p1$layer$quantile$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata = p1$strata,
    theme = p1$theme
  )

  expect_no_error(do.call(er_style_quantile_pointrange_vlines, args1))
  p1_out <- do.call(er_style_quantile_pointrange_vlines, args1)

  # vline, pointrange, label
  expect_length(p1_out, 3)
  expect_true(inherits(p1_out[[1]], "LayerInstance"))
  expect_s3_class(p1_out[[1]]$geom, "GeomVline")
})

test_that("er_plot_add_quantiles() builds and renders with the _vlines builders", {
  plt1 <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(er_test_mod1) |>
    er_plot_add_quantiles(style = er_style_quantile_errorbar_vlines)
  expect_no_error(er_plot_build(plt1))

  plt2 <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(er_test_mod1) |>
    er_plot_add_quantiles(style = er_style_quantile_pointrange_vlines)
  expect_no_error(er_plot_build(plt2))
})

# ---- new arguments: point_size / errorbar_width / label_size ----

test_that("er_style_quantile_errorbar() respects point_size, errorbar_width, label_size overrides", {
  p1 <- er_plot(er_test_data, aucss, ae1) |> er_plot_add_quantiles()
  args <- list(
    data     = p1$data,
    config   = p1$layer$quantile$config,
    stratify = p1$layer$quantile$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata   = p1$strata,
    theme    = p1$theme
  )

  out_default <- do.call(er_style_quantile_errorbar, args)
  out_custom  <- do.call(er_style_quantile_errorbar,
                         c(args, list(point_size = 5, errorbar_width = 0.1, label_size = 6)))

  # point geom
  expect_equal(out_default[[1]]$aes_params$size, 2)
  expect_equal(out_custom[[1]]$aes_params$size, 5)

  # label geom
  expect_equal(out_default[[3]]$aes_params$size, 3)
  expect_equal(out_custom[[3]]$aes_params$size, 6)

  # errorbar width is exposure-range-scaled; default fraction is 0.025
  exp_range <- diff(p1$exposure$limits)
  expect_equal(out_default[[2]]$aes_params$width, 0.025 * exp_range)
  expect_equal(out_custom[[2]]$aes_params$width,  0.1   * exp_range)
})

test_that("er_style_quantile_errorbar() overrides also apply in the stratified branch", {
  p2 <- er_plot(er_test_data, aucss, ae1, sex) |> er_plot_add_quantiles()
  args <- list(
    data     = p2$data,
    config   = p2$layer$quantile$config,
    stratify = p2$layer$quantile$stratify,
    exposure = p2$exposure,
    response = p2$response,
    strata   = p2$strata,
    theme    = p2$theme
  )

  out_default <- do.call(er_style_quantile_errorbar, args)
  out_custom  <- do.call(er_style_quantile_errorbar,
                         c(args, list(point_size = 4, label_size = 5)))

  expect_equal(out_default[[1]]$aes_params$size, 2)
  expect_equal(out_custom[[1]]$aes_params$size, 4)
  expect_equal(out_default[[3]]$aes_params$size, 3)
  expect_equal(out_custom[[3]]$aes_params$size, 5)
})

test_that("er_style_quantile_errorbar_vlines() respects vline_colour and vline_linetype overrides", {
  p1 <- er_plot(er_test_data, aucss, ae1) |> er_plot_add_quantiles(bins = 4)
  args <- list(
    data     = p1$data,
    config   = p1$layer$quantile$config,
    stratify = p1$layer$quantile$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata   = p1$strata,
    theme    = p1$theme
  )

  out_default <- do.call(er_style_quantile_errorbar_vlines, args)
  out_custom  <- do.call(er_style_quantile_errorbar_vlines,
                         c(args, list(vline_colour = "blue", vline_linetype = "dashed")))

  # vline geom is the first element
  expect_equal(out_default[[1]]$aes_params$colour, "grey50")
  expect_equal(out_default[[1]]$aes_params$linetype, "dotted")
  expect_equal(out_custom[[1]]$aes_params$colour, "blue")
  expect_equal(out_custom[[1]]$aes_params$linetype, "dashed")
})

test_that("er_style_quantile_errorbar_vlines() forwards point_size / label_size to the inner builder", {
  p1 <- er_plot(er_test_data, aucss, ae1) |> er_plot_add_quantiles(bins = 4)
  args <- list(
    data     = p1$data,
    config   = p1$layer$quantile$config,
    stratify = p1$layer$quantile$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata   = p1$strata,
    theme    = p1$theme
  )

  out <- do.call(er_style_quantile_errorbar_vlines,
                 c(args, list(point_size = 5, label_size = 6)))

  # geom order: vline, point, errorbar, label
  expect_equal(out[[2]]$aes_params$size, 5)
  expect_equal(out[[4]]$aes_params$size, 6)
})

test_that("er_style_quantile_pointrange() respects label_size, pointrange_size, pointrange_linewidth", {
  p1 <- er_plot(er_test_data, aucss, ae1) |>
    er_plot_add_quantiles(style = er_style_quantile_pointrange)
  args <- list(
    data     = p1$data,
    config   = p1$layer$quantile$config,
    stratify = p1$layer$quantile$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata   = p1$strata,
    theme    = p1$theme
  )

  out_default <- do.call(er_style_quantile_pointrange, args)
  out_custom  <- do.call(er_style_quantile_pointrange,
                         c(args, list(label_size = 6, pointrange_size = 2,
                                      pointrange_linewidth = 1.5)))

  # label is the second geom
  expect_equal(out_default[[2]]$aes_params$size, 3)
  expect_equal(out_custom[[2]]$aes_params$size, 6)

  # pointrange size/linewidth: defaults are NULL (ggplot2's own defaults)
  expect_null(out_default[[1]]$aes_params$size)
  expect_equal(out_custom[[1]]$aes_params$size, 2)
  expect_null(out_default[[1]]$aes_params$linewidth)
  expect_equal(out_custom[[1]]$aes_params$linewidth, 1.5)
})

test_that("er_style_quantile_pointrange() label_size also applies in the stratified branch", {
  p2 <- er_plot(er_test_data, aucss, ae1, sex) |>
    er_plot_add_quantiles(style = er_style_quantile_pointrange)
  args <- list(
    data     = p2$data,
    config   = p2$layer$quantile$config,
    stratify = p2$layer$quantile$stratify,
    exposure = p2$exposure,
    response = p2$response,
    strata   = p2$strata,
    theme    = p2$theme
  )

  out_default <- do.call(er_style_quantile_pointrange, args)
  out_custom  <- do.call(er_style_quantile_pointrange, c(args, list(label_size = 7)))

  expect_equal(out_default[[2]]$aes_params$size, 3)
  expect_equal(out_custom[[2]]$aes_params$size, 7)
})

test_that("er_style_quantile_pointrange_vlines() forwards all new args and passes vline params", {
  p1 <- er_plot(er_test_data, aucss, ae1) |>
    er_plot_add_quantiles(bins = 4, style = er_style_quantile_pointrange_vlines)
  args <- list(
    data     = p1$data,
    config   = p1$layer$quantile$config,
    stratify = p1$layer$quantile$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata   = p1$strata,
    theme    = p1$theme
  )

  out <- do.call(er_style_quantile_pointrange_vlines,
                 c(args, list(label_size = 6, vline_colour = "red", vline_linetype = "dashed")))

  # geom order: vline, pointrange, label
  expect_equal(out[[1]]$aes_params$colour, "red")
  expect_equal(out[[1]]$aes_params$linetype, "dashed")
  expect_equal(out[[3]]$aes_params$size, 6)
})

# ---- vline_labels (issue #1) ----

test_that(".quantile_label_side() picks the vertical half opposite the least-crowded corner", {
  expect_equal(
    erplots:::.quantile_label_side(c(top_left = 0.1, top_right = 0.2, bottom_left = 0.3, bottom_right = 0.9)),
    "top"
  )
  expect_equal(
    erplots:::.quantile_label_side(c(top_left = 0.1, top_right = 0.2, bottom_left = 0.9, bottom_right = 0.3)),
    "top"
  )
  expect_equal(
    erplots:::.quantile_label_side(c(top_left = 0.9, top_right = 0.2, bottom_left = 0.3, bottom_right = 0.1)),
    "bottom"
  )
  expect_equal(
    erplots:::.quantile_label_side(c(top_left = 0.1, top_right = 0.9, bottom_left = 0.3, bottom_right = 0.2)),
    "bottom"
  )
})

test_that("vline_labels = FALSE (the default) leaves _vlines builders' output unchanged", {
  p1 <- er_plot(er_test_data, aucss, ae1) |> er_plot_add_quantiles(bins = 4)
  args <- list(
    data     = p1$data,
    config   = p1$layer$quantile$config,
    stratify = p1$layer$quantile$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata   = p1$strata,
    theme    = p1$theme
  )

  out_errorbar <- do.call(er_style_quantile_errorbar_vlines, args)
  expect_length(out_errorbar, 4) # vline, point, bar, label

  out_pointrange <- do.call(er_style_quantile_pointrange_vlines, args)
  expect_length(out_pointrange, 3) # vline, pointrange, label
})

test_that("vline_labels = TRUE adds a geom_label at the interior breaks", {
  p1 <- er_plot(er_test_data, aucss, ae1) |> er_plot_add_quantiles(bins = 4)
  args <- list(
    data     = p1$data,
    config   = p1$layer$quantile$config,
    stratify = p1$layer$quantile$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata   = p1$strata,
    theme    = p1$theme
  )

  out <- do.call(er_style_quantile_errorbar_vlines, c(args, list(vline_labels = TRUE)))
  expect_length(out, 5) # vline, point, bar, label, vline label

  label_layer <- out[[5]]
  expect_true(inherits(label_layer, "LayerInstance"))
  expect_s3_class(label_layer$geom, "GeomLabel")

  breaks <- p1$layer$quantile$config$breaks
  interior_breaks <- breaks[-c(1, length(breaks))]
  expect_equal(label_layer$data$x, unname(interior_breaks))
})

test_that("vline_label_position overrides the automatic top/bottom heuristic", {
  p1 <- er_plot(er_test_data, aucss, ae1) |> er_plot_add_quantiles(bins = 4)
  args <- list(
    data     = p1$data,
    config   = p1$layer$quantile$config,
    stratify = p1$layer$quantile$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata   = p1$strata,
    theme    = p1$theme
  )

  response_lo <- p1$response$limits[1]
  response_hi <- p1$response$limits[2]
  margin <- 0.05 * (response_hi - response_lo)

  out_top <- do.call(er_style_quantile_errorbar_vlines,
                      c(args, list(vline_labels = TRUE, vline_label_position = "top")))
  out_bottom <- do.call(er_style_quantile_errorbar_vlines,
                         c(args, list(vline_labels = TRUE, vline_label_position = "bottom")))

  expect_equal(unique(out_top[[5]]$data$y), response_hi - margin)
  expect_equal(unique(out_bottom[[5]]$data$y), response_lo + margin)
})

test_that("vline_label_size/vline_label_colour/vline_label_fill override defaults", {
  p1 <- er_plot(er_test_data, aucss, ae1) |> er_plot_add_quantiles(bins = 4)
  args <- list(
    data     = p1$data,
    config   = p1$layer$quantile$config,
    stratify = p1$layer$quantile$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata   = p1$strata,
    theme    = p1$theme
  )

  out <- do.call(er_style_quantile_errorbar_vlines, c(args, list(
    vline_labels = TRUE, vline_label_size = 6, vline_label_colour = "red", vline_label_fill = "yellow"
  )))
  label_layer <- out[[5]]
  expect_equal(label_layer$aes_params$size, 6)
  expect_equal(label_layer$aes_params$colour, "red")
  expect_equal(label_layer$aes_params$fill, "yellow")
})

test_that(".layer_summary()'s corner_distance output is unchanged after the .compute_corner_distance() extraction", {
  plt <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(er_test_mod1) |>
    er_plot_add_summary(er_test_mod1)

  expect_equal(names(plt$layer$summary$config$corner_distance), c("top_left", "top_right", "bottom_left", "bottom_right"))
  expect_true(all(plt$layer$summary$config$corner_distance >= 0))
})

test_that(".layer_quantile() also computes corner_distance", {
  plt <- er_test_data |> er_plot(aucss, ae1) |> er_plot_add_quantiles(bins = 4)
  expect_equal(names(plt$layer$quantile$config$corner_distance), c("top_left", "top_right", "bottom_left", "bottom_right"))
})

test_that("er_plot_add_quantiles() builds and renders with vline_labels = TRUE, with and without a summary layer", {
  plt <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(er_test_mod1) |>
    er_plot_add_summary(er_test_mod1) |>
    er_plot_add_quantiles(bins = 4, style = er_style_quantile_errorbar_vlines, vline_labels = TRUE)
  expect_no_error(er_plot_build(plt))

  plt_pointrange <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(er_test_mod1) |>
    er_plot_add_quantiles(bins = 4, style = er_style_quantile_pointrange_vlines, vline_labels = TRUE)
  expect_no_error(er_plot_build(plt_pointrange))

  plt_strat <- er_test_data |>
    er_plot(aucss, ae1, sex) |>
    er_plot_add_model(er_test_mod1) |>
    er_plot_add_quantiles(bins = 4, style = er_style_quantile_errorbar_vlines, vline_labels = TRUE) |>
    er_plot_add_summary(er_test_mod1)
  expect_no_error(er_plot_build(plt_strat))
})
