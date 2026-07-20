test_that("build_quantile_errorbar returns 3 geoms", {
  skip_if_not_installed("erglm")

  p1 <- er_plot(er_test_data, aucss, ae1)
  p2 <- er_plot(er_test_data, aucss, ae1, sex)

  expect_no_error(p1 |> er_plot_show_quantiles(style = "errorbar"))
  expect_no_error(p2 |> er_plot_show_quantiles(style = "errorbar"))

  p1 <- p1 |> er_plot_show_quantiles(style = "errorbar")
  p2 <- p2 |> er_plot_show_quantiles(style = "errorbar")

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

  expect_no_error(do.call(build_quantile_errorbar, args1))
  expect_no_error(do.call(build_quantile_errorbar, args2))

  p1_out <- do.call(build_quantile_errorbar, args1)
  p2_out <- do.call(build_quantile_errorbar, args2)

  expect_length(p1_out, 3)
  expect_length(p2_out, 3)

  expect_true(inherits(p1_out[[1]], "LayerInstance"))
  expect_true(inherits(p1_out[[2]], "LayerInstance"))
  expect_true(inherits(p1_out[[3]], "LayerInstance"))

  expect_true(inherits(p2_out[[1]], "LayerInstance"))
  expect_true(inherits(p2_out[[2]], "LayerInstance"))
  expect_true(inherits(p2_out[[3]], "LayerInstance"))
})

test_that("build_quantile_errorbar returns 3 geoms for a continuous response", {
  skip_if_not_installed("erglm")

  p1 <- er_plot(er_test_data, aucss, biomarker_change)
  p2 <- er_plot(er_test_data, aucss, biomarker_change, sex)

  expect_no_error(p1 |> er_plot_show_quantiles(style = "errorbar"))
  expect_no_error(p2 |> er_plot_show_quantiles(style = "errorbar"))

  p1 <- p1 |> er_plot_show_quantiles(style = "errorbar")
  p2 <- p2 |> er_plot_show_quantiles(style = "errorbar")

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

  p1_out <- do.call(build_quantile_errorbar, args1)
  p2_out <- do.call(build_quantile_errorbar, args2)

  expect_length(p1_out, 3)
  expect_length(p2_out, 3)

  expect_true(inherits(p1_out[[1]], "LayerInstance"))
  expect_true(inherits(p1_out[[2]], "LayerInstance"))
  expect_true(inherits(p1_out[[3]], "LayerInstance"))

  expect_true(inherits(p2_out[[1]], "LayerInstance"))
  expect_true(inherits(p2_out[[2]], "LayerInstance"))
  expect_true(inherits(p2_out[[3]], "LayerInstance"))
})
