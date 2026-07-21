test_that("er_builder_quantile_errorbar returns 3 geoms", {
  skip_if_not_installed("erglm")

  p1 <- er_plot(er_test_data, aucss, ae1)
  p2 <- er_plot(er_test_data, aucss, ae1, sex)

  expect_no_error(p1 |> er_plot_add_quantiles())
  expect_no_error(p2 |> er_plot_add_quantiles())

  p1 <- p1 |> er_plot_add_quantiles()
  p2 <- p2 |> er_plot_add_quantiles()

  args1 <- list(
    data = p1$data,
    config = p1$part$quantile$config,
    stratify = p1$part$quantile$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata = p1$strata,
    style = p1$style
  )
  args2 <- list(
    data = p2$data,
    config = p2$part$quantile$config,
    stratify = p2$part$quantile$stratify,
    exposure = p2$exposure,
    response = p2$response,
    strata = p2$strata,
    style = p2$style
  )

  expect_no_error(do.call(er_builder_quantile_errorbar, args1))
  expect_no_error(do.call(er_builder_quantile_errorbar, args2))

  p1_out <- do.call(er_builder_quantile_errorbar, args1)
  p2_out <- do.call(er_builder_quantile_errorbar, args2)

  expect_length(p1_out, 3)
  expect_length(p2_out, 3)

  expect_true(inherits(p1_out[[1]], "LayerInstance"))
  expect_true(inherits(p1_out[[2]], "LayerInstance"))
  expect_true(inherits(p1_out[[3]], "LayerInstance"))

  expect_true(inherits(p2_out[[1]], "LayerInstance"))
  expect_true(inherits(p2_out[[2]], "LayerInstance"))
  expect_true(inherits(p2_out[[3]], "LayerInstance"))
})

test_that("er_builder_quantile_errorbar dodges stratified points/bars/labels horizontally", {
  skip_if_not_installed("erglm")

  p2 <- er_plot(er_test_data, aucss, ae1, sex) |> er_plot_add_quantiles()

  args2 <- list(
    data = p2$data,
    config = p2$part$quantile$config,
    stratify = p2$part$quantile$stratify,
    exposure = p2$exposure,
    response = p2$response,
    strata = p2$strata,
    style = p2$style
  )

  p2_out <- do.call(er_builder_quantile_errorbar, args2)

  point_data <- p2_out[[1]]$data
  bar_data   <- p2_out[[2]]$data
  label_data <- p2_out[[3]]$data

  # a new x_dodge column is used for the plotted x position; the
  # underlying x_mid (from .part_quantile()'s config$summary) is untouched
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
  expect_equal(point_data$y_mid, p2$part$quantile$config$summary$y_mid)
})

test_that("er_builder_quantile_errorbar leaves x unmodified (no x_dodge column) when unstratified", {
  skip_if_not_installed("erglm")

  p1 <- er_plot(er_test_data, aucss, ae1) |> er_plot_add_quantiles()

  args1 <- list(
    data = p1$data,
    config = p1$part$quantile$config,
    stratify = p1$part$quantile$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata = p1$strata,
    style = p1$style
  )

  p1_out <- do.call(er_builder_quantile_errorbar, args1)
  expect_false("x_dodge" %in% names(p1_out[[1]]$data))
})

test_that("er_builder_quantile_errorbar returns 3 geoms for a continuous response", {
  skip_if_not_installed("erglm")

  p1 <- er_plot(er_test_data, aucss, biomarker_change)
  p2 <- er_plot(er_test_data, aucss, biomarker_change, sex)

  expect_no_error(p1 |> er_plot_add_quantiles())
  expect_no_error(p2 |> er_plot_add_quantiles())

  p1 <- p1 |> er_plot_add_quantiles()
  p2 <- p2 |> er_plot_add_quantiles()

  args1 <- list(
    data = p1$data,
    config = p1$part$quantile$config,
    stratify = p1$part$quantile$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata = p1$strata,
    style = p1$style
  )
  args2 <- list(
    data = p2$data,
    config = p2$part$quantile$config,
    stratify = p2$part$quantile$stratify,
    exposure = p2$exposure,
    response = p2$response,
    strata = p2$strata,
    style = p2$style
  )

  p1_out <- do.call(er_builder_quantile_errorbar, args1)
  p2_out <- do.call(er_builder_quantile_errorbar, args2)

  expect_length(p1_out, 3)
  expect_length(p2_out, 3)

  expect_true(inherits(p1_out[[1]], "LayerInstance"))
  expect_true(inherits(p1_out[[2]], "LayerInstance"))
  expect_true(inherits(p1_out[[3]], "LayerInstance"))

  expect_true(inherits(p2_out[[1]], "LayerInstance"))
  expect_true(inherits(p2_out[[2]], "LayerInstance"))
  expect_true(inherits(p2_out[[3]], "LayerInstance"))
})


test_that("er_builder_quantile_bar returns 3 geoms", {
  skip_if_not_installed("erglm")

  p1 <- er_plot(er_test_data, aucss, ae1)
  p2 <- er_plot(er_test_data, aucss, ae1, sex)

  expect_no_error(p1 |> er_plot_add_quantiles(builder = er_builder_quantile_bar))
  expect_no_error(p2 |> er_plot_add_quantiles(builder = er_builder_quantile_bar))

  p1 <- p1 |> er_plot_add_quantiles(builder = er_builder_quantile_bar)
  p2 <- p2 |> er_plot_add_quantiles(builder = er_builder_quantile_bar)

  expect_identical(p1$part$quantile$config$builder, er_builder_quantile_bar)
  expect_identical(p2$part$quantile$config$builder, er_builder_quantile_bar)

  args1 <- list(
    data = p1$data,
    config = p1$part$quantile$config,
    stratify = p1$part$quantile$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata = p1$strata,
    style = p1$style
  )
  args2 <- list(
    data = p2$data,
    config = p2$part$quantile$config,
    stratify = p2$part$quantile$stratify,
    exposure = p2$exposure,
    response = p2$response,
    strata = p2$strata,
    style = p2$style
  )

  expect_no_error(do.call(er_builder_quantile_bar, args1))
  expect_no_error(do.call(er_builder_quantile_bar, args2))

  p1_out <- do.call(er_builder_quantile_bar, args1)
  p2_out <- do.call(er_builder_quantile_bar, args2)

  expect_length(p1_out, 3)
  expect_length(p2_out, 3)

  expect_true(inherits(p1_out[[1]], "LayerInstance"))
  expect_true(inherits(p1_out[[2]], "LayerInstance"))
  expect_true(inherits(p1_out[[3]], "LayerInstance"))

  expect_true(inherits(p2_out[[1]], "LayerInstance"))
  expect_true(inherits(p2_out[[2]], "LayerInstance"))
  expect_true(inherits(p2_out[[3]], "LayerInstance"))
})

test_that("er_builder_quantile_bar dodges stratified bars/errorbars/labels horizontally", {
  skip_if_not_installed("erglm")

  p2 <- er_plot(er_test_data, aucss, ae1, sex) |>
    er_plot_add_quantiles(builder = er_builder_quantile_bar)

  args2 <- list(
    data = p2$data,
    config = p2$part$quantile$config,
    stratify = p2$part$quantile$stratify,
    exposure = p2$exposure,
    response = p2$response,
    strata = p2$strata,
    style = p2$style
  )

  p2_out <- do.call(er_builder_quantile_bar, args2)

  bar_data <- p2_out[[1]]$data
  expect_true("x_dodge" %in% names(bar_data))

  n_distinct_by_bin <- bar_data |>
    dplyr::summarise(n = dplyr::n_distinct(x_dodge), .by = "exposure_bins")
  expect_true(all(n_distinct_by_bin$n > 1))
})

test_that("er_builder_quantile_bar returns 3 geoms for a continuous response", {
  skip_if_not_installed("erglm")

  p1 <- er_plot(er_test_data, aucss, biomarker_change)
  p2 <- er_plot(er_test_data, aucss, biomarker_change, sex)

  p1 <- p1 |> er_plot_add_quantiles(builder = er_builder_quantile_bar)
  p2 <- p2 |> er_plot_add_quantiles(builder = er_builder_quantile_bar)

  args1 <- list(
    data = p1$data,
    config = p1$part$quantile$config,
    stratify = p1$part$quantile$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata = p1$strata,
    style = p1$style
  )
  args2 <- list(
    data = p2$data,
    config = p2$part$quantile$config,
    stratify = p2$part$quantile$stratify,
    exposure = p2$exposure,
    response = p2$response,
    strata = p2$strata,
    style = p2$style
  )

  p1_out <- do.call(er_builder_quantile_bar, args1)
  p2_out <- do.call(er_builder_quantile_bar, args2)

  expect_length(p1_out, 3)
  expect_length(p2_out, 3)

  expect_true(inherits(p1_out[[1]], "LayerInstance"))
  expect_true(inherits(p2_out[[1]], "LayerInstance"))
})

test_that("er_plot_add_quantiles() builds and renders with builder = er_builder_quantile_bar", {
  skip_if_not_installed("erglm")

  plt <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(er_test_mod1) |>
    er_plot_add_quantiles(builder = er_builder_quantile_bar)

  expect_no_error(er_plot_build(plt))
})


test_that("er_builder_quantile_pointrange returns 2 geoms", {
  skip_if_not_installed("erglm")

  p1 <- er_plot(er_test_data, aucss, ae1)
  p2 <- er_plot(er_test_data, aucss, ae1, sex)

  expect_no_error(p1 |> er_plot_add_quantiles(builder = er_builder_quantile_pointrange))
  expect_no_error(p2 |> er_plot_add_quantiles(builder = er_builder_quantile_pointrange))

  p1 <- p1 |> er_plot_add_quantiles(builder = er_builder_quantile_pointrange)
  p2 <- p2 |> er_plot_add_quantiles(builder = er_builder_quantile_pointrange)

  expect_identical(p1$part$quantile$config$builder, er_builder_quantile_pointrange)
  expect_identical(p2$part$quantile$config$builder, er_builder_quantile_pointrange)

  args1 <- list(
    data = p1$data,
    config = p1$part$quantile$config,
    stratify = p1$part$quantile$stratify,
    exposure = p1$exposure,
    response = p1$response,
    strata = p1$strata,
    style = p1$style
  )
  args2 <- list(
    data = p2$data,
    config = p2$part$quantile$config,
    stratify = p2$part$quantile$stratify,
    exposure = p2$exposure,
    response = p2$response,
    strata = p2$strata,
    style = p2$style
  )

  expect_no_error(do.call(er_builder_quantile_pointrange, args1))
  expect_no_error(do.call(er_builder_quantile_pointrange, args2))

  p1_out <- do.call(er_builder_quantile_pointrange, args1)
  p2_out <- do.call(er_builder_quantile_pointrange, args2)

  expect_length(p1_out, 2)
  expect_length(p2_out, 2)

  expect_true(inherits(p1_out[[1]], "LayerInstance"))
  expect_true(inherits(p1_out[[2]], "LayerInstance"))

  expect_true(inherits(p2_out[[1]], "LayerInstance"))
  expect_true(inherits(p2_out[[2]], "LayerInstance"))
})

test_that("er_plot_add_quantiles() builds and renders with builder = er_builder_quantile_pointrange", {
  skip_if_not_installed("erglm")

  plt <- er_test_data |>
    er_plot(aucss, ae1) |>
    er_plot_add_model(er_test_mod1) |>
    er_plot_add_quantiles(builder = er_builder_quantile_pointrange)

  expect_no_error(er_plot_build(plt))
})
